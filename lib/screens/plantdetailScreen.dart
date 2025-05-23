import 'package:flutter/material.dart';
import 'package:nunito/services/plant_api_service.dart';
import 'package:nunito/models/plant.dart';
import 'package:nunito/screens/addplantScreen.dart';

bool _isSeasonGuideExpanded = false;

class PlantDetailScreen extends StatefulWidget {
  final String cntntsNo; // 식물 컨텐츠 번호
  final String? imageUrl; // 이미지 URL
  final String? plantName; // 도감에서 전달받은 한국어 식물명 추가

  const PlantDetailScreen({
    super.key,
    required this.cntntsNo,
    this.imageUrl,
    this.plantName, // 새로 추가
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final PlantApiService _apiService = PlantApiService();
  bool _isLoading = true;
  PlantDetail? _plantDetail;

  // 계절 가이드 토글 상태
  final bool _isSpringExpanded = false;
  final bool _isSummerExpanded = false;
  final bool _isAutumnExpanded = false;
  final bool _isWinterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPlantDetail();
  }

  // 첫 번째 유효한 이미지 URL만 추출하는 함수
  String _getFirstImageUrl(String imageUrls) {
    if (imageUrls.isEmpty) return '';

    // URL이 | 문자로 구분되어 있는 경우 첫 번째 URL만 사용
    if (imageUrls.contains('|')) {
      final urls = imageUrls.split('|');
      if (urls.isNotEmpty) {
        return urls[0];
      }
    }

    return imageUrls;
  }

  Future<void> _loadPlantDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await _apiService.getPlantDetail(widget.cntntsNo);
      setState(() {
        _plantDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('식물 상세 정보를 가져오는 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('식물 상세 정보를 불러오는데 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '식물도감',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
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
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
              )
              : _plantDetail == null
              ? Center(child: Text('식물 정보를 불러올 수 없습니다.'))
              : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 식물 이미지
          _buildPlantImage(),

          SizedBox(height: 10),

          // 식물 이름 및 학명
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 32,
                  color: Color(0xFF0BB57F),
                  margin: EdgeInsets.only(right: 7),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 도감에서 전달받은 한국어 식물명 표시
                      Text(
                        widget.plantName ?? '식물명 없음',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // 식물 정보
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '식물 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
          ),

          SizedBox(height: 16),

          // 4개의 정보 박스 (2x2 그리드)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 첫 번째 행: 성장 높이, 성장 넓이
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        title: '성장 높이',
                        value: _getNumericValue(
                          _plantDetail?.growthHgInfo ?? '',
                        ),
                        unit: 'cm',
                        icon: Icons.height_rounded,
                        color: Color(0xFF0BB57F),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        title: '성장 넓이',
                        value: _getNumericValue(
                          _plantDetail?.growthAraInfo ?? '',
                        ),
                        unit: 'cm',
                        icon: Icons.height_rounded,
                        color: Color(0xFF0BB57F),
                        rotateIcon: true,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // 두 번째 행: 관리 수준, 관리 요구도
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        title: '관리 수준',
                        value: _getCareLevelText(_plantDetail?.adviseInfo),
                        unit: '',
                        icon: Icons.star_rounded,
                        color: Color(0xFF0BB57F),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        title: '관리 요구도',
                        value: _getLightLevelText(
                          _plantDetail?.lighttdemanddoCodeNm,
                        ),
                        unit: '',
                        icon: Icons.check_rounded,
                        color: Color(0xFF0BB57F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // 성장 TIP
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '성장 TIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.eco_rounded, color: Color(0xFF0BB57F)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _plantDetail?.adviseInfo ?? '정보가 없습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // 사계절 가이드 라인
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 위쪽 얇은 선
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Color(0xFFDFDFDF),
                  margin: EdgeInsets.only(bottom: 16),
                ),

                // 사계절 가이드 라인 토글 헤더 (박스 제거, 화살표 위치 변경)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSeasonGuideExpanded = !_isSeasonGuideExpanded;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '사계절 가이드 라인',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(width: 8), // 글자와 화살표 사이 간격
                        Icon(
                          _isSeasonGuideExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF363636),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // 사계절 내용 (토글 상태에 따라 표시)
                if (_isSeasonGuideExpanded) ...[
                  SizedBox(height: 12),

                  _buildSeasonItem(
                    '봄',
                    _getSeasonGuide(_plantDetail, 'spring'),
                    Color(0xFF79CE5E),
                  ),
                  SizedBox(height: 8),

                  _buildSeasonItem(
                    '여름',
                    _getSeasonGuide(_plantDetail, 'summer'),
                    Color(0xFF5AE0D8),
                  ),
                  SizedBox(height: 8),

                  _buildSeasonItem(
                    '가을',
                    _getSeasonGuide(_plantDetail, 'fall'),
                    Color(0xFFD39666),
                  ),
                  SizedBox(height: 8),

                  _buildSeasonItem(
                    '겨울',
                    _getSeasonGuide(_plantDetail, 'winter'),
                    Color(0xFFC1DDF2),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 32),

          // 내 식물로 추가 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ElevatedButton(
              onPressed: () {
                // AddPlantScreen으로 식물 이름을 전달하며 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddPlantScreen(
                          scientificName: _plantDetail?.plntbneNm,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0BB57F),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '+ 내 식물로 추가',
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
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool rotateIcon = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 제목
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF363636),
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          // 값과 단위
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF363636),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // 아이콘 표시 (모든 박스에 동일하게 적용)
          rotateIcon
              ? Transform.rotate(
                angle: 1.5708,
                child: Icon(
                  icon,
                  color: Color(0xFF363636),
                  size: 30,
                  weight: 700,
                ),
              )
              : Icon(
                icon,
                color:
                    icon == Icons.star_rounded
                        ? Color(0xFFFDB022)
                        : Color(0xFF363636),
                size: 30,
                weight: icon == Icons.star_rounded ? null : 700,
              ),
        ],
      ),
    );
  }

  // 식물 이미지 위젯
  Widget _buildPlantImage() {
    // 이미지 URL 처리
    String imageUrl = '';

    // 전달받은 이미지 URL 사용 (이 부분이 중요!)
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      imageUrl = widget.imageUrl!;
    }

    return Container(
      height: 240,
      width: double.infinity,
      color: Color(0xFFF2F2F2), // 배경색 추가
      child:
          imageUrl.isNotEmpty
              ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: Color(0xFF0BB57F),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('이미지 로딩 오류: $error');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Color(0xFF363636),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            color: Color(0xFF363636),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa, size: 64, color: Color(0xFF0BB57F)),
                    SizedBox(height: 8),
                    Text(
                      '이미지가 없습니다',
                      style: TextStyle(
                        color: Color(0xFFF2F2F2),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 계절별 가이드 토글 위젯
  Widget _buildSeasonItem(String season, String guideText, Color seasonColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seasonColor,
              ),
            ),
            SizedBox(width: 8),
            Text(
              season,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
                color: Color(0xFF363636),
              ),
            ),
          ],
        ),

        SizedBox(height: 8),

        // 가이드 내용 박스
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFF2F2F2)),
          ),
          child: Text(
            guideText,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF363636),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // 숫자 값만 추출
  String _getNumericValue(String? text) {
    if (text == null || text.isEmpty) return '0';

    // 숫자만 추출
    final numericRegExp = RegExp(r'(\d+)');
    final match = numericRegExp.firstMatch(text);

    String result = match?.group(1) ?? '0';

    // 값이 너무 크면 단위 변환
    int? numValue = int.tryParse(result);
    if (numValue != null) {
      if (numValue >= 100) {
        return (numValue / 100).toStringAsFixed(1).replaceAll('.0', '');
      }
    }

    return result;
  }

  // 관리 수준 계산 (1~5)
  int _getCareLevel(String? text) {
    if (text == null || text.isEmpty) return 3;

    String lowerText = text.toLowerCase();

    if (lowerText.contains('매우 어려') || lowerText.contains('전문가')) return 5;
    if (lowerText.contains('어려') ||
        lowerText.contains('까다로') ||
        lowerText.contains('경험자'))
      return 4;
    if (lowerText.contains('보통') ||
        lowerText.contains('적절') ||
        lowerText.contains('중간'))
      return 3;
    if (lowerText.contains('쉬') ||
        lowerText.contains('용이') ||
        lowerText.contains('간단'))
      return 2;
    if (lowerText.contains('매우 쉬') || lowerText.contains('초보자')) return 1;

    return 3; // 기본값
  }

  // 관리 수준 텍스트
  String _getCareLevelText(String? text) {
    int level = _getCareLevel(text);

    switch (level) {
      case 1:
        return '매우 쉬움';
      case 2:
        return '쉬움';
      case 3:
        return '보통';
      case 4:
        return '경험자';
      case 5:
        return '전문가';
      default:
        return '보통';
    }
  }

  // 광 요구도 계산 (1~5)
  int _getLightLevel(String? text) {
    if (text == null || text.isEmpty) return 3;

    String lowerText = text.toLowerCase();

    if (lowerText.contains('직사광선') ||
        lowerText.contains('강한 빛') ||
        lowerText.contains('양지'))
      return 5;
    if (lowerText.contains('밝은') ||
        lowerText.contains('충분한 빛') ||
        lowerText.contains('많은 빛'))
      return 4;
    if (lowerText.contains('반음지') ||
        lowerText.contains('반그늘') ||
        lowerText.contains('보통'))
      return 3;
    if (lowerText.contains('간접광') ||
        lowerText.contains('적은 빛') ||
        lowerText.contains('어두운'))
      return 2;
    if (lowerText.contains('음지') ||
        lowerText.contains('그늘') ||
        lowerText.contains('매우 어두운'))
      return 1;

    return 3; // 기본값
  }

  // 광 요구도 텍스트
  String _getLightLevelText(String? text) {
    int level = _getLightLevel(text);

    switch (level) {
      case 1:
        return '낮음';
      case 2:
        return '약간 낮음';
      case 3:
        return '보통';
      case 4:
        return '약간 높음';
      case 5:
        return '높음';
      default:
        return '보통';
    }
  }

  // 계절별 관리 정보 추출
  String _getSeasonGuide(PlantDetail? plantDetail, String season) {
    Map<String, String> defaultGuides = {};

    if (plantDetail == null) {
      return defaultGuides[season] ?? '정보가 없습니다.';
    }

    // ========== API에서 계절별 물주기 정보 가져오기 ==========
    String seasonGuide = '';

    switch (season) {
      case 'spring':
        seasonGuide = plantDetail.watercycleSprngCodeNm;
        break;
      case 'summer':
        seasonGuide = plantDetail.watercycleSummerCodeNm;
        break;
      case 'fall':
        seasonGuide = plantDetail.watercycleAutumnCodeNm;
        break;
      case 'winter':
        seasonGuide = plantDetail.watercycleWinterCodeNm;
        break;
    }

    // API 데이터가 있으면 그것을 사용, 없으면 기본값 사용
    if (seasonGuide.isNotEmpty) {
      print('✅ $season 가이드 API 데이터 사용: "$seasonGuide"');
      return seasonGuide;
    } else {
      print('⚠️ $season 가이드 API 데이터 없음, 기본값 사용');
      return defaultGuides[season] ?? '정보가 없습니다.';
    }
  }

  String _convertWaterCycleCodeToText(String code) {
    switch (code) {
      case '053001':
        return '4';
      case '053002':
        return '3';
      case '053003':
        return '2';
      case '053004':
        return '1';
      default:
        return code; // 코드명이 이미 텍스트인 경우 그대로 반환
    }
  }

  String _getSeasonGuideImproved(PlantDetail? plantDetail, String season) {
    Map<String, String> defaultGuides = {
      'spring': '토양 표면이 말랐을 때 충분히 관수',
      'summer': '토양 표면이 말랐을 때 충분히 관수',
      'fall': '토양 표면이 말랐을 때 충분히 관수',
      'winter': '화분 흙 대부분이 말랐을 때 충분히 관수',
    };

    if (plantDetail == null) {
      return defaultGuides[season] ?? '정보가 없습니다.';
    }

    String seasonGuide = '';

    switch (season) {
      case 'spring':
        seasonGuide = plantDetail.watercycleSprngCodeNm;
        break;
      case 'summer':
        seasonGuide = plantDetail.watercycleSummerCodeNm;
        break;
      case 'fall':
        seasonGuide = plantDetail.watercycleAutumnCodeNm;
        break;
      case 'winter':
        seasonGuide = plantDetail.watercycleWinterCodeNm;
        break;
    }

    if (seasonGuide.isNotEmpty) {
      // 코드인지 텍스트인지 확인하고 적절히 변환
      String friendlyText = _convertWaterCycleCodeToText(seasonGuide);
      print('✅ $season 가이드 API 데이터 사용: "$friendlyText"');
      return friendlyText;
    } else {
      print('⚠️ $season 가이드 API 데이터 없음, 기본값 사용');
      return defaultGuides[season] ?? '정보가 없습니다.';
    }
  }
}
