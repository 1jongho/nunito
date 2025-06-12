import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nunito/widgets/modal/alarm.dart';
import 'package:nunito/widgets/switch.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/services/notification_service.dart'; // 수정
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nunito/widgets/toast.dart';

class PlantAlarmScreen extends StatefulWidget {
  final Map<String, dynamic> plant;

  const PlantAlarmScreen({super.key, required this.plant});

  @override
  State<PlantAlarmScreen> createState() => _PlantAlarmScreenState();
}

class _PlantAlarmScreenState extends State<PlantAlarmScreen> {
  // 알림 설정 상태 변수들
  final Map<String, bool> _alarmStates = {
    '수분 알림': true,
    '온도 알림': true,
    '전도도 알림': true,
  };

  // 각 알림별 현재 선택된 값
  final Map<String, int> _alarmValues = {
    '수분 알림': 30, // 기본값: 30%
    '온도 알림': 22, // 기본값: 22°C
    '전도도 알림': 3, // 기본값: 3 mS/cm
  };

  // 관리자가 설정한 각 알림별 허용 범위 (최소값~최대값)
  final Map<String, Map<String, int>> _alarmRanges = {
    '수분 알림': {'min': 10, 'max': 90}, // 10% ~ 90%
    '온도 알림': {'min': 5, 'max': 35}, // 5°C ~ 35°C
    '전도도 알림': {'min': 1, 'max': 10}, // 1 ~ 10 mS/cm
  };

