import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/recommendresultScreen.dart';

class PlantRecommendScreen extends StatefulWidget {
  const PlantRecommendScreen({super.key});

  @override
  State<PlantRecommendScreen> createState() => _PlantRecommendScreenState();
}

class _PlantRecommendScreenState extends State<PlantRecommendScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // 설문 응답 저장
  String? _selectedLight;
  String? _selectedTemperature;
  String? _selectedHumidity;
  String? _selectedLocation;
  String? _selectedLevel;
  String? _selectedCareRequirement;

  // 각 단계별 옵션들
  final List<Map<String, String>> _lightOptions = [
    {'key': 'low', 'value': '낮은 광도'},
    {'key': 'medium', 'value': '중간 광도'},
    {'key': 'high', 'value': '높은 광도'},
  ];

  final List<Map<String, String>> _temperatureOptions = [
    {'key': 'under_0', 'value': '0°C 이하'},
    {'key': '5', 'value': '5°C'},
    {'key': '7', 'value': '7°C'},
    {'key': '10', 'value': '10°C'},
    {'key': 'over_13', 'value': '13°C 이상'},
  ];

  final List<Map<String, String>> _humidityOptions = [
    {'key': 'under_40', 'value': '40% 미만'},
    {'key': '40_70', 'value': '40~70%'},
    {'key': 'over_70', 'value': '70% 이상'},
  ];

  final List<Map<String, String>> _locationOptions = [
    {'key': 'balcony_inner', 'value': '발코니\n내측'},
    {'key': 'balcony_window', 'value': '발코니\n창측'},
    {'key': 'living_inner', 'value': '거실\n내측'},
    {'key': 'living_window', 'value': '거실\n창측'},
    {'key': 'indoor_dark', 'value': '실내\n어두운 곳'},
    {'key': 'humid_place', 'value': '습한 곳'},
    {'key': 'wide_place', 'value': '넓은 곳'},
    {'key': 'narrow_place', 'value': '좁은 곳'},
  ];

  final List<Map<String, String>> _levelOptions = [
    {'key': 'beginner', 'value': '초보자'},
    {'key': 'experienced', 'value': '경험자'},
    {'key': 'expert', 'value': '전문가'},
  ];

  final List<Map<String, String>> _careOptions = [
    {'key': 'low', 'value': '낮음\n잘 견딤'},
    {'key': 'normal', 'value': '보통\n약간 잘 견딤'},
    {'key': 'needed', 'value': '필요함'},
    {'key': 'special', 'value': '특별 관리 요구'},
    {'key': 'other', 'value': '기타'},
  ];

  void _selectOption(String value) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedLight = value;
          break;
        case 1:
          _selectedTemperature = value;
          break;
        case 2:
          _selectedHumidity = value;
          break;
        case 3:
          _selectedLocation = value;
          break;
        case 4:
          _selectedLevel = value;
          break;
        case 5:
          _selectedCareRequirement = value;
          break;
      }
    });
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedLight != null;
      case 1:
        return _selectedTemperature != null;
      case 2:
        return _selectedHumidity != null;
      case 3:
        return _selectedLocation != null;
      case 4:
        return _selectedLevel != null;
      case 5:
        return _selectedCareRequirement != null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitSurvey();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitSurvey() {
    Map<String, String?> surveyData = {
      'light': _selectedLight,
      'temperature': _selectedTemperature,
      'humidity': _selectedHumidity,
      'location': _selectedLocation,
      'level': _selectedLevel,
      'careRequirement': _selectedCareRequirement,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlantRecommendResultScreen(surveyData: surveyData),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '광도';
      case 1:
        return '온도';
      case 2:
        return '습도';
      case 3:
        return '장소';
      case 4:
        return '수준';
      case 5:
        return '관리요구도';
      default:
        return '';
    }
  }

  List<Map<String, String>> _getCurrentOptions() {
    switch (_currentStep) {
      case 0:
        return _lightOptions;
      case 1:
        return _temperatureOptions;
      case 2:
        return _humidityOptions;
      case 3:
        return _locationOptions;
      case 4:
        return _levelOptions;
      case 5:
        return _careOptions;
      default:
        return [];
    }
  }

  String? _getCurrentSelection() {
    switch (_currentStep) {
      case 0:
        return _selectedLight;
      case 1:
        return _selectedTemperature;
      case 2:
        return _selectedHumidity;
      case 3:
        return _selectedLocation;
      case 4:
        return _selectedLevel;
      case 5:
        return _selectedCareRequirement;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size;
    final options = _getCurrentOptions();
    final currentSelection = _getCurrentSelection();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '${_currentStep + 1}/$_totalSteps 단계',
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
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 진행률 표시
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0BB57F)),
              minHeight: 2,
            ),
          ),

          // 단계 제목
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Text(
              _getStepTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
                color: Color(0xFF363636),
              ),
            ),
          ),

          // 옵션 그리드
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child:
                  _currentStep == 3
                      ? _buildLocationGrid(options, currentSelection)
                      : _buildNormalGrid(options, currentSelection),
            ),
          ),

          // 다음 버튼
          Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canProceed() ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canProceed() ? Color(0xFF0BB57F) : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? '완료' : '다음',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildNormalGrid(
    List<Map<String, String>> options,
    String? currentSelection,
  ) {
    // 온도 단계는 5개 옵션이므로 특별 처리
    if (_currentStep == 1) {
      return Column(
        children: [
          // 첫 번째 행 (2개)
          Row(
            children: [
              Expanded(child: _buildOptionCard(options[0], currentSelection)),
              SizedBox(width: 12),
              Expanded(child: _buildOptionCard(options[1], currentSelection)),
            ],
          ),
          SizedBox(height: 12),
          // 두 번째 행 (2개)
          Row(
            children: [
              Expanded(child: _buildOptionCard(options[2], currentSelection)),
              SizedBox(width: 12),
              Expanded(child: _buildOptionCard(options[3], currentSelection)),
            ],
          ),
          SizedBox(height: 12),
          // 세 번째 행 (1개, 중앙 정렬)
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: _buildOptionCard(options[4], currentSelection),
            ),
          ),
        ],
      );
    }

    // 기본 3옵션 그리드 (수직 배치)
    return Column(
      children: [
        for (int i = 0; i < options.length; i += 2) ...[
          if (i + 1 < options.length)
            Row(
              children: [
                Expanded(child: _buildOptionCard(options[i], currentSelection)),
                SizedBox(width: 12),
                Expanded(
                  child: _buildOptionCard(options[i + 1], currentSelection),
                ),
              ],
            )
          else
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: _buildOptionCard(options[i], currentSelection),
              ),
            ),
          if (i + 2 < options.length) SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildLocationGrid(
    List<Map<String, String>> options,
    String? currentSelection,
  ) {
    return Column(
      children: [
        // 첫 번째 행 (발코니)
        Row(
          children: [
            Expanded(child: _buildOptionCard(options[0], currentSelection)),
            SizedBox(width: 12),
            Expanded(child: _buildOptionCard(options[1], currentSelection)),
          ],
        ),
        SizedBox(height: 12),
        // 두 번째 행 (거실)
        Row(
          children: [
            Expanded(child: _buildOptionCard(options[2], currentSelection)),
            SizedBox(width: 12),
            Expanded(child: _buildOptionCard(options[3], currentSelection)),
          ],
        ),
        SizedBox(height: 12),
        // 세 번째 행 (실내, 습한 곳)
        Row(
          children: [
            Expanded(child: _buildOptionCard(options[4], currentSelection)),
            SizedBox(width: 12),
            Expanded(child: _buildOptionCard(options[5], currentSelection)),
          ],
        ),
        SizedBox(height: 12),
        // 네 번째 행 (넓은 곳, 좁은 곳)
        Row(
          children: [
            Expanded(child: _buildOptionCard(options[6], currentSelection)),
            SizedBox(width: 12),
            Expanded(child: _buildOptionCard(options[7], currentSelection)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    Map<String, String> option,
    String? currentSelection,
  ) {
    final isSelected = currentSelection == option['key'];

    return GestureDetector(
      onTap: () => _selectOption(option['key']!),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF0BB57F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF0BB57F) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            option['value']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              color: isSelected ? Colors.white : Color(0xFF0BB57F),
            ),
          ),
        ),
      ),
    );
  }
}
