import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? tag; // Hero 애니메이션을 위한 태그

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경을 검게 해서 몰입감 높임
      body: GestureDetector(
        // 화면을 탭하면 닫히도록 설정
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: tag != null
              ? Hero(
                  tag: tag!,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain, // 비율 유지하며 화면에 맞춤
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}