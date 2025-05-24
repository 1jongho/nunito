import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nunito/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nunito/screens/introScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/services/notification_service.dart';
import 'package:nunito/services/plant_monitor_service.dart';

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
    // 알림 서비스 초기화
    await NotificationService.initialize();
    print('✅ 알림 서비스 초기화 성공!');
    // 식물 모니터링 시작
    PlantMonitorService.startMonitoring();
    print('✅ 식물 모니터링 시작!');
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

        // 전역 터치 애니메이션 효과 제거 설정
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,

        // 개별 버튼 타입별 설정 (더 구체적인 설정)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent, // 오버레이 색상 투명
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
        ),

        // InkWell과 기타 터치 가능한 위젯들에 대한 전역 설정
        splashFactory: NoSplash.splashFactory,

        // ListTile에 대한 설정
        listTileTheme: ListTileThemeData(selectedTileColor: Colors.transparent),

        // Card에 대한 설정
        cardTheme: CardTheme(surfaceTintColor: Colors.transparent),
      ),
      home: IntroScreen(),
    );
  }
}
