import 'package:flutter/material.dart';
import 'package:nunito/models/plant.dart';
import 'package:nunito/screens/addplantScreen.dart';
import 'package:nunito/screens/plantdetailScreen.dart';
import 'package:nunito/services/plant_api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddPlantSearchScreen extends StatefulWidget {
  const AddPlantSearchScreen({super.key});

  @override
  State<AddPlantSearchScreen> createState() => _AddPlantSearchScreenState();
}

class _AddPlantSearchScreenState extends State<AddPlantSearchScreen> {
  final PlantApiService _apiService = PlantApiService();
  List<Plant> _plants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false; // 검색 실행 여부 확인용

  // 페이지네이션을 위한 변수들
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPlants();

    // 스크롤 이벤트 리스너 등록
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 스크롤 이벤트 리스너
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreItems && !_isLoadingMore) {
        _loadMorePlants();
      }
    }
  }

  // 식물 목록 가져오기
  Future<void> _loadPlants({String? searchText}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _plants = [];
      _hasMoreItems = true;
      _hasSearched = searchText != null && searchText.isNotEmpty;
    });

    try {
      final plants = await _apiService.getPlantList(
        searchParam: searchText,
        pageNo: _currentPage,
        numOfRows: _itemsPerPage,
      );

      setState(() {
        _plants = plants;

        // 검색 결과가 비어있고, 검색어가 존재하면 사용자 정의 식물 항목 추가
        if (_plants.isEmpty &&
            _hasSearched &&
            searchText != null &&
            searchText.isNotEmpty) {
          _plants = [
            Plant(
              cntntsNo: 'custom',
              cntntsSj: searchText, // 검색어를 식물 이름으로 사용
              rtnFileUrl: '',
              rtnThumbFileUrl: '',
            ),
          ];
          _hasMoreItems = false; // 더 이상 항목을 로드하지 않음
        } else if (plants.length < _itemsPerPage) {
          _hasMoreItems = false;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMoreItems = false;

        // 오류 발생 시에도 검색어가 있으면 사용자 정의 식물 항목 추가
        if (_hasSearched && searchText != null && searchText.isNotEmpty) {
          _plants = [
            Plant(
              cntntsNo: 'custom',
              cntntsSj: searchText,
              rtnFileUrl: '',
              rtnThumbFileUrl: '',
            ),
          ];
        }
      });
      print('식물 데이터를 가져오는 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('식물 정보를 불러오는데 실패했습니다.')));
    }
  }

  // 추가 식물 목록 가져오기
  Future<void> _loadMorePlants() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final morePlants = await _apiService.getPlantList(
        searchParam: _searchText.isNotEmpty ? _searchText : null,
        pageNo: _currentPage,
        numOfRows: _itemsPerPage,
      );

      setState(() {
        if (morePlants.isEmpty) {
          _hasMoreItems = false;
        } else {
          _plants.addAll(morePlants);

          if (morePlants.length < _itemsPerPage) {
            _hasMoreItems = false;
          }
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      print('추가 식물 데이터를 가져오는 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('추가 식물 정보를 불러오는데 실패했습니다.')));
    }
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp');
  }

  String _processImageUrl(String url) {
    if (url.isEmpty) return '';
    String processedUrl = url.trim();
    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }
    return processedUrl;
  }

  String _getBestImageUrl(Plant plant) {
    // 원본 이미지 URL 먼저 시도
    String originalUrl = _getFirstImageUrl(plant.rtnFileUrl);
    if (originalUrl.isNotEmpty) {
      return originalUrl;
    }
    // 원본이 없으면 썸네일 사용
    String thumbnailUrl = _getFirstImageUrl(plant.rtnThumbFileUrl);
    return thumbnailUrl;
  }

  // 검색 실행
  void _performSearch() {
    _loadPlants(searchText: _searchText);
  }

  // 이미지 URL 처리
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isPad = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '식물 추가',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Color(0xFF363636),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF363636)),
      ),
      body: Column(
        children: [
          // 검색 창
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.03,
            ),
            child: SizedBox(
              height: size.height * 0.05,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '식물명을 입력해주세요.',
                  hintStyle: TextStyle(
                    color: Colors.grey[800],
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchText = '';
                      });
                      _loadPlants();
                    },
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Color(0xFF0BB57F), width: 1),
                  ),
                  filled: true,
                  fillColor: Color(0xffF3F3F3),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                onSubmitted: (value) {
                  _performSearch();
                },
              ),
            ),
          ),

          // 로딩 중이거나 에러 발생 시 표시할 위젯
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
              ),
            )
          else if (_plants.isEmpty)
            Expanded(child: _buildEmptyResult())
          else
            // 식물 목록 (그리드 또는 리스트)
            Expanded(
              child:
                  isPad
                      ? _buildGridView(context, isTablet)
                      : _buildListView(context, isTablet),
            ),
        ],
      ),
    );
  }

  // 검색 결과가 없을 때 표시할 위젯
  Widget _buildEmptyResult() {
    // 검색을 실행한 경우
    if (_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '직접 식물을 추가하시겠습니까?',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),

            // 직접 추가 버튼
            ElevatedButton.icon(
              onPressed: () {
                // 검색어를 학명으로 사용하여 식물 추가 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AddPlantScreen(scientificName: _searchText),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text(
                '직접 추가하기',
                style: TextStyle(fontFamily: 'Pretendard'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0BB57F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 초기 상태
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '추가할 식물을 검색해보세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 리스트 뷰
  Widget _buildListView(BuildContext context, bool isTablet) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _plants.length + (_hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _plants.length && _hasMoreItems) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
            ),
          );
        }
        if (index < _plants.length) {
          return _buildPlantItem(context, _plants[index], isTablet);
        }
        return null;
      },
    );
  }

  // 그리드 뷰
  Widget _buildGridView(BuildContext context, bool isTablet) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _plants.length + (_hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _plants.length && _hasMoreItems) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
          );
        }
        if (index < _plants.length) {
          return _buildPlantGridItem(context, _plants[index], isTablet);
        }
        return null;
      },
    );
  }

  // 식물 항목 위젯
  Widget _buildPlantItem(BuildContext context, Plant plant, bool isTablet) {
    final size = MediaQuery.of(context).size;
    final customGreen = Color(0xFF0BB57F);

    final imageUrl = _getBestImageUrl(plant);
    final isCustomPlant = plant.cntntsNo == 'custom';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.015,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          // 식물 이미지
          Container(
            width: isTablet ? 60 : 48,
            height: isTablet ? 60 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child:
                isCustomPlant || imageUrl.isEmpty
                    ? SvgPicture.asset(
                      'assets/image/default_plant_image.svg', // SVG 파일 경로
                      width: 12,
                      height: 12,
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: isTablet ? 60 : 48,
                        height: isTablet ? 60 : 48,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: Color(0xFFFFFFFF),
                              strokeWidth: 2.0,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print(
                            '식물 이미지 로딩 실패: ${plant.cntntsSj} - $imageUrl - $error',
                          );
                          return Icon(
                            Icons.spa,
                            color: Colors.green,
                            size: isTablet ? 30 : 24,
                          );
                        },
                      ),
                    ),
          ),
          SizedBox(width: size.width * 0.04),

          // 식물 이름 (클릭 가능하게 수정)
          Expanded(
            child: InkWell(
              onTap: () {
                // 사용자 정의 식물이 아닌 경우에만 상세 페이지로 이동
                if (!isCustomPlant) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PlantDetailScreen(
                            cntntsNo: plant.cntntsNo,
                            imageUrl: imageUrl,
                            plantName: plant.cntntsSj, // 검색에서 보던 한국어 식물명 전달
                          ),
                    ),
                  );
                }
              },
              child: Text(
                plant.cntntsSj,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontFamily: 'Pretendard',
                  fontWeight:
                      isCustomPlant ? FontWeight.w500 : FontWeight.normal,
                  // 클릭 가능한 것을 표시하기 위해 색상 추가 (선택사항)
                  color: isCustomPlant ? Colors.black : Color(0xFF363636),
                ),
              ),
            ),
          ),

          // + 아이콘 (식물 추가용)
          InkWell(
            onTap: () {
              // 식물 추가 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AddPlantScreen(scientificName: plant.cntntsSj),
                ),
              );
            },
            child: Icon(
              Icons.add,
              size: isTablet ? 24 : 25,
              color: customGreen,
            ),
          ),
        ],
      ),
    );
  }

  // 그리드 항목 위젯
  Widget _buildPlantGridItem(BuildContext context, Plant plant, bool isTablet) {
    final customGreen = Color(0xFF0BB57F);
    final imageUrl = _getBestImageUrl(plant);
    final isCustomPlant = plant.cntntsNo == 'custom';

    return Card(
      elevation: 2,
      child: InkWell(
        // 카드 전체를 클릭하면 상세 페이지로 이동 (사용자 정의 식물 제외)
        onTap: () {
          if (!isCustomPlant) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PlantDetailScreen(
                      cntntsNo: plant.cntntsNo,
                      imageUrl: imageUrl,
                      plantName: plant.cntntsSj, // 검색에서 보던 한국어 식물명 전달
                    ),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 식물 이미지
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green[100],
                ),
                child:
                    isCustomPlant || imageUrl.isEmpty
                        ? Icon(Icons.spa, color: Colors.green, size: 24)
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            headers: {
                              'User-Agent': 'Mozilla/5.0 (compatible; Flutter)',
                            },
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
                                  strokeWidth: 2.0,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                '식물 이미지 로딩 실패: ${plant.cntntsSj} - $imageUrl - $error',
                              );
                              return Icon(
                                Icons.spa,
                                color: Colors.green,
                                size: 24,
                              );
                            },
                          ),
                        ),
              ),
              SizedBox(width: 12),

              // 식물 이름
              Expanded(
                child: Text(
                  plant.cntntsSj,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontFamily: 'Pretendard',
                    fontWeight:
                        isCustomPlant ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),

              // + 아이콘 (식물 추가용, 이벤트 버블링 방지)
              InkWell(
                onTap: () {
                  // 식물 추가 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddPlantScreen(scientificName: plant.cntntsSj),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(4), // 클릭 영역 확대
                  child: Icon(
                    Icons.add,
                    size: isTablet ? 24 : 20,
                    color: customGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
