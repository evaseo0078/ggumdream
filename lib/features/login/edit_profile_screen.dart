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
  // 텍스트 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // 비밀번호 관련 컨트롤러
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 비밀번호 보이기/숨기기 상태 변수
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  int _currentImageIndex = 1; // 현재 프로필 이미지 인덱스

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 🔥 Firestore에서 'name'과 'nickname', 'profileImageIndex'를 정확히 가져오기
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. 이메일은 Auth에서 바로 가져옴
      _emailController.text = user.email ?? '';

      // 2. 나머지는 Firestore에서 가져옴
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? ''; // 실명
            _nicknameController.text = data['nickname'] ?? ''; // 닉네임
            _currentImageIndex = data['profileImageIndex'] ?? 1; // 프로필 이미지
          });
        }
      } catch (e) {
        debugPrint('Data load fail: $e');
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

  // 📸 프로필 사진 변경 팝업 (AccountScreen과 동일 로직)
  void _showProfilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final imageIndex = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentImageIndex = imageIndex; // 화면에 즉시 반영
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentImageIndex == imageIndex
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: _currentImageIndex == imageIndex ? 3 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile$imageIndex.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💾 저장 버튼 클릭 시 '확인 팝업' 띄우기
  void _onSavePressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Changes"),
        content: const Text("Are you sure you want to update your profile information?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // cancel
            child: const Text("cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫고
              _saveProfile(); // 실제 저장 로직 실행
            },
            child:
                const Text("confirm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 실제 저장 로직
  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Firestore 정보 업데이트 (닉네임 + 이미지 인덱스)
      // Name은 보통 가입 후 변경 불가 정책을 쓰지만, 필요하다면 여기서 같이 업데이트 가능
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'nickname': _nicknameController.text,
        'profileImageIndex': _currentImageIndex,
      });

      // UserProvider 강제 새로고침 (앱 전반에 변경 사항 반영)
      ref.invalidate(userProvider);

      // 2. 비밀번호 변경 로직
      if (_currentPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text.isEmpty) {
          throw Exception("Please enter a new password.");
        }
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception("New passwords do not match.");
        }

        // 재인증
        await authRepo.reauthenticate(
          email: _emailController.text,
          password: _currentPasswordController.text,
        );

        // 비밀번호 업데이트
        await authRepo.updatePassword(_newPasswordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully.")),
        );
        Navigator.pop(context); // 화면 닫기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error occurred: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // ⚡ 화면 탭 시 키보드 내리기
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          children: [
            // ✨ 프로필 사진 표시 및 변경 (상단 중앙)
            GestureDetector(
              onTap: _showProfilePicker,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: AssetImage(
                        'assets/images/profile$_currentImageIndex.png'),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 기본 정보 섹션
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("Basic Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            _buildTextField(
                label: "Name",
                controller: _nameController,
                readOnly: true), // 이름 수정 불가
            const SizedBox(height: 16),
            _buildTextField(
                label: "Nickname",
                controller: _nicknameController), // 닉네임 수정 가능 (키보드 뜸)
            const SizedBox(height: 16),
            _buildTextField(
                label: "Email", controller: _emailController, readOnly: true),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 비밀번호 변경 섹션
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("Change Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("To change your password, please enter your current password.",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              label: "Current Password",
              controller: _currentPasswordController,
              isVisible: _isCurrentPasswordVisible,
              onToggleVisibility: () {
                setState(() =>
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
              },
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              label: "New Password",
              controller: _newPasswordController,
              isVisible: _isNewPasswordVisible,
              onToggleVisibility: () {
                setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
              },
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              label: "Confirm New Password",
              controller: _confirmPasswordController,
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () {
                setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
              },
            ),

            const SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSavePressed, // ✨ 팝업 함수 연결
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          // ✨ 탭 했을 때 전체 선택되는 동작 방지 (기본 동작이 커서 이동임)
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}
