// lib/features/login/signup_page.dart

import 'package:flutter/material.dart';
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
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordCheckCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordCheckCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignupPressed() async {
    final name = _nameCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final passwordCheck = _passwordCheckCtrl.text.trim();

    // --- 기본 입력 검사 ---
    if (name.isEmpty ||
        nickname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordCheck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters long.')),
      );
      return;
    }

    if (password != passwordCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.signUp(
        name: name,
        nickname: nickname,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-up completed. Please log in.')),
      );

      // 로그인 화면으로 이동
      context.go('/login');
    } on NicknameAlreadyUsedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This nickname is already in use. Please enter a different nickname.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;
        case 'weak-password':
          message = 'The password is too weak. Please use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'The email format is invalid.';
          break;
        default:
          message = e.message ?? 'Sign-up failed. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unknown error occurred. Please try again later.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 오버플로우 방지를 위해 이 속성을 추가/수정했습니다.
      // SingleChildScrollView가 스크롤을 전담하도록 만듭니다.
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 237, 253),
        elevation: 0,
        leading: const BackButton(color: Color.fromARGB(255, 216, 169, 255)),
        title: const Text(
          "Make your new Account",
          style: TextStyle(color: Color.fromARGB(255, 216, 169, 255), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // ⚡ 화면 탭 시 키보드 내리기
        child: Container(
          height: double.infinity, // Ensure the gradient fills the entire screen
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              _buildLabel("Name"),
              _buildInput(controller: _nameCtrl),
              const SizedBox(height: 16),
              

              _buildLabel("Nickname"),
              _buildInput(controller: _nicknameCtrl),
              const SizedBox(height: 16),

              _buildLabel("Email"),
              _buildInput(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Password",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  Text(
                    "Insert more than 8 letters",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildInput(
                controller: _passwordCtrl,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              _buildLabel("Password Check"),
              _buildInput(
                controller: _passwordCheckCtrl,
                obscureText: true,
              ),

              const SizedBox(height: 40),

              GgumButton(
                text: _isLoading ? "..." : "sign up",
                onPressed: () {
                  if (_isLoading) return;
                  _onSignupPressed();
                },
              ),

              const SizedBox(height: 24),

              // ✅ 작은 오버플로우를 해결하기 위해 하단 여백을 추가했습니다.
              const SizedBox(height: 30),
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
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}