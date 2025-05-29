import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart'; // Color 클래스를 위해 추가
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Android 채널 설정 (더 강화됨)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 (포그라운드 알림 활성화)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
          // 🔔 포그라운드에서도 알림 표시
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 알림 클릭됨: ${response.payload}');
      },
    );

    // Android 알림 채널 수동 생성
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // 권한 요청
    await _requestPermissions();

    _isInitialized = true;

    // 초기화 완료 후 즉시 테스트 알림
    await _sendInitializationTestAlert();
  }

  /// iOS 포그라운드 알림 처리
  static Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {}

  /// Android 알림 채널 생성
  static Future<void> _createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'plant_alert_channel',
      'Plant Alerts',
      description: '식물 상태 알림 채널',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF0BB57F),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('📱 Android 알림 채널 생성 완료');
  }

  /// 초기화 테스트 알림
  static Future<void> _sendInitializationTestAlert() async {
    try {
      await showNotification(
        id: 0,
        title: '🌱 Nunito 알림 테스트',
        body:
            '알림 시스템이 정상 작동합니다! ${DateTime.now().toString().substring(11, 19)}',
      );
    } catch (e) {
      print('❌ 초기화 테스트 알림 실패: $e');
    }
  }

  /// 알림 권한 요청
  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final permission = await Permission.notification.request();
        print('📱 Android 알림 권한: ${permission.isGranted ? "허용" : "거부"}');
      }

      if (Platform.isIOS) {
        // iOS에서는 flutter_local_notifications의 네이티브 방식 사용
        bool? granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);

        print('📱 iOS 알림 권한 (네이티브): ${granted == true ? "허용" : "거부"}');

        if (granted != true) {
          print('⚠️ iOS 알림 권한이 거부되었습니다. 설정에서 수동으로 허용해주세요.');
          print('📱 설정 → 알림 → Nunito → 알림 허용');
        }
      }
    } catch (e) {
      print('❌ 권한 요청 실패: $e');
      // 권한 요청 실패해도 알림 시도는 계속 진행
    }
  }

  /// 기본 알림 발송
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? plantName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Android 알림 설정 (더 강력하게)
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'plant_alert_channel', // 채널 ID 변경
            'Plant Alerts',
            channelDescription: '식물 상태 알림 채널',
            importance: Importance.max, // max로 변경
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            fullScreenIntent: true, // 전체 화면 인텐트
            category: AndroidNotificationCategory.alarm, // 알람 카테고리
          );

      // iOS 알림 설정 (더 강력하게)
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical, // 중요 알림
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);

      // 발송 후 잠시 대기
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print('❌ 알림 발송 실패: $e');
      print('스택 트레이스: ${StackTrace.current}');
    }
  }

  /// 수분 부족 알림 (PlantMonitorService에서 호출)
  static Future<void> showMoistureAlert({
    required String plantName,
    required int currentValue,
    required int targetValue,
  }) async {
    await showNotification(
      id: 1,
      title: '💧 $plantName 물주기 알림',
      body: '수분이 부족합니다! (현재: $currentValue%, 목표: $targetValue%)',
      plantName: plantName,
    );
  }

  /// 온도 이상 알림 (PlantMonitorService에서 호출)
  static Future<void> showTemperatureAlert({
    required String plantName,
    required int currentValue,
    required int targetValue,
    required bool isTooHot,
  }) async {
    String emoji = isTooHot ? '🔥' : '🧊';
    String status = isTooHot ? '너무 뜨거워요' : '너무 추워요';

    await showNotification(
      id: 2,
      title: '$emoji $plantName 온도 알림',
      body: '온도가 $status! (현재: $currentValue°C, 목표: $targetValue°C)',
      plantName: plantName,
    );
  }

  /// 전도도 이상 알림 (PlantMonitorService에서 호출)
  static Future<void> showConductivityAlert({
    required String plantName,
    required double currentValue,
    required int targetValue,
    required bool isTooHigh,
  }) async {
    String emoji = isTooHigh ? '⚡' : '🌱';
    String status = isTooHigh ? '너무 높아요' : '너무 낮아요';

    await showNotification(
      id: 3,
      title: '$emoji $plantName 전도도 알림',
      body: '전도도가 $status! (현재: $currentValue mS/cm, 목표: $targetValue mS/cm)',
      plantName: plantName,
    );
  }

  /// 간단한 식물 알림 (화면에서 호출)
  static Future<void> showPlantAlert(String plantName, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 1000,
      title: '🌱 $plantName 알림',
      body: message,
    );
  }
}
