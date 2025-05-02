import 'package:flutter/material.dart';

class PlantAddScreen extends StatelessWidget {
  const PlantAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('식물 추가'),
        backgroundColor: Color(0xFF0BB57F),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      body: Center(child: Text('plantaddScreen.dart 화면')),
    );
  }
}
