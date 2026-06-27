import 'package:flutter/material.dart';

/// 앱 시작 시 전체화면으로 스플래시 이미지를 보여주는 자체 스플래시 화면.
/// Android 12+ 시스템 스플래시는 작은 아이콘만 표시할 수 있으므로,
/// Flutter가 첫 프레임을 그린 직후 이 화면으로 이미지를 꽉 채워 보여준다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFF8A00),
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('splash_img.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
