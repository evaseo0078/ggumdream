import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← 글자 수 제한용
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ggum_button.dart';
import 'auth_repository.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  // ===== 길이 제한 상수 =====
  static const int _nameMin = 1;
  static const int _nameMax = 30;

  static const int _nicknameMin = 2;
  static const int _nicknameMax = 20;

  static const int _emailMin = 5;
  static const int _emailMax = 100;

  static const int _passwordMin = 6;   // UI 문구와 맞추려고 6으로 둠
  static const int _passwordMax = 64;

  // ===== 컨트롤러 =====
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordCheckCtrl = TextEditingController();

  // 포커스 노드 (커서 옮길 때 blur 이벤트 잡기)
  late final FocusNode _nameFocus;
  late final FocusNode _nicknameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  late final FocusNode _passwordCheckFocus;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isPasswordCheckVisible = false;
  bool _isNicknameChecked = false;
  bool _isEmailChecked = false;

  // 각 필드 에러 텍스트
  String? _nameErrorText;
  String? _nicknameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _passwordCheckErrorText;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _nicknameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _passwordCheckFocus = FocusNode();

    // 포커스가 빠져나갈 때마다 각 필드 검사
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _validateName();
    });
    _nicknameFocus.addListener(() {
      if (!_nicknameFocus.hasFocus) _validateNickname();
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _validateEmail();
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) _validatePasswordPair();
    });
    _passwordCheckFocus.addListener(() {
      if (!_passwordCheckFocus.hasFocus) _validatePasswordPair();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordCheckCtrl.dispose();

    _nameFocus.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _passwordCheckFocus.dispose();
    super.dispose();
  }

  bool _containsWhitespace(String value) {
    return RegExp(r'\s').hasMatch(value);
  }

  // ---------- 필드별 검증 함수들 ----------

  void _validateName() {
    final raw = _nameCtrl.text;
    String? error;

    if (raw.isEmpty) {
      error = 'Please enter your name.';
    } else if (_containsWhitespace(raw)) {
      error = 'Name cannot contain spaces.';
    } else if (raw.length < _nameMin || raw.length > _nameMax) {
      error = 'Name must be between $_nameMin and $_nameMax characters.';
    }

    setState(() => _nameErrorText = error);
  }

  void _validateNickname() {
    final raw = _nicknameCtrl.text;
    String? error;

    if (raw.isEmpty) {
      error = 'Please enter your nickname.';
    } else if (_containsWhitespace(raw)) {
      error = 'Nickname cannot contain spaces.';
    } else if (raw.length < _nicknameMin || raw.length > _nicknameMax) {
      error =
          'Nickname must be between $_nicknameMin and $_nicknameMax characters.';
    }

    setState(() => _nicknameErrorText = error);
  }

  void _validateEmail() {
    final raw = _emailCtrl.text;
    final value = raw.trim();
    String? error;

    if (value.isEmpty) {
      error = 'Please enter your email.';
    } else if (_containsWhitespace(value)) {
      error = 'Email cannot contain spaces.';
    } else if (value.length < _emailMin || value.length > _emailMax) {
      error = 'Email must be between $_emailMin and $_emailMax characters.';
    } else {
      // 간단한 이메일 형식 검증
      final reg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!reg.hasMatch(value)) {
        error = 'Please enter a valid email address.';
      }
    }

    setState(() => _emailErrorText = error);
  }

  void _validatePasswordPair() {
    final rawPw = _passwordCtrl.text;
    final rawCheck = _passwordCheckCtrl.text;

    String? pwError;
    String? checkError;

    if (rawPw.isEmpty) {
      pwError = 'Please enter your password.';
    } else if (_containsWhitespace(rawPw)) {
      pwError = 'Password cannot contain spaces.';
    } else if (rawPw.length < _passwordMin ||
        rawPw.length > _passwordMax) {
      pwError =
          'Password must be between $_passwordMin and $_passwordMax characters.';
    }

    if (rawCheck.isEmpty) {
      checkError = 'Please re-enter your password.';
    } else if (_containsWhitespace(rawCheck)) {
      checkError = 'Password check cannot contain spaces.';
    } else if (rawPw != rawCheck) {
      checkError = 'Passwords do not match.';
    }

    setState(() {
      _passwordErrorText = pwError;
      _passwordCheckErrorText = checkError;
    });
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameCtrl.text.trim();

    // 먼저 기본 검증
    _validateNickname();
    if (_nicknameErrorText != null) return;

    if (nickname.isEmpty) {
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final isAvailable = await repo.checkNickname(nickname);

      if (!mounted) return;

      if (isAvailable) {
        setState(() {
          _isNicknameChecked = true;
          // 중복 체크까지 통과했으면 nickname 에러 제거
          _nicknameErrorText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is available!')),
        );
      } else {
        setState(() {
          _isNicknameChecked = false;
          _nicknameErrorText = 'Nickname is already taken.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is already taken.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ✅ Email 중복 확인 함수
  Future<void> _checkEmail() async {
    final email = _emailCtrl.text.trim();

    _validateEmail();
    if (_emailErrorText != null) return;

    if (email.isEmpty) {
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final isAvailable = await repo.checkEmail(email);
      if (!mounted) return;

      if (isAvailable) {
        setState(() {
          _isEmailChecked = true;
          _emailErrorText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is available!')),
        );
      } else {
        setState(() {
          _isEmailChecked = false;
          _emailErrorText = 'This email is already taken.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is already taken.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking email: $e')),
      );
    }
  }

  Future<void> _onSignupPressed() async {
    // 제출 시 한 번 전체 검증
    _validateName();
    _validateNickname();
    _validateEmail();
    _validatePasswordPair();

    // 하나라도 에러가 있으면 종료
    if (_nameErrorText != null ||
        _nicknameErrorText != null ||
        _emailErrorText != null ||
        _passwordErrorText != null ||
        _passwordCheckErrorText != null) {
      return;
    }

    if (!_isNicknameChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check nickname availability.')),
      );
      return;
    }
    if (!_isEmailChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check email availability.')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(
        name: name,
        nickname: nickname,
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up successful!')),
      );
      context.go('/login');
    } on NicknameAlreadyUsedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname is already in use.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            const BackButton(color: Color.fromARGB(255, 216, 169, 255)),
        title: const Text(
          "Make your new Account",
          style: TextStyle(
            color: Color.fromARGB(255, 216, 169, 255),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 화면 탭 시 키보드 내리기
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 255, 237, 253),
                Color.fromARGB(255, 205, 230, 246),
                Color.fromARGB(255, 211, 202, 239),
                Color.fromARGB(255, 142, 124, 232),
              ],
              stops: [0.0, 0.5, 0.7, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight +
                      MediaQuery.of(context).padding.top +
                      20,
                ),

                _buildLabel("Name"),
                _buildInput(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  errorText: _nameErrorText,
                  maxLength: _nameMax,
                  onChanged: (_) {
                    if (_nameErrorText != null) {
                      setState(() => _nameErrorText = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel("Nickname"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _nicknameCtrl,
                        focusNode: _nicknameFocus,
                        errorText: _nicknameErrorText,
                        maxLength: _nicknameMax,
                        onChanged: (val) {
                          if (_isNicknameChecked) {
                            setState(() => _isNicknameChecked = false);
                          }
                          if (_nicknameErrorText != null) {
                            setState(() => _nicknameErrorText = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _checkNickname,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNicknameChecked
                            ? Colors.green
                            : const Color.fromARGB(255, 185, 154, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _isNicknameChecked ? "OK" : "Check",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel("Email"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailErrorText,
                        maxLength: _emailMax,
                        onChanged: (val) {
                          if (_isEmailChecked) {
                            setState(() => _isEmailChecked = false);
                          }
                          if (_emailErrorText != null) {
                            setState(() => _emailErrorText = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _checkEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEmailChecked
                            ? Colors.green
                            : const Color.fromARGB(255, 216, 169, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _isEmailChecked ? "OK" : "Check",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Password",
                      style:
                          TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    Text(
                      "Insert more than 6 letters",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: !_isPasswordVisible,
                  maxLength: _passwordMax,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                  errorText: _passwordErrorText,
                  onChanged: (_) {
                    if (_passwordErrorText != null ||
                        _passwordCheckErrorText != null) {
                      setState(() {
                        _passwordErrorText = null;
                        _passwordCheckErrorText = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel("Password Check"),
                _buildInput(
                  controller: _passwordCheckCtrl,
                  focusNode: _passwordCheckFocus,
                  obscureText: !_isPasswordCheckVisible,
                  maxLength: _passwordMax,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordCheckVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordCheckVisible =
                          !_isPasswordCheckVisible,
                    ),
                  ),
                  errorText: _passwordCheckErrorText,
                  onChanged: (_) {
                    if (_passwordCheckErrorText != null) {
                      setState(() => _passwordCheckErrorText = null);
                    }
                  },
                ),
                const SizedBox(height: 40),

                GgumButton(
                  text: _isLoading ? "..." : "sign up",
                  onPressed: _isLoading ? null : _onSignupPressed,
                ),
                const SizedBox(height: 54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? errorText,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black87),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: maxLength != null
                ? [LengthLimitingTextInputFormatter(maxLength)]
                : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
