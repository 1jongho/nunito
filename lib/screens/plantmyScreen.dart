import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';

class PlantMyScreen extends StatelessWidget {
  const PlantMyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 식물')),
      body: Center(child: Text('plantmyScreen.dart 화면')),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 0),
    );
  }
}
