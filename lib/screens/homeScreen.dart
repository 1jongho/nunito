import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('homeScreen.dart 화면')),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 0),
    );
  }
}
