import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';

class PlantDetailScreen extends StatelessWidget {
  final String cntntsNo; // 식물 컨텐츠 번호 추가

  const PlantDetailScreen({super.key, required this.cntntsNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('식물 상세 정보'), centerTitle: true),
      body: Center(child: Text('식물 ID: $cntntsNo의 상세 정보')),
    );
  }
}
