import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ✅ 시도할 때 기존 로컬 에러는 일단 제거
    _setLocalError(null);

    // -----------------------------
    // UI-level validation (English)
    // -----------------------------
    if (email.isEmpty || password.isEmpty) {
      _setLocalError('Please enter both email and password.');
      return;
    }

    if (!_isValidEmail(email)) {
      _setLocalError('Invalid email format.');
      return;
    }

    if (password.length < 6) {
      _setLocalError('Password must be at least 6 characters.');
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
                          // 입력 중엔 에러를 과하게 지우고 싶지 않으면 주석 가능
                          if (_localError != null) _setLocalError(null);
                        },
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
