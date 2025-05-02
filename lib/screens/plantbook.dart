import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';

class PlantBookScreen extends StatelessWidget {
  const PlantBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('plantbook.dart 화면')),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 2),
    );
  }
}
