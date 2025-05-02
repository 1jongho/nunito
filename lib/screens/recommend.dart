import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';

class PlantRecommendScreen extends StatelessWidget {
  const PlantRecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('recommend.dart 화면')),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 1),
    );
  }
}
