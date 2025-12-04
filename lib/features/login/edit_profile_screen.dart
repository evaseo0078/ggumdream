// lib/features/login/edit_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import '../diary/application/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  int _currentImageIndex = 1;
  bool _isCurrentVerified = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  String? _originalNickname;
  bool _isNicknameChecked = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['name'] != null) _nameController.text = data['name'];

          final nickname = data['nickname'] ?? '';
          _nicknameController.text = nickname;
          _originalNickname = nickname;

          if (data['profileImageIndex'] != null) {
            setState(() {
              _currentImageIndex = data['profileImageIndex'];
            });
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) return;

    if (newNickname == _originalNickname) {
      setState(() => _isNicknameChecked = true);
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final isAvailable = await repo.checkNickname(newNickname);
      if (!mounted) return;

      if (isAvailable) {
        setState(() => _isNicknameChecked = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nickname is available!')));
      } else {
        setState(() => _isNicknameChecked = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nickname is already taken.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _verifyCurrentPassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    if (currentPassword.isEmpty) {
      setState(() => _currentPasswordError = 'Please enter current password');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      setState(() {
        _isCurrentVerified = true;
        _currentPasswordError = null;
      });
    } catch (e) {
      setState(() {
        _isCurrentVerified = false;
        _currentPasswordError = 'Incorrect password';
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    if (!_isNicknameChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check nickname availability.')));
      return;
    }

    String? newPassword;
    if (_newPasswordController.text.isNotEmpty) {
      if (!_isCurrentVerified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please verify current password first.')));
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() => _confirmPasswordError = 'Passwords do not match');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        setState(
            () => _newPasswordError = 'Password must be at least 6 characters');
        return;
      }
      newPassword = _newPasswordController.text.trim();
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user');

      final repo = ref.read(authRepositoryProvider);

      if (newPassword != null) {
        await repo.changePassword(_currentPasswordController.text, newPassword);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'profileImageIndex': _currentImageIndex,
      });

      // ✅ 닉네임 변경 반영을 위해 상태 무효화
      ref.invalidate(userProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: AssetImage(
                        'assets/images/profile$_currentImageIndex.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Container(
                            height: 200,
                            padding: const EdgeInsets.all(20),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                final imgIndex = index + 1;
                                return GestureDetector(
                                  onTap: () {
                                    setState(
                                        () => _currentImageIndex = imgIndex);
                                    Navigator.pop(context);
                                  },
                                  child: CircleAvatar(
                                      backgroundImage: AssetImage(
                                          'assets/images/profile$imgIndex.png')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildLabel("Name"),
            _buildField(
                controller: _nameController,
                isVisible: true,
                onToggleVisibility: () {}),
            const SizedBox(height: 20),
            _buildLabel("Nickname"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    onChanged: (val) {
                      if (val != _originalNickname) {
                        setState(() => _isNicknameChecked = false);
                      } else {
                        setState(() => _isNicknameChecked = true);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkNickname,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isNicknameChecked ? Colors.green : Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                  ),
                  child: Text(_isNicknameChecked ? "OK" : "Check",
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel("Email"),
            _buildField(
              controller: _emailController,
              isVisible: true,
              onToggleVisibility: () {},
              readOnly: true,
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text("Change Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildField(
              label: "Current Password",
              controller: _currentPasswordController,
              isVisible: _isCurrentPasswordVisible,
              onToggleVisibility: () => setState(
                  () => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
              errorText: _currentPasswordError,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: _verifyCurrentPassword,
                  child: Text(_isCurrentVerified ? "Verified" : "Verify",
                      style: TextStyle(
                          color: _isCurrentVerified
                              ? Colors.green
                              : Colors.blue))),
            ),
            _buildField(
              label: "New Password",
              controller: _newPasswordController,
              isVisible: _isNewPasswordVisible,
              onToggleVisibility: () => setState(
                  () => _isNewPasswordVisible = !_isNewPasswordVisible),
              errorText: _newPasswordError,
              readOnly: !_isCurrentVerified,
            ),
            const SizedBox(height: 15),
            _buildField(
              label: "Confirm New Password",
              controller: _confirmPasswordController,
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              errorText: _confirmPasswordError,
              readOnly: !_isCurrentVerified,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)));

  Widget _buildField(
      {String label = "",
      required TextEditingController controller,
      required bool isVisible,
      required VoidCallback onToggleVisibility,
      bool readOnly = false,
      VoidCallback? onTap,
      String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8)
        ],
        TextField(
          controller: controller,
          obscureText: !isVisible && label.toLowerCase().contains("password"),
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            suffixIcon: label.toLowerCase().contains("password")
                ? IconButton(
                    icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey),
                    onPressed: onToggleVisibility)
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12))
        ],
      ],
    );
  }
}
