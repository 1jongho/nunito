import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nunito/screens/plantmyScreen.dart';
import 'package:nunito/screens/testScreen.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/plantmyScreen.dart'; // 수정: 내 식물 화면
import 'package:nunito/screens/addplantsearchScreen.dart';
import 'package:nunito/screens/settingScreen.dart';
import 'package:nunito/services/firebase_service.dart'; // Firebase 서비스
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp 사용을 위해 추가
import 'package:nunito/screens/plantdetailmyScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  // Firebase 관련 변수들
  List<Map<String, dynamic>> _myPlants = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMyPlants();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Firebase에서 내 식물 목록 로드 (조회수 기준 상위 3개)
  Future<void> _loadMyPlants() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      List<Map<String, dynamic>> allPlants =
          await FirebaseService.getMyPlants();

      // viewCount 기준으로 정렬하고 최대 3개만 선택
      allPlants.sort((a, b) {
        try {
          int aViewCount = a['viewCount'] ?? 0;
          int bViewCount = b['viewCount'] ?? 0;

          // 조회수가 같으면 updatedAt으로 2차 정렬
          if (aViewCount == bViewCount) {
            Timestamp? aTime = a['updatedAt'] as Timestamp?;
            Timestamp? bTime = b['updatedAt'] as Timestamp?;

            aTime ??= a['createdAt'] as Timestamp?;
            bTime ??= b['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // 최신순
          }

          return bViewCount.compareTo(aViewCount); // 조회수 높은 순
        } catch (e) {
          print('정렬 중 오류: $e');
          return 0;
        }
      });

      // 최대 3개까지만 선택
      List<Map<String, dynamic>> popularPlants = allPlants.take(3).toList();

      setState(() {
        _myPlants = popularPlants;
        _isLoading = false;

        // 현재 페이지가 식물 개수를 초과하면 조정
        if (_myPlants.isNotEmpty && _currentPage >= _myPlants.length) {
          _currentPage = _myPlants.length - 1;
        }
      });
      for (int i = 0; i < popularPlants.length; i++) {
        final plant = popularPlants[i];
        final viewCount = plant['viewCount'] ?? 0;
        final updatedAt = plant['updatedAt'] as Timestamp?;
        // 사용자가 홈화면으로 이동할 시, 조회수 순위를 출력. (임시 주석 처리)
        /*print(
          '${i + 1}. ${plant['nickname']} - 조회수: $viewCount회, 업데이트: ${updatedAt?.toDate()}',
        );*/
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('❌ 홈 화면 식물 로드 실패: $e');
    }
  }

  // 새로고침
  Future<void> _refreshPlants() async {
    try {
      // 1. 조회수 리셋 체크 먼저 실행
      await FirebaseService.checkAndResetAllPlants();
      // 2. 그 다음 식물 목록 새로고침
      await _loadMyPlants();
    } catch (e) {
      print('❌ 새로고침 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPlants,
        color: Color(0xFF0BB57F),
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Column(
                  children: [
                    _buildPlantCard(),
                    _buildPlantInfo(),
                    _buildPageIndicator(),
                    _buildAddButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.only(top: 60),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/icon/nunito_logo.svg',
              width: 90,
              height: 32,
            ),
          ),
          Positioned(
            right: 30,
            child: IconButton(
              icon: Icon(
                Icons.settings_rounded,
                size: 32,
                color: Color(0xFF363636),
              ),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FirebaseTestScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 5,
          bottom: 140,
          left: 10,
          right: 10,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 로딩 중
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0BB57F)),
                    SizedBox(height: 16),
                    Text(
                      '식물 불러오는 중...',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            // 오류 발생
            else if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      '식물을 불러올 수 없습니다',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPlants,
                      child: Text(
                        '다시 시도',
                        style: TextStyle(fontFamily: 'Pretendard'),
                      ),
                    ),
                  ],
                ),
              )
            // 식물이 없는 경우
            else if (_myPlants.isEmpty)
              _buildEmptyPlantView()
            // 식물이 있는 경우 (최대 3개)
            else
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _myPlants.length,
                itemBuilder: (context, index) {
                  return _buildPlantItem(_myPlants[index]);
                },
              ),

            // 네비게이션 버튼들 (식물이 여러 개일 때만 표시, 최대 3개)
            if (!_isLoading && !_hasError && _myPlants.length > 1) ...[
              Positioned(
                left: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 40,
                    color: Color(0xFF363636),
                  ),
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              Positioned(
                right: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 40,
                    color: Color(0xFF363636),
                  ),
                  onPressed: () {
                    if (_currentPage < _myPlants.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 빈 상태 뷰
  Widget _buildEmptyPlantView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: ShapeDecoration(
              shape: OvalBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFDEDEDE)),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/image/default_plant_image.svg',
                width: 80,
                height: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 실제 식물 데이터로 식물 아이템 생성 (조회수 기록 포함)
  Widget _buildPlantItem(Map<String, dynamic> plant) {
    return GestureDetector(
      // 또는 InkWell 사용 가능
      onTap: () {
        // 식물 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailMyScreen(plant: plant),
          ),
        ).then((_) {
          // 상세 페이지에서 돌아왔을 때 홈 화면 데이터 새로고침
          _refreshPlants();
        });
      },
      child: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: ShapeDecoration(
            color: Colors.white, // 연한 배경색 추가
            shape: OvalBorder(
              side: BorderSide(width: 0.40, color: const Color(0xFFDEDEDE)),
            ),
          ),
          child: Center(
            child:
                plant['imageUrl'] != null &&
                        plant['imageUrl'].toString().isNotEmpty
                    ? ClipOval(
                      child: Image.network(
                        plant['imageUrl'].toString(),
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Color(0xFF0BB57F),
                            strokeWidth: 3,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print(
                            '홈 화면 이미지 로드 실패: ${plant['nickname']} - $error',
                          );
                          return Container(
                            padding: EdgeInsets.all(30), // SVG 주변 여백
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
                      padding: EdgeInsets.all(30), // SVG 주변 여백
                      child: SvgPicture.asset(
                        'assets/image/default_plant_image.svg',
                        width: 80,
                        height: 80,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantInfo() {
    return Transform.translate(
      offset: Offset(0, -140),
      child: SizedBox(
        width: 280,
        height: 75,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: 279,
                height: 30,
                child: Text(
                  _getDisplayName(),
                  style: TextStyle(
                    color: const Color(0xFF363636),
                    fontSize: 28,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 1,
              top: 34,
              child: SizedBox(
                width: 279,
                height: 25,
                child: Text(
                  _getDisplayScientificName(),
                  style: TextStyle(
                    color: const Color(0xFF363636),
                    fontSize: 20,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.10,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 75,
              child: Container(
                width: 280,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.80,
                      strokeAlign: BorderSide.strokeAlignCenter,
                      color: const Color(0xFFDEDEDE),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 표시할 식물 이름 가져오기
  String _getDisplayName() {
    if (_isLoading) return '로딩 중...';
    if (_hasError) return '오류 발생';
    if (_myPlants.isEmpty) return '애칭';

    final currentPlant = _myPlants[_currentPage];
    return currentPlant['nickname'] ?? '이름 없음';
  }

  // 표시할 학명 가져오기
  String _getDisplayScientificName() {
    if (_isLoading) return '';
    if (_hasError) return '다시 시도해주세요';
    if (_myPlants.isEmpty) return '학명';

    final currentPlant = _myPlants[_currentPage];
    return currentPlant['scientificName'] ?? '';
  }

  Widget _buildPageIndicator() {
    return Transform.translate(
      offset: Offset(0, -120),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlantMyScreen()),
          ).then((_) {
            // 내 식물 페이지에서 돌아왔을 때 데이터 새로고침
            _refreshPlants();
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _myPlants.isEmpty ? 120 : 80,
                height: 30,
                decoration: ShapeDecoration(
                  color: const Color(0xCCF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // 식물이 없으면 텍스트, 있으면 페이지 인디케이터 (최대 3개)
              if (_myPlants.isEmpty)
                Text(
                  '내 식물 보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF363636),
                    fontFamily: 'Pretendard',
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _myPlants.length, // 최대 3개
                    (index) => Container(
                      width: 10,
                      height: 10,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Color(0xFF0BB57F)
                                : Colors.grey.shade300,
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

  Widget _buildAddButton() {
    return Transform.translate(
      offset: Offset(0, -80),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlantSearchScreen()),
          ).then((_) {
            // 식물 추가 후 돌아왔을 때 데이터 새로고침
            _refreshPlants();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0BB57F),
          foregroundColor: Colors.white,
          minimumSize: Size(160, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          '추가하기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
