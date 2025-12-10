import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // ← 추가: 글자 수 제한용
import 'package:go_router/go_router.dart';
import 'package:ggumdream/widgets/logo_particle_animation.dart';

import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // ✅ 길이 제한 상수 (최소 변경)
  static const int _emailMax = 100;
  static const int _passwordMax = 64;

  // ✅ UI에만 띄울 로컬 에러
  String? _localError;

  // -----------------------------
  // Basic email validation
  // -----------------------------
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  // -----------------------------
  // Whitespace check
  // -----------------------------
  bool _containsWhitespace(String value) {
    return RegExp(r'\s').hasMatch(value);
  }

  // -----------------------------
  // Two-message policy for auth failures
  // 1) invalid email format
  // 2) email or password incorrect
  // -----------------------------
  String _mapRawErrorToMessage(String raw) {
    final s = raw.toLowerCase();

    if (s.contains('invalid-email')) {
      return 'Invalid email format.';
    }

    return 'Email or password is incorrect.';
  }

  String _mapAuthExceptionToMessage(FirebaseAuthException e) {
    if (e.code == 'invalid-email') {
      return 'Invalid email format.';
    }
    return 'Email or password is incorrect.';
  }

  void _setLocalError(String? message) {
    if (!mounted) return;
    setState(() {
      _localError = message;
    });
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // ⚠️ 공백 검사용: trim() 이전 원본 값
    final rawEmail = _emailController.text;
    final rawPassword = _passwordController.text;

    // 기존 로컬 에러 초기화
    _setLocalError(null);

    // -----------------------------
    // UI-level validation
    // -----------------------------
    // 1) 비어 있는지
    if (rawEmail.isEmpty || rawPassword.isEmpty) {
      _setLocalError('Please enter both email and password.');
      return;
    }

    // 2) 공백 포함 여부 (예: "1234 " 도 에러)
    if (_containsWhitespace(rawEmail) || _containsWhitespace(rawPassword)) {
      _setLocalError('Email and password cannot contain spaces.');
      return;
    }

    // 3) 형식/길이 검사는 trim 후 진행
    final email = rawEmail.trim();
    final password = rawPassword.trim();

    // 🔹 추가: 이메일 길이 상한 체크
    if (email.length > _emailMax) {
      _setLocalError('Email is too long.');
      return;
    }

    // 기존 이메일 형식 체크
    if (!_isValidEmail(email)) {
      _setLocalError('Invalid email format.');
      return;
    }

    // 🔹 기존 비밀번호 최소 길이 체크
    if (password.length < 6) {
      _setLocalError('Password must be at least 6 characters.');
      return;
    }

    // 🔹 추가: 비밀번호 길이 상한 체크
    if (password.length > _passwordMax) {
      _setLocalError('Password is too long.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final success =
          await ref.read(authStateProvider.notifier).login(email, password);

      if (!mounted) return;

      if (success) {
        _setLocalError(null);
        context.go('/');
        return;
      }

      // provider가 false만 반환한 케이스
      final rawErr = ref.read(authStateProvider).error;
      final friendly = (rawErr == null || rawErr.trim().isEmpty)
          ? 'Email or password is incorrect.'
          : _mapRawErrorToMessage(rawErr);

      _setLocalError(friendly);
    } on FirebaseAuthException catch (e) {
      _setLocalError(_mapAuthExceptionToMessage(e));
    } catch (_) {
      _setLocalError('Email or password is incorrect.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // ✅ provider error를 UI에 쓸 경우도 동일 규칙 적용
    // 단, 로컬 에러가 있으면 로컬을 우선 (중복 방지)
    final friendlyProviderError = (authState.error == null ||
            authState.error!.trim().isEmpty)
        ? null
        : _mapRawErrorToMessage(authState.error!);

    final displayError = _localError ?? friendlyProviderError;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            const Color.fromARGB(255, 73, 149, 255).withOpacity(0.5),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_background.jpg',
                fit: BoxFit.cover,
                color:
                    const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            Positioned(
              top: 0,
              right: 10,
              child: Image.asset('assets/images/star.png'),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      width: 50,
                      height: 40,
                      child: LogoParticleAnimation(
                        logoAssetPath: 'assets/images/GGUMDREAM_logo_white.png',
                        offsetX: 0,
                        offsetY: -10,
                        width: 50,
                        height: 40,
                        logoScale: 8.0,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email
                    SizedBox(
                      width: 350,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_localError != null) _setLocalError(null);
                        },
                        // 🔹 추가: 실제 입력 길이 제한
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_emailMax),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 175, 126, 255),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    SizedBox(
                      width: 350,
                      child: TextField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        onChanged: (_) {
                          if (_localError != null) _setLocalError(null);
                        },
                        // 🔹 추가: 실제 입력 길이 제한
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_passwordMax),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 175, 126, 255),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(0.3),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ Inline error (UI only)
                    if (displayError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          displayError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Login button
                    SizedBox(
                      width: 350,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1.4,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Sign up
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => context.go('/login/signup'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 107, 107, 107),
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
