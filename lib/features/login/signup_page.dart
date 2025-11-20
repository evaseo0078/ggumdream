// lib/features/login/signup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Riverpod import
import 'package:go_router/go_router.dart'; // GoRouter import
import 'auth_provider.dart'; // 2. Auth Provider import

// StatefulWidget 대신 ConsumerStatefulWidget 사용
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  // 3. 폼 상태 관리를 위한 GlobalKey
  final _formKey = GlobalKey<FormState>();

  // 4. 입력 값 관리를 위한 컨트롤러
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // 5. 회원가입 로직
  void _onSignup() async {
    // 폼 유효성 검사
    if (_formKey.currentState?.validate() ?? false) {
      final String id = _idController.text.trim();
      final String password = _pwController.text;

      // 로딩 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입 요청 중...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 6. AuthProvider의 signup 메서드 호출
      final bool success = await ref
          .read(currentUserProvider.notifier)
          .signup(id, password);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        // 7. 회원가입 성공 시
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$id 계정으로 회원가입 성공!')));
          // ID를 임시 저장하고 로그인 페이지로 이동
          ref.read(tempSignupIdProvider.notifier).state = id;
          context.go('/login');
        }
      } else {
        // 8. 회원가입 실패 (대부분 ID 중복)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$id는 이미 존재하는 ID입니다.')));
      }
    }
  }

  // 로그인 페이지와 통일된 디자인의 InputDecoration을 사용 (선택 사항)
  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade200,
    contentPadding: const EdgeInsets.symmetric(
      vertical: 14.0,
      horizontal: 16.0,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0), // 살짝 덜 둥글게
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make your new Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0), // 전체 패딩을 넉넉하게 조정
        // 9. Form 위젯 추가
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Username 입력 필드
              const Text('Username'),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('사용자 이름을 입력하세요'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
              ),

              const SizedBox(height: 24.0),

              // 2. User ID 입력 필드
              const Text('User ID'),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _idController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('ID를 입력하세요'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'ID는 필수입니다' : null,
              ),

              const SizedBox(height: 24.0),

              // 3. Password 입력 필드
              const Text('Password'),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _pwController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration('6자 이상 입력하세요'),
                validator: (v) =>
                    (v == null || v.length < 6) ? '비밀번호는 6자 이상이어야 합니다' : null,
                onFieldSubmitted: (_) => _onSignup(),
              ),

              const SizedBox(height: 48.0),

              // 4. Signup 버튼
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _onSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
