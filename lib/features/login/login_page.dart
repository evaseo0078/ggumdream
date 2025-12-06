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

  // -----------------------------
  // Basic email validation
  // -----------------------------
  bool _isValidEmail(String email) {
    // Simple and not too strict
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

    // invalid email only
    if (s.contains('invalid-email')) {
      return 'Invalid email format.';
    }

    // Everything else -> unify
    // wrong-password, user-not-found, invalid-credential, too-many-requests, etc.
    return 'Email or password is incorrect.';
  }

  String _mapAuthExceptionToMessage(FirebaseAuthException e) {
    if (e.code == 'invalid-email') {
      return 'Invalid email format.';
    }
    return 'Email or password is incorrect.';
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text; // no trim for safety

    // -----------------------------
    // UI-level validation (English)
    // -----------------------------
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnack('Please enter both email and password.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnack('Invalid email format.');
      return;
    }

    if (password.length < 6) {
      _showErrorSnack('Password must be at least 6 characters.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final success =
          await ref.read(authStateProvider.notifier).login(email, password);

      if (!mounted) return;

      if (success) {
        context.go('/');
        return;
      }

      // If provider returns false without throwing
      final rawErr = ref.read(authStateProvider).error;
      final friendly = (rawErr == null || rawErr.trim().isEmpty)
          ? 'Email or password is incorrect.'
          : _mapRawErrorToMessage(rawErr);

      _showErrorSnack(friendly);
    } on FirebaseAuthException catch (e) {
      _showErrorSnack(_mapAuthExceptionToMessage(e));
    } catch (_) {
      // Unknown error -> keep it safe but not too detailed
      _showErrorSnack('Email or password is incorrect.');
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

    // Inline error also uses the same mapping
    final friendlyInlineError = (authState.error == null ||
            authState.error!.trim().isEmpty)
        ? null
        : _mapRawErrorToMessage(authState.error!);

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
                color: const Color.fromARGB(255, 255, 255, 255)
                    .withOpacity(0.7),
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
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 175, 126, 255),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255)
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
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 175, 126, 255),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255)
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

                    // Inline error (friendly)
                    if (friendlyInlineError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          friendlyInlineError,
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
