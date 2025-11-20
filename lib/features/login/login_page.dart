// lib/features/login/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Riverpod import
import 'auth_provider.dart'; // 2. auth_provider import
import 'signup_page.dart';

// 3. StatefulWidget -> ConsumerStatefulWidget으로 변경
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  // 4. State<LoginPage> -> ConsumerState<LoginPage>로 변경
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

// 5. State<LoginPage> -> ConsumerState<LoginPage>로 변경
class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 다음 프레임에서 실행 (build 완료 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 임시 저장된 회원가입 ID가 있으면 자동으로 채우기
      final signupId = ref.read(tempSignupIdProvider);
      if (signupId != null) {
        _idController.text = signupId;
        // ID를 사용한 후 임시 저장소 비우기
        ref.read(tempSignupIdProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // 6. _onLogin 함수를 async로 변경하고 Riverpod 연동
  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String id = _idController.text.trim();
      final String password = _pwController.text.trim();

      // 로딩 상태를 보여주는 스낵바 (UX 개선)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 시도 중...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 7. AuthProvider의 login 메서드 호출
      final bool success = await ref
          .read(currentUserProvider.notifier)
          .login(id, password);

      // 이전 로딩 스낵바를 숨깁니다 (선택 사항)
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        // 8. 로그인 성공
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$id님, 로그인 성공!')));

        // 로그인 성공 시 diary 화면으로 이동
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/diary');
        }
      } else {
        // 9. 로그인 실패
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: ID 또는 비밀번호를 확인하세요.')),
        );
      }
    }
  }

  void _onSignup() {
    // SignupPage로 이동
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignupPage()));
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade200,
    contentPadding: const EdgeInsets.symmetric(
      vertical: 14.0,
      horizontal: 16.0,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24.0),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 48.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 24),
                  const Text(
                    'GGUM\nDREAM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // User ID
                  TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('User ID'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ID를 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _pwController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration('Password'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? '6자 이상 입력하세요' : null,
                    onFieldSubmitted: (_) => _onLogin(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onLogin,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(letterSpacing: 1.2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Signup link
                  TextButton(
                    onPressed: _onSignup,
                    child: const Text(
                      'Signup',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
