import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nunito/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nunito/screens/introScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nunito/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공!');
    // 익명 인증 초기화 (비로그인)
    await FirebaseService.signInAnonymously();
    print('✅ 익명 인증 초기화 성공!');
    await FirebaseService.checkAndResetAllPlants();
    print('✅ 주간 조회수 리셋 체크 완료!');
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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(surface: Colors.white),
      ),
      home: IntroScreen(),
    );
  }
}
