import 'dart:async';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/services/notification_service.dart';

class PlantMonitorService {
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;

  // 마지막 알림 시간을 추적하여 스팸 방지 (5초 쿨다운)
  static final Map<String, DateTime> _lastNotificationTime = {};
  static const Duration _notificationCooldown = Duration(seconds: 5);

  /// 식물 모니터링 시작
  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // 5초마다 모든 식물 상태 확인
    _monitoringTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkAllPlantsStatus();
    });
  }

  /// 식물 모니터링 중지
  static void stopMonitoring() {
    print('🛑 백그라운드 식물 모니터링 중지');
    _monitoringTimer?.cancel();
    _isMonitoring = false;
  }

  /// 모든 식물 상태 확인 (백그라운드)
  static Future<void> _checkAllPlantsStatus() async {
    try {
      // 사용자의 모든 식물 조회
      List<Map<String, dynamic>> plants = await FirebaseService.getMyPlants();

      if (plants.isEmpty) {
        print('⚠️ 등록된 식물이 없습니다.');
        return;
      }

      for (int i = 0; i < plants.length; i++) {
        var plant = plants[i];
        String plantName = plant['nickname'] ?? '식물 ${i + 1}';

        // 각 식물마다 새로운 랜덤 센서 데이터 생성
        Map<String, dynamic> sensorData =
            FirebaseService.generateRandomSensorData();
        await checkPlantStatusWithSensorData(plant, sensorData);
      }
    } catch (e) {
      print('❌ 백그라운드 식물 상태 확인 실패: $e');
    }
  }

  /// 특정 식물의 센서 데이터로 알림 확인 (공용 함수)
  static Future<void> checkPlantStatusWithSensorData(
    Map<String, dynamic> plant,
    Map<String, dynamic> sensorData,
  ) async {
    try {
      String plantId = plant['id'] ?? '';
      String plantName = plant['nickname'] ?? '내 식물';

      // 알림 설정 가져오기
      Map<String, dynamic>? alarmSettings = plant['alarmSettings'];
      if (alarmSettings == null) {
        print('⚠️ [$plantName] 알림 설정이 없습니다.');
        return;
      }

      // 각 센서별 알림 확인
      await _checkMoistureAlert(plantId, plantName, sensorData, alarmSettings);
      await _checkTemperatureAlert(
        plantId,
        plantName,
        sensorData,
        alarmSettings,
      );
      await _checkConductivityAlert(
        plantId,
        plantName,
        sensorData,
        alarmSettings,
      );
    } catch (e) {
      print('❌ 식물 상태 확인 실패: $e');
    }
  }

  /// 수분 알림 확인
  static Future<void> _checkMoistureAlert(
    String plantId,
    String plantName,
    Map<String, dynamic> sensorData,
    Map<String, dynamic> alarmSettings,
  ) async {
    final moistureAlarm = alarmSettings['moistureAlarm'];
    if (moistureAlarm == null || !(moistureAlarm['enabled'] ?? false)) {
      return;
    }

    int currentMoisture = sensorData['moisture'] ?? 50;
    int targetMoisture = moistureAlarm['value'] ?? 30;

    if (currentMoisture < targetMoisture) {
      String notificationKey = '${plantId}_moisture';

      if (_canSendNotification(notificationKey)) {
        await NotificationService.showMoistureAlert(
          plantName: plantName,
          currentValue: currentMoisture,
          targetValue: targetMoisture,
        );

        _lastNotificationTime[notificationKey] = DateTime.now();
      }
    }
  }

  /// 온도 알림 확인
  static Future<void> _checkTemperatureAlert(
    String plantId,
    String plantName,
    Map<String, dynamic> sensorData,
    Map<String, dynamic> alarmSettings,
  ) async {
    final temperatureAlarm = alarmSettings['temperatureAlarm'];
    if (temperatureAlarm == null || !(temperatureAlarm['enabled'] ?? false)) {
      return;
    }

    int currentTemperature = sensorData['temperature'] ?? 22;
    int targetTemperature = temperatureAlarm['value'] ?? 22;

    int tolerance = 3;
    bool isTooHot = currentTemperature > (targetTemperature + tolerance);
    bool isTooLow = currentTemperature < (targetTemperature - tolerance);

    if (isTooHot || isTooLow) {
      String notificationKey = '${plantId}_temperature';

      if (_canSendNotification(notificationKey)) {
        String status = isTooHot ? '너무 뜨거움' : '너무 추움';

        await NotificationService.showTemperatureAlert(
          plantName: plantName,
          currentValue: currentTemperature,
          targetValue: targetTemperature,
          isTooHot: isTooHot,
        );

        _lastNotificationTime[notificationKey] = DateTime.now();
      }
    }
  }

  /// 전도도 알림 확인
  static Future<void> _checkConductivityAlert(
    String plantId,
    String plantName,
    Map<String, dynamic> sensorData,
    Map<String, dynamic> alarmSettings,
  ) async {
    final conductivityAlarm = alarmSettings['conductivityAlarm'];
    if (conductivityAlarm == null || !(conductivityAlarm['enabled'] ?? false)) {
      return;
    }

    double currentConductivity = sensorData['conductivity'] ?? 1.5;
    int targetConductivity = conductivityAlarm['value'] ?? 3;

    double tolerance = 1.0;
    bool isTooHigh = currentConductivity > (targetConductivity + tolerance);
    bool isTooLow = currentConductivity < (targetConductivity - tolerance);

    if (isTooHigh || isTooLow) {
      String notificationKey = '${plantId}_conductivity';

      if (_canSendNotification(notificationKey)) {
        String status = isTooHigh ? '너무 높음' : '너무 낮음';

        await NotificationService.showConductivityAlert(
          plantName: plantName,
          currentValue: currentConductivity,
          targetValue: targetConductivity,
          isTooHigh: isTooHigh,
        );

        _lastNotificationTime[notificationKey] = DateTime.now();
      }
    }
  }

  /// 알림 발송 가능 여부 확인 (스팸 방지)
  static bool _canSendNotification(String notificationKey) {
    DateTime? lastTime = _lastNotificationTime[notificationKey];
    if (lastTime == null) return true;

    DateTime now = DateTime.now();
    Duration elapsed = now.difference(lastTime);

    return elapsed >= _notificationCooldown;
  }

  /// 테스트용 즉시 알림 발송
  static Future<void> sendTestNotification(Map<String, dynamic> plant) async {
    String plantName = plant['nickname'] ?? '테스트 식물';

    await NotificationService.showNotification(
      id: 999,
      title: '🧪 테스트 알림',
      body: '$plantName의 알림 기능이 정상 작동합니다!',
      plantName: plantName,
    );
  }
}
