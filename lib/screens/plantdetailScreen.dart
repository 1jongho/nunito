import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/services/plant_api_service.dart';
import 'package:nunito/models/plant.dart';
import 'package:nunito/screens/addplantScreen.dart';

class PlantDetailScreen extends StatefulWidget {
  final String cntntsNo; // 식물 컨텐츠 번호
  final String? imageUrl; // 이미지 URL

  const PlantDetailScreen({super.key, required this.cntntsNo, this.imageUrl});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final PlantApiService _apiService = PlantApiService();
  bool _isLoading = true;
  PlantDetail? _plantDetail;

  // 계절 가이드 토글 상태
  bool _isSpringExpanded = false;
  bool _isSummerExpanded = false;
  bool _isAutumnExpanded = false;
  bool _isWinterExpanded = false;

  @override
  void initState() {
    super.initState();
    // 디버깅을 위한 로그 추가
    print("전달받은 이미지 URL: ${widget.imageUrl}");
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
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20),
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

          // 식물 이름 및 학명
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  color: Color(0xFF0BB57F),
                  margin: EdgeInsets.only(right: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plantDetail?.cntntsSj ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _plantDetail?.plntbneNm ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
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

          // 성장 정보 (높이/넓이)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // 성장 높이
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '성장 높이',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getNumericValue(
                                _plantDetail?.growthHgInfo ?? '',
                              ),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0BB57F),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            Icon(Icons.arrow_upward, color: Colors.grey[600]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // 성장 넓이
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '성장 넓이',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getNumericValue(
                                _plantDetail?.growthAraInfo ?? '',
                              ),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0BB57F),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            Icon(Icons.swap_horiz, color: Colors.grey[600]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 관리 수준
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _buildCareLevel(
              '관리 수준',
              _getCareLevel(_plantDetail?.adviseInfo),
              _getCareLevelText(_plantDetail?.adviseInfo),
            ),
          ),

          SizedBox(height: 16),

