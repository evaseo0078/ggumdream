// lib/features/auth/presentation/signup_page.dart

import 'package:flutter/material.dart';
import '../../../shared/widgets/notebook_background.dart';
import '../../../shared/widgets/ggum_button.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart'; // FIX: 패키지 경로로 변경

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Signup 1",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
      body: NotebookBackground(
        // 공책 배경 적용
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Make\nyour new\nAccount",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // 입력 필드들
              _buildLabel("Username"),
              _buildInput(),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("User ID"),
                  // ID 중복확인 버튼 (WobblyContainer 적용)
                  SizedBox(
                    height: 30,
                    width: 80,
                    child: WobblyContainer(
                      // WobblyContainer 적용
                      backgroundColor: const Color(0xFFAABCC5),
                      borderColor: Colors.black87,
                      borderRadius: 12,
                      padding: EdgeInsets.zero,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // 배경을 WobblyContainer에 맡김
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("OK",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
              _buildInput(),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("Password"),
                  const Text(
                    "Insert more than 8 letters",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              _buildInput(),

              const SizedBox(height: 20),

              _buildLabel("Password Check"),
              _buildInput(),

              const SizedBox(height: 60),

              GgumButton(
                text: "sign\nup", // 줄바꿈이 있다면 Text 위젯을 커스텀하거나 '\n' 사용
                onPressed: () {
                  // TODO: 회원가입 로직
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  // 삐뚤빼뚤한 입력 필드 (WobblyContainer 적용)
  Widget _buildInput() {
    return WobblyContainer(
      backgroundColor: Colors.white,
      borderColor: Colors.black87,
      borderRadius: 20,
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
