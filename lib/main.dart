import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nunito/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nunito/screens/homeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공!');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
  }

  await initializeDateFormatting('ko-KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nunito',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: HomeScreen(),
    );
  }
}
