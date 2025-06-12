import 'package:flutter/material.dart';
import 'package:nunito/screens/plantmyScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nunito/widgets/modal/date_picker_modal.dart';
import 'package:nunito/widgets/modal/alarm.dart';
import 'package:nunito/widgets/switch.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nunito/services/firebase_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nunito/widgets/toast.dart';

class AddPlantScreen extends StatefulWidget {
  final String? scientificName;

  const AddPlantScreen({super.key, this.scientificName});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  int _currentStep = 0;

  // 각 단계별 데이터를 저장할 변수들
  String? selectedPlantType;
  Map<String, dynamic> plantDetails = {};
  DateTime selectedDate = DateTime.now();

  // 컨트롤러 추가
  late TextEditingController _scientificNameController;
  final TextEditingController _nicknameController = TextEditingController();

  // 이미지 관련 변수들
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // 알림 설정 상태 변수들
  Map<String, bool> _alarmStates = {
    '수분 알림': true,
    '온도 알림': true,
    '전도도 알림': true,
  };

  // 각 알림별 현재 선택된 값
  Map<String, int> _alarmValues = {
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

  @override
  void initState() {
    super.initState();

    // 학명 컨트롤러 초기화 및 값 설정
    _scientificNameController = TextEditingController(
      text: widget.scientificName ?? '',
    );

    // 학명이 있으면 plantDetails에 추가
    if (widget.scientificName != null) {
      plantDetails['scientificName'] = widget.scientificName;
    }

    // 날짜 초기화
    plantDetails['startDate'] = DateFormat('yyyy/MM/dd').format(selectedDate);
  }

  @override
  void dispose() {
    _scientificNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print('✅ 이미지 선택 완료: ${image.path}');
      }
    } catch (e) {
      print('❌ 이미지 선택 실패: $e');
      CustomFluttertoast.showToast(
        context: context,
        msg: "이미지 선택에 실패했습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentStep + 1}/3 단계',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions:
            _currentStep == 2
                ? [
                  TextButton(
                    onPressed:
                        _isUploading
                            ? null
                            : () {
                              _savePlant(skipImage: true);
                            },
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: _isUploading ? Colors.grey : Colors.blue,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ]
                : null,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // 컨텐츠 영역
              Expanded(child: _getStepContent(_currentStep)),

              // 하단 버튼
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed:
                      _isUploading
                          ? null
                          : () {
                            if (_currentStep < 2) {
                              // 1단계에서 필수 필드 검증
                              if (_currentStep == 0) {
                                if (_nicknameController.text.trim().isEmpty) {
                                  CustomFluttertoast.showToast(
                                    context: context,
                                    msg: "애칭을 입력해주세요.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Colors.orange,
                                    textColor: Colors.white,
                                    fontSize: 16.0,
                                  );
                                  return;
                                }
                                if (_scientificNameController.text
                                    .trim()
                                    .isEmpty) {
                                  CustomFluttertoast.showToast(
                                    context: context,
                                    msg: "학명을 입력해주세요.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Colors.orange,
                                    textColor: Colors.white,
                                    fontSize: 16.0,
                                  );
                                  return;
                                }
                              }

                              setState(() {
                                _currentStep += 1;
                              });
                            } else {
                              _savePlant();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isUploading ? Colors.grey : Color(0xFF0BB57F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isUploading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '저장 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          )
                          : Text(
                            _currentStep == 2 ? '추가하기' : '다음',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 현재 단계에 맞는 컨텐츠 반환
  Widget _getStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep1Content();
      case 1:
        return _buildStep2Content();
      case 2:
        return _buildStep3Content();
      default:
        return Container();
    }
  }

  Widget _buildStep1Content() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 60),
          Text(
            '나만의 식물을 추가하세요. 🌱',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 42),

          // 애칭 입력 필드
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  '애칭',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '반려 식물의 애칭을 정해주세요.',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    onChanged: (value) {
                      plantDetails['nickname'] = value;
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 학명 입력 필드
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  '학명',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _scientificNameController,
                    decoration: InputDecoration(
                      hintText: '반려 식물의 학명을 입력해주세요.',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    onChanged: (value) {
                      plantDetails['scientificName'] = value;
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 함께한 시간 입력 필드
          InkWell(
            onTap: () {
              DatePickerModal.show(
                context: context,
                initialDate: selectedDate,
                onDateSelected: (DateTime date) {
                  setState(() {
                    selectedDate = date;
                    plantDetails['startDate'] = DateFormat(
                      'yyyy/MM/dd',
                    ).format(date);
                  });
                },
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                title: '함께한 시간',
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    '함께한 시간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(selectedDate),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, color: Color(0xFF363636)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Content() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알림을 설정하세요.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 32),

          Center(
            child: SvgPicture.asset(
              'assets/icon/water_drop.svg',
              width: 70,
              height: 70,
            ),
          ),

          SizedBox(height: 40),

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
    );
  }

  Widget _buildStep3Content() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),

          // 식물 이미지 표시 영역
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            child:
                _selectedImage != null
                    ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Center(
                      child: SvgPicture.asset(
                        'assets/image/default_plant_image.svg',
                        width: 70,
                        height: 70,
                      ),
                    ),
          ),

          SizedBox(height: 80),

          // 사진 등록 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF363636),
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _pickImage,
            child: Text(
              _selectedImage != null ? '사진 변경' : '사진 등록',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
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

  // 식물 저장 함수 (Firebase 연동)
  Future<void> _savePlant({bool skipImage = false}) async {
    try {
      setState(() {
        _isUploading = true;
      });

      print('🔍 식물 저장 시작...');

      // 필수 필드 검증
      if (_nicknameController.text.trim().isEmpty) {
        throw Exception('애칭을 입력해주세요.');
      }
      if (_scientificNameController.text.trim().isEmpty) {
        throw Exception('학명을 입력해주세요.');
      }

      String? imageUrl;

      // 이미지 업로드 처리
      if (!skipImage && _selectedImage != null) {
        print('📸 이미지 업로드 중...');

        // 파일명 생성 (현재 시간 + 애칭)
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_nicknameController.text.trim()}.jpg';

        // Firebase Storage에 이미지 업로드
        imageUrl = await FirebaseService.uploadImage(_selectedImage!, fileName);
        print('✅ 이미지 업로드 완료: $imageUrl');
      }

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

      print('💾 Firestore에 식물 정보 저장 중...');

      // Firebase Firestore에 식물 정보 저장
      String plantId = await FirebaseService.addMyPlant(
        nickname: _nicknameController.text.trim(),
        scientificName: _scientificNameController.text.trim(),
        startDate: selectedDate,
        imageUrl: imageUrl, // 이미지 URL (없으면 null)
        alarmSettings: alarmSettings,
      );

      print('✅ 식물 저장 완료: $plantId');

      // 성공 메시지
      CustomFluttertoast.showToast(
        context: context,
        msg: "${_nicknameController.text.trim()}이(가) 추가되었습니다!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFF0BB57F),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // 내 식물 페이지로 이동 (기존 스택 모두 제거)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => PlantMyScreen()),
        (route) => false,
      );
    } catch (e) {
      print('❌ 식물 저장 실패: $e');

      // 오류 메시지 표시
      CustomFluttertoast.showToast(
        context: context,
        msg: "저장 중 오류가 발생했습니다: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
