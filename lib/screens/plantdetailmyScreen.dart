import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nunito/widgets/modal/date_picker_modal.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/screens/plantalarmScreen.dart';
import 'dart:async';

class PlantDetailMyScreen extends StatefulWidget {
  final Map<String, dynamic> plant;

  const PlantDetailMyScreen({super.key, required this.plant});

  @override
  State<PlantDetailMyScreen> createState() => _PlantDetailMyScreenState();
}

class _PlantDetailMyScreenState extends State<PlantDetailMyScreen> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController _diaryController = TextEditingController();

  // 센서 데이터 (랜덤으로 갱신됨)
  Map<String, dynamic> _sensorData = {
    'moisture': 50,
    'temperature': 22,
    'conductivity': 1.5,
    'lastUpdated': DateTime.now(),
  };

  Map<String, dynamic> _generateNormalSensorData() {
    return {
      'moisture': 55, // 정상 범위 40-70% 중간값
      'temperature': 22, // 정상 범위 18-25°C 중간값
      'conductivity': 1.5, // 정상 범위 1.0-2.0 mS/cm 중간값
      'lastUpdated': DateTime.now(),
    };
  }

  // 일지 데이터
  final Map<String, String> _diaries = {};
  bool _isLoadingDiary = false;
  bool _isSavingDiary = false;

  // 센서 데이터 자동 갱신을 위한 타이머
  Timer? _sensorUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadDiaryForDate(selectedDate);
    _loadInitialSensorData();
    _startSensorDataTimer();
    _incrementViewCount();
  }

  @override
  void dispose() {
    _diaryController.dispose();
    _sensorUpdateTimer?.cancel(); // 타이머 정리
    super.dispose();
  }

  // 초기 센서 데이터 로드
  void _loadInitialSensorData() {
    setState(() {
      _sensorData = FirebaseService.generateRandomSensorData();
    });
  }

  // 센서 데이터 자동 갱신 타이머 시작 (3초마다)
  void _startSensorDataTimer() {
    _sensorUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _sensorData = FirebaseService.generateRandomSensorData();
        });

        // 선택적으로 Firebase에 센서 데이터 기록 (매번 저장하지 않도록 조건 추가)
        if (DateTime.now().minute % 5 == 0) {
          // 5분마다만 Firebase에 저장
          _saveSensorDataToFirebase();
        }
      }
    });
  }

  Future<void> _incrementViewCount() async {
    try {
      final plantId = widget.plant['id'];
      if (plantId != null) {
        await FirebaseService.incrementPlantViewCount(plantId);
        print('✅ 조회수 증가 완료: $plantId');
      }
    } catch (e) {
      print('❌ 조회수 증가 실패: $e');
      // 조회수 증가 실패는 사용자에게 알리지 않음 (백그라운드 작업)
    }
  }

  // Firebase에 센서 데이터 저장 (선택적)
  Future<void> _saveSensorDataToFirebase() async {
    try {
      await FirebaseService.saveSensorData(widget.plant['id'], _sensorData);
    } catch (e) {
      print('센서 데이터 Firebase 저장 실패 (무시): $e');
    }
  }

  // 선택된 날짜의 일지 불러오기
  Future<void> _loadDiaryForDate(DateTime date) async {
    setState(() {
      _isLoadingDiary = true;
    });

    try {
      String diaryText = await FirebaseService.getDiary(
        widget.plant['id'],
        date,
      );
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      _diaries[dateKey] = diaryText;
      _diaryController.text = diaryText;
    } catch (e) {
      print('일지 로드 실패: $e');
      _diaryController.text = '';
      // 사용자에게 오류 메시지 표시하지 않음 (빈 일지일 수 있음)
    } finally {
      setState(() {
        _isLoadingDiary = false;
      });
    }
  }

  // 일지 저장
  Future<void> _saveDiary() async {
    if (_diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일지 내용을 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSavingDiary = true;
    });

    try {
      await FirebaseService.saveDiary(
        widget.plant['id'],
        selectedDate,
        _diaryController.text.trim(),
      );

      String dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      _diaries[dateKey] = _diaryController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일지가 저장되었습니다.'),
          backgroundColor: Color(0xFF0BB57F),
        ),
      );
    } catch (e) {
      print('일지 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일지 저장에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSavingDiary = false;
      });
    }
  }

  // 센서 데이터 수동 새로고침
  void _refreshSensorData() {
    setState(() {
      // 기존의 랜덤 데이터 대신 정상 수치로 설정
      _sensorData = _generateNormalSensorData();
    });

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '센서 데이터가 정상 수치로 조정되었습니다.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        backgroundColor: Color(0xFF0BB57F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 함께한 시간 계산
  String _calculateTimeWithPlant() {
    if (widget.plant['startDate'] == null) {
      return 'D+ 1';
    }

    try {
      DateTime startDate = (widget.plant['startDate'] as Timestamp).toDate();
      DateTime now = DateTime.now();

      DateTime startDateOnly = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      DateTime nowDateOnly = DateTime(now.year, now.month, now.day);

      final difference = nowDateOnly.difference(startDateOnly);
      final days = difference.inDays + 1; // +1을 추가해서 1일부터 시작

      if (days < 1) return 'D+ 1';

      return 'D+ $days'; // 오늘 등록하면 D+ 1
    } catch (e) {
      return 'D+ 1';
    }
  }

  // 상태 색상 결정
  Color _getStatusColor(String type, double value) {
    // 각 센서별 정상 범위 (실제로는 식물별로 다르게 설정)
    Map<String, Map<String, double>> normalRanges = {
      'moisture': {'min': 40, 'max': 70},
      'temperature': {'min': 18, 'max': 25},
      'conductivity': {'min': 1.0, 'max': 2.0},
    };

    double min = normalRanges[type]?['min'] ?? 0;
    double max = normalRanges[type]?['max'] ?? 100;

    if (value < min) return Colors.red; // 위험
    if (value > max) return Colors.orange; // 주의
    return Color(0xFF0BB57F); // 정상
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '내 식물',
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
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Color(0xFF0BB57F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                // 알림 설정 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantAlarmScreen(plant: widget.plant),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 식물 이미지
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child:
                    widget.plant['imageUrl'] != null &&
                            widget.plant['imageUrl'].toString().isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            widget.plant['imageUrl'].toString(),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: Color(0xFF0BB57F),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: EdgeInsets.all(40),
                                child: SvgPicture.asset(
                                  'assets/image/default_plant_image.svg',
                                  width: 80,
                                  height: 80,
                                ),
                              );
                            },
                          ),
                        )
                        : Container(
                          padding: EdgeInsets.all(40),
                          child: SvgPicture.asset(
                            'assets/image/default_plant_image.svg',
                            width: 80,
                            height: 80,
                          ),
                        ),
              ),

              SizedBox(height: 24),

              // 식물 이름과 학명
              Text(
                widget.plant['nickname'] ?? '이름 없음',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF363636),
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.plant['scientificName'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0BB57F),
                  fontFamily: 'Pretendard',
                ),
              ),

              SizedBox(height: 32),

              // 함께한 시간
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '함께한 시간',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                          color: Color(0xFF363636),
                        ),
                      ),
                      Text(
                        widget.plant['startDate'] != null
                            ? '${DateFormat('yyyy/MM/dd').format((widget.plant['startDate'] as Timestamp).toDate())}~'
                            : '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ), // 균등한 패딩
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _calculateTimeWithPlant(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0BB57F),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // 토양 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '토양 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                          color: Color(0xFF363636),
                        ),
                      ),
                      Spacer(),
                      // 새로고침 버튼 추가
                      InkWell(
                        onTap: _refreshSensorData,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFF0BB57F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.refresh,
                            size: 16,
                            color: Color(0xFF0BB57F),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // 상태 표시
                      Row(
                        children: [
                          _buildStatusIndicator('위험', Colors.red),
                          SizedBox(width: 8),
                          _buildStatusIndicator('주의', Colors.orange),
                          SizedBox(width: 8),
                          _buildStatusIndicator('정상', Color(0xFF0BB57F)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // 마지막 업데이트 시간 표시
                  Text(
                    '마지막 업데이트: ${DateFormat('HH:mm:ss').format(_sensorData['lastUpdated'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 16),

                  // 센서 데이터
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          '수분',
                          '${_sensorData['moisture']}%',
                          _getStatusColor(
                            'moisture',
                            _sensorData['moisture'].toDouble(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildSensorCard(
                          '온도',
                          '${_sensorData['temperature']}°C',
                          _getStatusColor(
                            'temperature',
                            _sensorData['temperature'].toDouble(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildSensorCard(
                    '전도도',
                    '${_sensorData['conductivity']} mS/cm',
                    _getStatusColor(
                      'conductivity',
                      _sensorData['conductivity'],
                    ),
                    isFullWidth: true,
                  ),
                ],
              ),

              SizedBox(height: 24),

              // 일지
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '일지',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                          color: Color(0xFF363636),
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          DatePickerModal.show(
                            context: context,
                            initialDate: selectedDate,
                            onDateSelected: (DateTime date) {
                              setState(() {
                                selectedDate = date;
                              });
                              _loadDiaryForDate(date);
                            },
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                            title: '날짜 선택',
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              DateFormat('yyyy/MM/dd').format(selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0BB57F),
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF0BB57F),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // 일지 입력 영역
                  if (_isLoadingDiary)
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0BB57F),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _diaryController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: '오늘의 식물 상태나 관리 내용을 기록해보세요.',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'Pretendard',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),

                  SizedBox(height: 12),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingDiary ? null : _saveDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0BB57F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSavingDiary
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                '일지 저장',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    Color statusColor, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