          // 관리 요구도
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _buildCareLevel(
              '관리 요구도',
              _getLightLevel(_plantDetail?.lighttdemanddoCodeNm),
              _getLightLevelText(_plantDetail?.lighttdemanddoCodeNm),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.eco, color: Color(0xFF0BB57F)),
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
                Text(
                  '사계절 가이드 라인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                ),

                SizedBox(height: 12),

                // 봄
                _buildSeasonToggle(
                  '봄',
                  _isSpringExpanded,
                  _getSeasonGuide(_plantDetail, 'spring'),
                  Color(0xFF8BC34A),
                  () {
                    setState(() {
                      _isSpringExpanded = !_isSpringExpanded;
                    });
                  },
                ),

                SizedBox(height: 8),

                // 여름
                _buildSeasonToggle(
                  '여름',
                  _isSummerExpanded,
                  _getSeasonGuide(_plantDetail, 'summer'),
                  Color(0xFFFF9800),
                  () {
                    setState(() {
                      _isSummerExpanded = !_isSummerExpanded;
                    });
                  },
                ),

                SizedBox(height: 8),

                // 가을
                _buildSeasonToggle(
                  '가을',
                  _isAutumnExpanded,
                  _getSeasonGuide(_plantDetail, 'fall'),
                  Color(0xFFFF5722),
                  () {
                    setState(() {
                      _isAutumnExpanded = !_isAutumnExpanded;
                    });
                  },
                ),

                SizedBox(height: 8),

                // 겨울
                _buildSeasonToggle(
                  '겨울',
                  _isWinterExpanded,
                  _getSeasonGuide(_plantDetail, 'winter'),
                  Color(0xFF2196F3),
                  () {
                    setState(() {
                      _isWinterExpanded = !_isWinterExpanded;
                    });
                  },
                ),
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
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
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

  // 식물 이미지 위젯
  Widget _buildPlantImage() {
    // 이미지 URL 처리
    String imageUrl = '';

    // 전달받은 이미지 URL 사용 (이 부분이 중요!)
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      imageUrl = widget.imageUrl!;
      print("사용할 이미지 URL: $imageUrl"); // 디버깅 로그
    }

    return Container(
      height: 240,
      width: double.infinity,
      color: Colors.grey[200], // 배경색 추가
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
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            color: Colors.grey[600],
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
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 관리 수준 위젯
  Widget _buildCareLevel(String title, int level, String levelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              levelText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0BB57F),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < level ? Color(0xFF0BB57F) : Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 계절별 가이드 토글 위젯
  Widget _buildSeasonToggle(
    String season,
    bool isExpanded,
    String guideText,
    Color seasonColor,
    VoidCallback onToggle,
  ) {
    return Column(
      children: [
        // 토글 헤더
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
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
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // 토글 내용
        if (isExpanded)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              guideText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontFamily: 'Pretendard',
              ),
            ),
          ),
      ],
    );
  }

  // 숫자 값만 추출 (예: '100~150cm' -> '100')
  String _getNumericValue(String? text) {
    if (text == null || text.isEmpty) return '0';

    // 숫자만 추출
    final numericRegExp = RegExp(r'(\d+)');
    final match = numericRegExp.firstMatch(text);

    return match?.group(1) ?? '0';
  }

  // 관리 수준 계산 (1~5)
  int _getCareLevel(String? text) {
    if (text == null || text.isEmpty) return 3;

    if (text.contains('까다로') || text.contains('어려')) return 5;
    if (text.contains('관리') && text.contains('필요')) return 4;
    if (text.contains('보통') || text.contains('적절')) return 3;
    if (text.contains('쉽') || text.contains('용이')) return 2;
    if (text.contains('매우 쉽') || text.contains('간단')) return 1;

    return 3;
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

    if (text.contains('직사광선') || text.contains('양지')) return 5;
    if (text.contains('밝은') || text.contains('충분한 빛')) return 4;
    if (text.contains('반음지') || text.contains('반그늘')) return 3;
    if (text.contains('간접광') || text.contains('적은 빛')) return 2;
    if (text.contains('음지') || text.contains('그늘')) return 1;

    return 3;
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
    // 기본 계절별 정보 (API 데이터가 없는 경우 기본값)
    Map<String, String> defaultGuides = {
      'spring': '토양 표면이 말랐을 때 충분히 관수',
      'summer': '토양 표면이 말랐을 때 충분히 관수',
      'fall': '토양 표면이 말랐을 때 충분히 관수',
      'winter': '화분 흙 대부분이 말랐을 때 충분히 관수',
    };

    if (plantDetail == null) {
      return defaultGuides[season] ?? '정보가 없습니다.';
    }

    // 겨울철 물주기 정보가 있으면 겨울 가이드에 추가
    if (season == 'winter' && plantDetail.waterCycleInfo.isNotEmpty) {
      return plantDetail.waterCycleInfo;
    }

    // 봄철 물주기 정보가 있으면 봄 가이드에 추가
    if (season == 'spring' && plantDetail.watercycleSprngCodeNm.isNotEmpty) {
      return plantDetail.watercycleSprngCodeNm;
    }

    // API 데이터에서 조언 정보가 있으면 활용
    if (plantDetail.adviseInfo.isNotEmpty) {
      // 계절 관련 키워드 검색
      if (season == 'spring' && plantDetail.adviseInfo.contains('봄')) {
        // 봄 관련 문장 추출 로직
        return defaultGuides[season] ?? '정보가 없습니다.';
      } else if (season == 'summer' && plantDetail.adviseInfo.contains('여름')) {
        // 여름 관련 문장 추출 로직
        return defaultGuides[season] ?? '정보가 없습니다.';
      } else if (season == 'fall' && plantDetail.adviseInfo.contains('가을')) {
        // 가을 관련 문장 추출 로직
        return defaultGuides[season] ?? '정보가 없습니다.';
      } else if (season == 'winter' && plantDetail.adviseInfo.contains('겨울')) {
        // 겨울 관련 문장 추출 로직
        return defaultGuides[season] ?? '정보가 없습니다.';
      }
    }

    // 계절별 정보가 없으면 기본값 반환
    return defaultGuides[season] ?? '정보가 없습니다.';
  }
}
