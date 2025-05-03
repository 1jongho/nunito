import 'package:flutter/material.dart';
import 'package:nunito/screens/plantbookScreen.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG를 위한 import 추가
import 'package:nunito/widgets/modal/date_picker_modal.dart'; // 날짜 선택기 import
import 'package:intl/intl.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  int _currentStep = 0;

  // 각 단계별 데이터를 저장할 변수들
  String? selectedPlantType;
  Map<String, dynamic> plantDetails = {};
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentStep + 1}/3 단계',
          style: TextStyle(fontSize: 16, fontFamily: 'Pretendard'),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                    onPressed: () {
                      // 건너뛰기 로직
                      _savePlant();
                    },
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Colors.blue,
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
                  onPressed: () {
                    if (_currentStep < 2) {
                      setState(() {
                        _currentStep += 1;
                      });
                    } else {
                      _savePlant();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0BB57F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
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
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '반려 식물의 애칭을 정해주세요.',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      isDense: true, // 텍스트필드 높이 줄이기
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '반려 식물의 학명을 입력해주세요.',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      isDense: true, // 텍스트필드 높이 줄이기
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
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
              // DatePickerModal.show 정적 메서드 사용
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
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(selectedDate),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.black54),
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
            // Icon 대신 SvgPicture 사용
            child: SvgPicture.asset(
              'assets/icon/water_drop.svg',
              width: 80,
              height: 80,
              color: Colors.blue,
            ),
          ),

          SizedBox(height: 40),

          // 수분 알림 설정
          _buildAlarmSettingItem('수분 알림', '30%'),

          SizedBox(height: 16),

          // 온도 알림 설정
          _buildAlarmSettingItem('온도 알림', '20°C'),

          SizedBox(height: 16),

          // 전도도 알림 설정
          _buildAlarmSettingItem('전도도 알림', '3.0mS/cm'),
        ],
      ),
    );
  }

  Widget _buildAlarmSettingItem(String title, String value) {
    return Container(
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
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              color: Color(0xFF0BB57F),
            ),
          ),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontFamily: 'Pretendard')),
          SizedBox(width: 10),
          Icon(Icons.arrow_drop_up_outlined, size: 18),
          Icon(Icons.arrow_drop_down_outlined, size: 18),
          SizedBox(width: 20),
          // 스위치 추가
          Switch(
            value: true, // 상태 관리 필요
            onChanged: (value) {
              // 상태 변경 처리
            },
            activeColor: Color(0xFF0BB57F),
            activeTrackColor: Color(0xFFE0F7F0),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Content() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40),

          // 식물 아이콘 또는 이미지
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Center(
              // 여기에도 SVG 사용하려면 아래 코드 활용
              child: SvgPicture.asset(
                'assets/icon/plantbook_T.svg', // 적절한 SVG 파일 경로로 변경
                width: 60,
                height: 60,
                color: Color(0xFF0BB57F),
              ),
            ),
          ),

          SizedBox(height: 60),

          // 사진 등록 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF363636),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              // 사진 등록 로직
            },
            child: Text(
              '사진 등록',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePlant() {
    // 식물 정보 저장 로직
    // Firebase나 다른 저장소에 데이터 저장

    // 저장 완료 후 식물도감 화면으로 이동
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => PlantBookScreen()),
      (route) => false, // 네비게이션 스택 초기화
    );
  }
}
