// lib/features/login/edit_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // ← 추가: 글자 수 제한용
import 'auth_repository.dart';
import '../diary/application/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ===== 길이 제한 상수 =====
  static const int _nameMin = 1;
  static const int _nameMax = 30;

  static const int _nicknameMin = 2;
  static const int _nicknameMax = 20;

  static const int _passwordMin = 6;
  static const int _passwordMax = 64;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ✅ 포커스 노드: 커서 이동(blur) 시 검증용
  late final FocusNode _nameFocus;
  late final FocusNode _nicknameFocus;
  late final FocusNode _currentPwFocus;
  late final FocusNode _newPwFocus;
  late final FocusNode _confirmPwFocus;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  int _currentImageIndex = 1;
  bool _isCurrentVerified = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  // ✅ 이름 / 닉네임 에러 텍스트
  String? _nameError;
  String? _nicknameError;

  String? _originalNickname;
  bool _isNicknameChecked = true;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _nicknameFocus = FocusNode();
    _currentPwFocus = FocusNode();
    _newPwFocus = FocusNode();
    _confirmPwFocus = FocusNode();

    _loadUserData();

    // 포커스 해제 시 자동 검증
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _validateNameOnBlur();
    });
    _nicknameFocus.addListener(() {
      if (!_nicknameFocus.hasFocus) _validateNicknameOnBlur();
    });
    _currentPwFocus.addListener(() {
      if (!_currentPwFocus.hasFocus) _validatePasswordsOnBlur();
    });
    _newPwFocus.addListener(() {
      if (!_newPwFocus.hasFocus) _validatePasswordsOnBlur();
    });
    _confirmPwFocus.addListener(() {
      if (!_confirmPwFocus.hasFocus) _validatePasswordsOnBlur();
    });
  }

  bool _containsWhitespace(String value) {
    return RegExp(r'\s').hasMatch(value);
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
        debugPrint('Data load fail: $e');
      }
    }
  }

  // ---------- Blur 시 검증 로직 ----------

  void _validateNameOnBlur() {
    final rawName = _nameController.text;
    String? err;
    if (rawName.isEmpty) {
      err = 'Please enter your name';
    } else if (_containsWhitespace(rawName)) {
      err = 'Name cannot contain spaces';
    } else if (rawName.length < _nameMin || rawName.length > _nameMax) {
      err = 'Name must be between $_nameMin and $_nameMax characters';
    }
    setState(() => _nameError = err);
  }

  void _validateNicknameOnBlur() {
    final rawNickname = _nicknameController.text;
    String? err;
    if (rawNickname.isEmpty) {
      err = 'Please enter your nickname';
    } else if (_containsWhitespace(rawNickname)) {
      err = 'Nickname cannot contain spaces';
    } else if (rawNickname.length < _nicknameMin ||
        rawNickname.length > _nicknameMax) {
      err = 'Nickname must be between $_nicknameMin and $_nicknameMax characters';
    }
    setState(() => _nicknameError = err);
  }

  void _validatePasswordsOnBlur() {
    final rawCurrentPw = _currentPasswordController.text;
    final rawNewPw = _newPasswordController.text;
    final rawConfirmPw = _confirmPasswordController.text;

    String? currentPwError;
    String? newPwError;
    String? confirmPwError;

    // 비밀번호 변경 시도(새/확인 중 하나라도 입력됨)일 때만 검사
    if (rawNewPw.isNotEmpty || rawConfirmPw.isNotEmpty) {
      // 현재 비밀번호
      if (rawCurrentPw.isEmpty) {
        currentPwError = 'Please enter current password';
      } else if (_containsWhitespace(rawCurrentPw)) {
        currentPwError = 'Password cannot contain spaces';
      }

      // 새 비밀번호
      if (_containsWhitespace(rawNewPw)) {
        newPwError = 'New password cannot contain spaces';
      } else if (rawNewPw.isNotEmpty && rawNewPw.length < _passwordMin) {
        newPwError = 'Password must be at least $_passwordMin characters';
      } else if (rawNewPw.length > _passwordMax) {
        newPwError =
            'Password must be between $_passwordMin and $_passwordMax characters';
      }

      // 새 비밀번호 확인
      if (_containsWhitespace(rawConfirmPw)) {
        confirmPwError = 'Confirm password cannot contain spaces';
      } else if (rawNewPw != rawConfirmPw) {
        confirmPwError = 'Passwords do not match';
      }

      // 현재 비밀번호 인증 여부
      if (!_isCurrentVerified) {
        currentPwError ??= 'Please verify current password first.';
      }
    }

    setState(() {
      _currentPasswordError = currentPwError;
      _newPasswordError = newPwError;
      _confirmPasswordError = confirmPwError;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _nicknameFocus.dispose();
    _currentPwFocus.dispose();
    _newPwFocus.dispose();
    _confirmPwFocus.dispose();

    super.dispose();
  }

  Future<void> _checkNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      setState(() {
        _nicknameError = 'Please enter your nickname';
      });
      return;
    }

    if (_containsWhitespace(newNickname)) {
      setState(() {
        _nicknameError = 'Nickname cannot contain spaces';
      });
      return;
    }

    if (newNickname.length < _nicknameMin || newNickname.length > _nicknameMax) {
      setState(() {
        _nicknameError =
            'Nickname must be between $_nicknameMin and $_nicknameMax characters';
      });
      return;
    }

    if (newNickname == _originalNickname) {
      setState(() {
        _isNicknameChecked = true;
        _nicknameError = null;
      });
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final isAvailable = await repo.checkNickname(newNickname);
      if (!mounted) return;

      if (isAvailable) {
        setState(() {
          _isNicknameChecked = true;
          _nicknameError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is available!')),
        );
      } else {
        setState(() {
          _isNicknameChecked = false;
          _nicknameError = 'Nickname is already taken.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is already taken.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // 💾 저장 버튼 클릭 시 '확인 팝업' 띄우기
  void _onSavePressed() {
    // 저장 누르기 전에 blur 검증 한 번 강제 실행
    _validateNameOnBlur();
    _validateNicknameOnBlur();
    _validatePasswordsOnBlur();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Changes"),
        content: const Text(
            "Are you sure you want to update your profile information?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // cancel
            child:
                const Text("cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫고
              _saveChanges(); // 실제 저장 로직 실행
            },
            child: const Text("confirm",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCurrentPassword() async {
    final rawCurrentPassword = _currentPasswordController.text;

    // 공백/빈 값 검사
    if (rawCurrentPassword.isEmpty) {
      setState(() => _currentPasswordError = 'Please enter current password');
      return;
    }
    if (_containsWhitespace(rawCurrentPassword)) {
      setState(
          () => _currentPasswordError = 'Password cannot contain spaces');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: rawCurrentPassword,
      );
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
    // 에러 초기화
    setState(() {
      _nameError = null;
      _nicknameError = null;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final rawName = _nameController.text;
    final rawNickname = _nicknameController.text;
    final rawEmail = _emailController.text;

    final rawCurrentPw = _currentPasswordController.text;
    final rawNewPw = _newPasswordController.text;
    final rawConfirmPw = _confirmPasswordController.text;

    bool hasError = false;
    String? nameError;
    String? nicknameError;
    String? currentPwError;
    String? newPwError;
    String? confirmPwError;

    // ✅ 이름 검증
    if (rawName.isEmpty) {
      nameError = 'Please enter your name';
      hasError = true;
    } else if (_containsWhitespace(rawName)) {
      nameError = 'Name cannot contain spaces';
      hasError = true;
    } else if (rawName.length < _nameMin || rawName.length > _nameMax) {
      nameError = 'Name must be between $_nameMin and $_nameMax characters';
      hasError = true;
    }

    // ✅ 닉네임 검증
    if (rawNickname.isEmpty) {
      nicknameError = 'Please enter your nickname';
      hasError = true;
    } else if (_containsWhitespace(rawNickname)) {
      nicknameError = 'Nickname cannot contain spaces';
      hasError = true;
    } else if (rawNickname.length < _nicknameMin ||
        rawNickname.length > _nicknameMax) {
      nicknameError =
          'Nickname must be between $_nicknameMin and $_nicknameMax characters';
      hasError = true;
    }

    // ✅ 이메일 공백 검사 (email은 readOnly지만, 혹시라도 잘못 들어간 경우 방지)
    if (_containsWhitespace(rawEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email cannot contain spaces.')),
      );
      hasError = true;
    }

    // ✅ 새 비밀번호 변경을 시도하는 경우에만 비밀번호 관련 검증
    if (rawNewPw.isNotEmpty || rawConfirmPw.isNotEmpty) {
      // 현재 비밀번호 공백/빈값
      if (rawCurrentPw.isEmpty) {
        currentPwError = 'Please enter current password';
        hasError = true;
      } else if (_containsWhitespace(rawCurrentPw)) {
        currentPwError = 'Password cannot contain spaces';
        hasError = true;
      }

      // 새 비밀번호 공백
      if (_containsWhitespace(rawNewPw)) {
        newPwError = 'New password cannot contain spaces';
        hasError = true;
      }

      // 새 비밀번호 확인 공백
      if (_containsWhitespace(rawConfirmPw)) {
        confirmPwError = 'Confirm password cannot contain spaces';
        hasError = true;
      }

      // 현재 비밀번호 검증 여부
      if (!_isCurrentVerified) {
        currentPwError ??= 'Please verify current password first.';
        hasError = true;
      }

      // 길이 체크
      if (rawNewPw.isNotEmpty && rawNewPw.length < _passwordMin) {
        newPwError = 'Password must be at least $_passwordMin characters';
        hasError = true;
      } else if (rawNewPw.length > _passwordMax) {
        newPwError =
            'Password must be between $_passwordMin and $_passwordMax characters';
        hasError = true;
      }

      // 일치 여부
      if (rawNewPw != rawConfirmPw) {
        confirmPwError = 'Passwords do not match';
        hasError = true;
      }
    }

    // 에러 상태 UI 반영
    setState(() {
      _nameError = nameError;
      _nicknameError = nicknameError;
      _currentPasswordError = currentPwError;
      _newPasswordError = newPwError;
      _confirmPasswordError = confirmPwError;
    });

    if (hasError) return;

    if (!_isNicknameChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check nickname availability.')),
      );
      return;
    }

    String? newPassword;
    if (rawNewPw.isNotEmpty) {
      newPassword = rawNewPw.trim();
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user');

      final repo = ref.read(authRepositoryProvider);

      if (newPassword != null) {
        await repo.changePassword(rawCurrentPw, newPassword);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': rawName.trim(),
        'nickname': rawNickname.trim(),
        'profileImageIndex': _currentImageIndex,
      });

      // ✅ 닉네임 변경 반영을 위해 상태 무효화
      ref.invalidate(userProvider);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _onSavePressed,
            child: const Text(
              "Save",
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          )
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 화면 탭 시 키보드 내리기
        child: SingleChildScrollView(
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
                        'assets/images/profile$_currentImageIndex.png',
                      ),
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
                                  mainAxisSpacing: 10,
                                ),
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
                                        'assets/images/profile$imgIndex.png',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
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
                onToggleVisibility: () {},
                errorText: _nameError,
                focusNode: _nameFocus,
                maxLength: _nameMax,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 20),

              _buildLabel("Nickname"),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameController,
                      focusNode: _nicknameFocus,
                      onChanged: (val) {
                        setState(() {
                          if (val != _originalNickname) {
                            _isNicknameChecked = false;
                          } else {
                            _isNicknameChecked = true;
                          }
                          _nicknameError = null;
                        });
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_nicknameMax),
                      ],
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                    child: Text(
                      _isNicknameChecked ? "OK" : "Check",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_nicknameError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _nicknameError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
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

              const Text(
                "Change Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildField(
                label: "Current Password",
                controller: _currentPasswordController,
                isVisible: _isCurrentPasswordVisible,
                onToggleVisibility: () => setState(
                  () => _isCurrentPasswordVisible = !_isCurrentPasswordVisible,
                ),
                errorText: _currentPasswordError,
                focusNode: _currentPwFocus,
                maxLength: _passwordMax,
                onChanged: (_) {
                  if (_currentPasswordError != null) {
                    setState(() => _currentPasswordError = null);
                  }
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _verifyCurrentPassword,
                  child: Text(
                    _isCurrentVerified ? "Verified" : "Verify",
                    style: TextStyle(
                      color:
                          _isCurrentVerified ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ),

              _buildField(
                label: "New Password",
                controller: _newPasswordController,
                isVisible: _isNewPasswordVisible,
                onToggleVisibility: () => setState(
                  () => _isNewPasswordVisible = !_isNewPasswordVisible,
                ),
                errorText: _newPasswordError,
                readOnly: !_isCurrentVerified,
                focusNode: _newPwFocus,
                maxLength: _passwordMax,
                onChanged: (_) {
                  if (_newPasswordError != null) {
                    setState(() => _newPasswordError = null);
                  }
                },
              ),
              const SizedBox(height: 15),

              _buildField(
                label: "Confirm New Password",
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggleVisibility: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
                errorText: _confirmPasswordError,
                readOnly: !_isCurrentVerified,
                focusNode: _confirmPwFocus,
                maxLength: _passwordMax,
                onChanged: (_) {
                  if (_confirmPasswordError != null) {
                    setState(() => _confirmPasswordError = null);
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildField({
    String label = "",
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    bool readOnly = false,
    VoidCallback? onTap,
    String? errorText,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
    int? maxLength, // ← 추가: 길이 제한
  }) {
    final isPasswordField = label.toLowerCase().contains("password");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPasswordField && !isVisible,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: maxLength != null
              ? [LengthLimitingTextInputFormatter(maxLength)]
              : null,
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
            suffixIcon: isPasswordField
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