  // 각 알림별 단위
  final Map<String, String> _alarmUnits = {
    '수분 알림': '%',
    '온도 알림': '°C',
    '전도도 알림': 'mS/cm',
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  // 현재 식물의 알림 설정 불러오기
  void _loadCurrentSettings() {
    try {
      final alarmSettings =
          widget.plant['alarmSettings'] as Map<String, dynamic>?;

      if (alarmSettings != null) {
        // 수분 알림 설정
        final moistureAlarm =
            alarmSettings['moistureAlarm'] as Map<String, dynamic>?;
        if (moistureAlarm != null) {
          _alarmStates['수분 알림'] = moistureAlarm['enabled'] ?? true;
          _alarmValues['수분 알림'] = moistureAlarm['value'] ?? 30;
        }

        // 온도 알림 설정
        final temperatureAlarm =
            alarmSettings['temperatureAlarm'] as Map<String, dynamic>?;
        if (temperatureAlarm != null) {
          _alarmStates['온도 알림'] = temperatureAlarm['enabled'] ?? true;
          _alarmValues['온도 알림'] = temperatureAlarm['value'] ?? 22;
        }

        // 전도도 알림 설정
        final conductivityAlarm =
            alarmSettings['conductivityAlarm'] as Map<String, dynamic>?;
        if (conductivityAlarm != null) {
          _alarmStates['전도도 알림'] = conductivityAlarm['enabled'] ?? true;
          _alarmValues['전도도 알림'] = conductivityAlarm['value'] ?? 3;
        }
      }
    } catch (e) {
      print('알림 설정 로드 실패: $e');
    }
  }

  // 알림 설정 저장
  Future<void> _saveAlarmSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 알림 설정 정보 구성
      Map<String, dynamic> alarmSettings = {
        'moistureAlarm': {
          'enabled': _alarmStates['수분 알림'],
          'value': _alarmValues['수분 알림'],
          'unit': _alarmUnits['수분 알림'],
        },
        'temperatureAlarm': {
          'enabled': _alarmStates['온도 알림'],
          'value': _alarmValues['온도 알림'],
          'unit': _alarmUnits['온도 알림'],
        },
        'conductivityAlarm': {
          'enabled': _alarmStates['전도도 알림'],
          'value': _alarmValues['전도도 알림'],
          'unit': _alarmUnits['전도도 알림'],
        },
      };

      // Firebase Firestore에 알림 설정 업데이트
      await FirebaseService.updatePlantAlarmSettings(
        widget.plant['id'],
        alarmSettings,
      );

      // 성공 메시지
      CustomFluttertoast.showToast(
        context: context,
        msg: "알림 설정이 저장되었습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFF0BB57F),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // 이전 화면으로 돌아가기
      Navigator.pop(context);
    } catch (e) {
      print('알림 설정 저장 실패: $e');
      CustomFluttertoast.showToast(
        context: context,
        msg: "알림 설정 저장에 실패했습니다: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 테스트 알림 발송
  Future<void> _sendTestNotification() async {
    try {
      // 즉시 테스트 알림 발송
      await NotificationService.showNotification(
        id: 999,
        title: '🧪 즉시 테스트 알림',
        body:
            '알림이 정상 작동합니다! 시간: ${DateTime.now().toString().substring(11, 19)}',
      );
      CustomFluttertoast.showToast(
        context: context,
        msg: "즉시 테스트 알림이 발송되었습니다!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFF0BB57F),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print('테스트 알림 발송 실패: $e');
      CustomFluttertoast.showToast(
        context: context,
        msg: "테스트 알림 발송에 실패했습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // 연속 알림 테스트
  Future<void> _sendMultipleTestNotifications() async {
    try {
      CustomFluttertoast.showToast(
        context: context,
        msg: "3개의 연속 알림을 발송합니다...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // 3개의 연속 알림 발송 (1초 간격)
      for (int i = 1; i <= 3; i++) {
        await NotificationService.showNotification(
          id: 900 + i,
          title: '🔔 연속 테스트 $i/3',
          body: '$i번째 알림입니다. ${DateTime.now().toString().substring(11, 19)}',
        );

        if (i < 3) {
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // 앱을 백그라운드로 보내라는 안내
      await Future.delayed(Duration(seconds: 1));
      CustomFluttertoast.showToast(
        context: context,
        msg: "홈 버튼을 눌러 앱을 백그라운드로 보내보세요!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print('연속 알림 발송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Color(0xFF363636),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF363636),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAlarmSettings,
            child:
                _isSaving
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Color(0xFF0BB57F),
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Color(0xFF0BB57F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 식물 정보 섹션
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.plant['nickname'] ?? '내 식물',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        color: Color(0xFF363636),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.plant['scientificName'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0BB57F),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // 물방울 아이콘
              Center(
                child: SvgPicture.asset(
                  'assets/icon/water_drop.svg',
                  width: 70,
                  height: 70,
                ),
              ),

              SizedBox(height: 32),

              // 설명 텍스트
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE9ECEF)),
                ),
                child: Text(
                  '알림은 토양 센서로 토양의 정보를 전달받아서\n특정 수치를 벗어날 경우 수분, 온도, 전도도의 수치를\n정상으로 맞출 수 있도록 알림을 제공합니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Color(0xFF0BB57F),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 32),

              // 테스트 알림 버튼 추가
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: Icon(Icons.notifications_active, size: 20),
                  label: Text(
                    '즉시 알림 테스트',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 연속 알림 테스트 버튼 추가
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendMultipleTestNotifications,
                  icon: Icon(Icons.notifications, size: 20),
                  label: Text(
                    '연속 알림 테스트 (3개)',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // 알림 설정 목록
              Column(
                children: [
                  // 수분 알림 설정
                  _buildAlarmSettingItem('수분 알림'),
                  SizedBox(height: 16),

                  // 온도 알림 설정
                  _buildAlarmSettingItem('온도 알림'),
                  SizedBox(height: 16),

                  // 전도도 알림 설정
                  _buildAlarmSettingItem('전도도 알림'),
                ],
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmSettingItem(String title) {
    final currentValue = _alarmValues[title]!;
    final isEnabled = _alarmStates[title]!;
    final range = _alarmRanges[title]!;
    final unit = _alarmUnits[title]!;

    return InkWell(
      onTap: () {
        // 알림 설정 모달 표시
        AlarmSettingModal.show(
          context: context,
          title: title,
          minValue: range['min']!,
          maxValue: range['max']!,
          initialValue: currentValue,
          unit: unit,
          onValueSelected: (selectedValue) {
            setState(() {
              _alarmValues[title] = selectedValue;
            });
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
                color: Color(0xFF0BB57F),
              ),
            ),
            Spacer(),
            Text(
              '$currentValue$unit',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                color: Color(0xFF363636),
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.unfold_more_rounded, size: 30, color: Color(0xFF363636)),
            SizedBox(width: 10),
            // 스위치
            CustomSwitch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  _alarmStates[title] = value;
                });
              },
              activeColor: Colors.white, // ON 상태 썸 색상
              inactiveColor: Colors.white, // OFF 상태 썸 색상
              activeTrackColor: Color(0xFF0BB57F), // ON 상태 트랙 색상
              inactiveTrackColor: Color(0xFFB0B0B0), // OFF 상태 트랙 색상
              width: 51, // 스위치 너비
              height: 31, // 스위치 높이
              animationDuration: Duration(milliseconds: 80), // 애니메이션 속도
            ),
          ],
        ),
      ),
    );
  }
}
