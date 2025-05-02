import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        backgroundColor: Color(0xFF0BB57F),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      body: Center(child: Text('settingScreen.dart 화면')),
    );
  }
}
