import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/models/plant.dart';
import 'package:nunito/services/plant_api_service.dart';
import 'package:nunito/screens/plantdetailScreen.dart';
import 'package:nunito/screens/addplantScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlantRecommendResultScreen extends StatefulWidget {
  final Map<String, String?> surveyData;

  const PlantRecommendResultScreen({super.key, required this.surveyData});

  @override
  State<PlantRecommendResultScreen> createState() =>
      _PlantRecommendResultScreenState();
}

class _PlantRecommendResultScreenState
    extends State<PlantRecommendResultScreen> {
  final PlantApiService _apiService = PlantApiService();
  List<Plant> _recommendedPlants = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendedPlants();
  }

  Future<void> _loadRecommendedPlants() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Map<String, String> apiParams = _buildApiParams();

      List<Plant> plants = await _apiService.getPlantListWithParams(apiParams);

      List<Plant> filteredPlants = _applyClientSideFiltering(plants);

      setState(() {
        _recommendedPlants = filteredPlants.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  List<Plant> _applyClientSideFiltering(List<Plant> plants) {
    List<Plant> filtered = List.from(plants);
    filtered.shuffle();
    return filtered;
  }

  Map<String, String> _buildApiParams() {
    Map<String, String> params = {};

    params['pageNo'] = '1';
    params['numOfRows'] = '50';

    if (widget.surveyData['light'] != null) {
      params['lightChkVal'] = _convertLightToApi(widget.surveyData['light']!);
    }

    if (widget.surveyData['temperature'] != null) {
      params['winterLwetChkVal'] = _convertTemperatureToApi(
        widget.surveyData['temperature']!,
      );
    }

    return params;
  }

  String _convertLightToApi(String lightValue) {
    switch (lightValue) {
      case 'low':
        return '055001';
      case 'medium':
        return '055002';
      case 'high':
        return '055003';
      default:
        return '';
    }
  }

  String _convertTemperatureToApi(String tempValue) {
    switch (tempValue) {
      case 'under_0':
        return '057001';
      case '5':
        return '057002';
      case '7':
        return '057003';
      case '10':
        return '057004';
      case 'over_13':
        return '057005';
      default:
        return '';
    }
  }

  String _getBestImageUrl(Plant plant) {
    String originalUrl = _getFirstImageUrl(plant.rtnFileUrl);
    if (originalUrl.isNotEmpty) {
      return originalUrl;
    }
    String thumbnailUrl = _getFirstImageUrl(plant.rtnThumbFileUrl);
    return thumbnailUrl;
  }

  String _getFirstImageUrl(String imageUrls) {
    if (imageUrls.isEmpty) return '';

    if (imageUrls.contains('|')) {
      final urls = imageUrls.split('|');
      if (urls.isNotEmpty) {
        return urls[0];
      }
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '식물 추천',
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 사용자 설정 요약
          Container(
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF9DB2CE).withOpacity(0.4)),
            ),
            child: Column(children: [_buildPreferenceText()]),
          ),

          // 결과 목록
          Expanded(child: _buildResultContent()),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildPreferenceText() {
    if (widget.surveyData.values.every((value) => value == null)) {
      return Text(
        '설정된 조건이 없습니다',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF363636),
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.center,
      children: _buildPreferenceTags(),
    );
  }

  List<Widget> _buildPreferenceTags() {
    List<Widget> tags = [];

    if (widget.surveyData['light'] != null) {
      tags.add(
        _buildEditableTag(
          '광도',
          _getLightText(widget.surveyData['light']!),
          'light',
        ),
      );
    }

    if (widget.surveyData['temperature'] != null) {
      tags.add(
        _buildEditableTag(
          '온도',
          _getTemperatureText(widget.surveyData['temperature']!),
          'temperature',
        ),
      );
    }

    if (widget.surveyData['humidity'] != null) {
      tags.add(
        _buildEditableTag(
          '습도',
          _getHumidityText(widget.surveyData['humidity']!),
          'humidity',
        ),
      );
    }

    if (widget.surveyData['location'] != null) {
      tags.add(
        _buildEditableTag(
          '장소',
          _getLocationText(widget.surveyData['location']!),
          'location',
        ),
      );
    }

    if (widget.surveyData['level'] != null) {
      tags.add(
        _buildEditableTag(
          '수준',
          _getLevelText(widget.surveyData['level']!),
          'level',
        ),
      );
    }

    if (widget.surveyData['careRequirement'] != null) {
      tags.add(
        _buildEditableTag(
          '관리요구도',
          _getCareText(widget.surveyData['careRequirement']!),
          'careRequirement',
        ),
      );
    }

    return tags;
  }

  Widget _buildEditableTag(String category, String value, String key) {
    return GestureDetector(
      onTap: () => _showEditModal(category, key),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF0BB57F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF0BB57F).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0BB57F),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLightText(String key) {
    switch (key) {
      case 'low':
        return '낮은 광도';
      case 'medium':
        return '중간 광도';
      case 'high':
        return '높은 광도';
      default:
        return key;
    }
  }

  String _getTemperatureText(String key) {
    switch (key) {
      case 'under_0':
        return '0°C 이하';
      case '5':
        return '5°C';
      case '7':
        return '7°C';
      case '10':
        return '10°C';
      case 'over_13':
        return '13°C 이상';
      default:
        return key;
    }
  }

  String _getHumidityText(String key) {
    switch (key) {
      case 'under_40':
        return '40% 미만';
      case '40_70':
        return '40~70%';
      case 'over_70':
        return '70% 이상';
      default:
        return key;
    }
  }

  String _getLocationText(String key) {
    switch (key) {
      case 'balcony_inner':
        return '발코니 내측';
      case 'balcony_window':
        return '발코니 창측';
      case 'living_inner':
        return '거실 내측';
      case 'living_window':
        return '거실 창측';
      case 'indoor_dark':
        return '실내 어두운 곳';
      case 'humid_place':
        return '습한 곳';
      case 'wide_place':
        return '넓은 곳';
      case 'narrow_place':
        return '좁은 곳';
      default:
        return key;
    }
  }

  String _getLevelText(String key) {
    switch (key) {
      case 'beginner':
        return '초보자';
      case 'experienced':
        return '경험자';
      case 'expert':
        return '전문가';
      default:
        return key;
    }
  }

  String _getCareText(String key) {
    switch (key) {
      case 'low':
        return '잘 견딤';
      case 'normal':
        return '보통';
      case 'needed':
        return '관리 필요';
      case 'special':
        return '특별 관리';
      case 'other':
        return '기타';
      default:
        return key;
    }
  }

  void _showEditModal(String category, String key) {
    List<Map<String, String>> options = _getOptionsForCategory(key);
    String? currentValue = widget.surveyData[key];
    String? tempSelectedValue = currentValue; // 임시 선택값 저장

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 핸들바
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // 헤더
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                              child: Text(
                                '취소',
                                style: TextStyle(fontFamily: 'Pretendard'),
                              ),
                            ),
                            Text(
                              '$category 변경',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  tempSelectedValue != null
                                      ? () {
                                        _updateSurveyData(
                                          key,
                                          tempSelectedValue!,
                                        );
                                        Navigator.pop(context);
                                      }
                                      : null,
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF0BB57F),
                              ),
                              child: Text(
                                '완료',
                                style: TextStyle(fontFamily: 'Pretendard'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 옵션 목록
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected =
                                tempSelectedValue == option['key'];

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    tempSelectedValue = option['key'];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Color(0xFF0BB57F)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Color(0xFF0BB57F)
                                              : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    option['value']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard',
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Color(0xFF363636),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  List<Map<String, String>> _getOptionsForCategory(String key) {
    switch (key) {
      case 'light':
        return [
          {'key': 'low', 'value': '낮은 광도'},
          {'key': 'medium', 'value': '중간 광도'},
          {'key': 'high', 'value': '높은 광도'},
        ];
      case 'temperature':
        return [
          {'key': 'under_0', 'value': '0°C 이하'},
          {'key': '5', 'value': '5°C'},
          {'key': '7', 'value': '7°C'},
          {'key': '10', 'value': '10°C'},
          {'key': 'over_13', 'value': '13°C 이상'},
        ];
      case 'humidity':
        return [
          {'key': 'under_40', 'value': '40% 미만'},
          {'key': '40_70', 'value': '40~70%'},
          {'key': 'over_70', 'value': '70% 이상'},
        ];
      case 'location':
        return [
          {'key': 'balcony_inner', 'value': '발코니 내측'},
          {'key': 'balcony_window', 'value': '발코니 창측'},
          {'key': 'living_inner', 'value': '거실 내측'},
          {'key': 'living_window', 'value': '거실 창측'},
          {'key': 'indoor_dark', 'value': '실내 어두운 곳'},
          {'key': 'humid_place', 'value': '습한 곳'},
          {'key': 'wide_place', 'value': '넓은 곳'},
          {'key': 'narrow_place', 'value': '좁은 곳'},
        ];
      case 'level':
        return [
          {'key': 'beginner', 'value': '초보자'},
          {'key': 'experienced', 'value': '경험자'},
          {'key': 'expert', 'value': '전문가'},
        ];
      case 'careRequirement':
        return [
          {'key': 'low', 'value': '잘 견딤'},
          {'key': 'normal', 'value': '보통'},
          {'key': 'needed', 'value': '관리 필요'},
          {'key': 'special', 'value': '특별 관리'},
          {'key': 'other', 'value': '기타'},
        ];
      default:
        return [];
    }
  }

  void _updateSurveyData(String key, String newValue) {
    setState(() {
      widget.surveyData[key] = newValue;
    });

    // API 다시 호출
    _loadRecommendedPlants();
  }

  Widget _buildResultContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0BB57F)),
            SizedBox(height: 16),
            Text(
              '맞춤 식물을 찾고 있어요...',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              '추천 결과를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendedPlants,
              child: Text('다시 시도', style: TextStyle(fontFamily: 'Pretendard')),
            ),
          ],
        ),
      );
    }

    if (_recommendedPlants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '조건에 맞는 식물을 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다른 조건으로 다시 시도해보세요',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _recommendedPlants.length,
      itemBuilder: (context, index) {
        return _buildPlantItem(_recommendedPlants[index]);
      },
    );
  }

  Widget _buildPlantItem(Plant plant) {
    final imageUrl = _getBestImageUrl(plant);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PlantDetailScreen(
                    cntntsNo: plant.cntntsNo,
                    imageUrl: imageUrl,
                    plantName: plant.cntntsSj,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // 식물 이미지
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child:
                    imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0BB57F),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return SvgPicture.asset(
                                'assets/image/default_plant_image.svg',
                                width: 40,
                                height: 40,
                              );
                            },
                          ),
                        )
                        : SvgPicture.asset(
                          'assets/image/default_plant_image.svg',
                          width: 40,
                          height: 40,
                        ),
              ),

              SizedBox(width: 16),

              // 식물 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.cntntsSj,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        color: Color(0xFF363636),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '추천 식물',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0BB57F),
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 추가 버튼
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFF0BB57F),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AddPlantScreen(scientificName: plant.cntntsSj),
                      ),
                    );
                  },
                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
