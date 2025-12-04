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
  bool _isPasswordVisible = false;
  bool _isPasswordCheckVisible = false;
  bool _isNicknameChecked = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordCheckCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname.')),
      );
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final isAvailable = await repo.checkNickname(nickname);

      if (!mounted) return;

      if (isAvailable) {
        setState(() => _isNicknameChecked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is available!')),
        );
      } else {
        setState(() => _isNicknameChecked = false);
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

  Future<void> _onSignupPressed() async {
    final name = _nameCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final passwordCheck = _passwordCheckCtrl.text.trim();

    if (name.isEmpty ||
        nickname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordCheck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    if (password != passwordCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 6 characters.')));
      return;
    }

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sign up successful!')));
      context.go('/login');
    } on NicknameAlreadyUsedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname is already in use.')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        leading: const BackButton(color: Color.fromARGB(255, 216, 169, 255)),
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
        onTap: () => FocusScope.of(context).unfocus(), // ⚡ 화면 탭 시 키보드 내리기
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
                  height:
                      kToolbarHeight + MediaQuery.of(context).padding.top + 20),

              _buildLabel("Name"),
              _buildInput(controller: _nameCtrl),
              const SizedBox(height: 16),

              _buildLabel("Nickname"),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _nicknameCtrl,
                      onChanged: (val) {
                        if (_isNicknameChecked)
                          setState(() => _isNicknameChecked = false);
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
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    child: Text(_isNicknameChecked ? "OK" : "Check",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel("Email"),
              _buildInput(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Password",
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  Text("Insert more than 6 letters",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              _buildInput(
                controller: _passwordCtrl,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel("Password Check"),
              _buildInput(
                controller: _passwordCheckCtrl,
                obscureText: !_isPasswordCheckVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordCheckVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey),
                  onPressed: () => setState(
                      () => _isPasswordCheckVisible = !_isPasswordCheckVisible),
                ),
              ),
              const SizedBox(height: 40),

              // ✅ [수정] 이 부분이 에러의 원인이었을 것입니다.
              // null 체크와 함수 호출 방식을 안전하게 변경했습니다.
              GgumButton(
                text: _isLoading ? "..." : "sign up",
                onPressed: _isLoading
                    ? null
                    : () {
                        _onSignupPressed();
                      },
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
      child: Text(text,
          style: const TextStyle(fontSize: 16, color: Colors.black54)),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Function(String)? onChanged,
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
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
