import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';

import 'dart:ui';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await ref.read(authStateProvider.notifier).login(email, password);

      if (!mounted) return;

      if (success) {
        context.go('/'); // ✅ 로그인 성공 시 다이어리로 이동
      } else {
        final err = ref.read(authStateProvider).error ?? 'Failed to login.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            color:
                Color.fromARGB(255, 255, 255, 255), // Changed title text color
          ),
        ),
        centerTitle: true,
        backgroundColor:
            const Color.fromARGB(255, 73, 149, 255).withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              color: const Color.fromARGB(255, 255, 255, 255)
                  .withOpacity(0.7), // Adjust transparency here
              colorBlendMode: BlendMode.darken, // Blend mode for transparency
            ),
          ),
          Positioned(
            top: 0,
            right: 10,
            child: Image.asset(
              'assets/images/star.png',
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 로고
                  SizedBox(
                    width: 520,
                    height: 170,
                    child: Image.asset(
                      'assets/images/GGUMDREAM_logo_white.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 이메일
                  SizedBox(
                    width: 350, // Reduced width
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(
                                255, 175, 126, 255), // Change border color
                            width: 1.5, // Adjust border width
                          ),
                        ),
                        filled: true, // Enable background color
                        fillColor: Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.3), // Set background color
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호
                  SizedBox(
                    width: 350, // Reduced width
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(
                                255, 175, 126, 255), // Change border color
                            width: 1.5, // Adjust border width
                          ),
                        ),
                        filled: true, // Enable background color
                        fillColor: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.3), // Set background color
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

                  if (authState.error != null)
                    Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: 350, // Reduced width
                    child: GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 10, sigmaY: 10), // 🔥 유리 흐림 효과
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white
                                  .withOpacity(0.25), // 🔥 glass 투명도
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
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
                  TextButton(
                    onPressed: () => context.go('/login/signup'),
                    child: const Text('Sign Up'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 107, 107, 107),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
