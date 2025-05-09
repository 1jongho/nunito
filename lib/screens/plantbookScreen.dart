import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/addplantScreen.dart';
import 'package:nunito/screens/plantdetailScreen.dart';
import 'package:nunito/models/plant.dart';
import 'package:nunito/services/plant_api_service.dart';

class PlantBookScreen extends StatefulWidget {
  const PlantBookScreen({super.key});

  @override
  State<PlantBookScreen> createState() => _PlantBookScreenState();
}

class _PlantBookScreenState extends State<PlantBookScreen> {
  final PlantApiService _apiService = PlantApiService();
  List<Plant> _plants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false; // 추가 데이터 로드 중 상태
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  // 페이지네이션을 위한 변수들
  int _currentPage = 1;
  final int _itemsPerPage = 20; // 한 번에 가져올 항목 수
  bool _hasMoreItems = true; // 더 불러올 항목이 있는지 여부

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
    super.dispose();
  }

  // 스크롤 이벤트 리스너
  void _scrollListener() {
    // 스크롤이 맨 아래에 도달했는지 확인
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 맨 아래에 도달했고, 더 불러올 항목이 있고, 현재 로딩 중이 아니라면 추가 로드
      if (_hasMoreItems && !_isLoadingMore) {
        _loadMorePlants();
      }
    }
  }

  // 최초 식물 목록 가져오기
  Future<void> _loadPlants({String? searchText}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1; // 페이지 초기화
      _plants = []; // 기존 목록 초기화
      _hasMoreItems = true; // 더 불러올 항목 있음으로 초기화
    });

    try {
      final plants = await _apiService.getPlantList(
        searchParam: searchText,
        pageNo: _currentPage,
        numOfRows: _itemsPerPage,
      );

      setState(() {
        _plants = plants;
        _isLoading = false;

        // 받아온 데이터가 요청한 개수보다 적으면 더 이상 데이터가 없는 것으로 판단
        if (plants.length < _itemsPerPage) {
          _hasMoreItems = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMoreItems = false;
      });
      print('식물 데이터를 가져오는 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('식물 정보를 불러오는데 실패했습니다.')));
    }
  }

  // 추가 식물 목록 가져오기
  Future<void> _loadMorePlants() async {
    if (_isLoadingMore) return; // 이미 로딩 중이면 중복 호출 방지

    setState(() {
      _isLoadingMore = true;
      _currentPage++; // 다음 페이지
    });

    try {
      final morePlants = await _apiService.getPlantList(
        searchParam: _searchText.isNotEmpty ? _searchText : null,
        pageNo: _currentPage,
        numOfRows: _itemsPerPage,
      );

      setState(() {
        // 새로운 데이터가 없으면 더 이상 데이터가 없는 것으로 표시
        if (morePlants.isEmpty) {
          _hasMoreItems = false;
        } else {
          // 기존 목록에 새 데이터 추가
          _plants.addAll(morePlants);

          // 받아온 데이터가 요청한 개수보다 적으면 더 이상 데이터가 없는 것으로 판단
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

  // 검색 함수
  void _performSearch() {
    _loadPlants(searchText: _searchText);
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

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isPad = size.width > 900;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 타이틀
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.02,
                bottom: size.height * 0.005,
              ),
              child: Text(
                '식물도감',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                  color: Color(0xff363636),
                ),
              ),
            ),

            // 검색 창
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.04,
              ),
              child: SizedBox(
                height: size.height * 0.05,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '식물명을 입력해주세요.',
                    hintStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
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
                      borderSide: BorderSide(
                        color: Color(0xFF0BB57F),
                        width: 2,
                      ),
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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '식물 정보가 없습니다.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
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
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 2),
    );
  }

  // 리스트 뷰 (API 데이터 사용)
  Widget _buildListView(BuildContext context, bool isTablet) {
    return ListView.builder(
      controller: _scrollController, // 스크롤 컨트롤러 추가
      itemCount: _plants.length + (_hasMoreItems ? 1 : 0), // 로딩 인디케이터를 위한 추가 항목
      itemBuilder: (context, index) {
        // 마지막 아이템이고 더 불러올 항목이 있는 경우 로딩 인디케이터 표시
        if (index == _plants.length && _hasMoreItems) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
            ),
          );
        }
        // 실제 식물 항목 표시
        if (index < _plants.length) {
          return _buildPlantItem(context, _plants[index], isTablet);
        }
        return null; // 도달하지 않는 케이스
      },
    );
  }

  // 그리드 뷰 (API 데이터 사용)
  Widget _buildGridView(BuildContext context, bool isTablet) {
    return GridView.builder(
      controller: _scrollController, // 스크롤 컨트롤러 추가
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _plants.length + (_hasMoreItems ? 1 : 0), // 로딩 인디케이터를 위한 추가 항목
      itemBuilder: (context, index) {
        // 마지막 아이템이고 더 불러올 항목이 있는 경우 로딩 인디케이터 표시
        if (index == _plants.length && _hasMoreItems) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
          );
        }
        // 실제 식물 항목 표시
        if (index < _plants.length) {
          return _buildPlantGridItem(context, _plants[index], isTablet);
        }
        return null; // 도달하지 않는 케이스
      },
    );
  }

  // 식물 항목 위젯 (API 데이터 사용)
  Widget _buildPlantItem(BuildContext context, Plant plant, bool isTablet) {
    final size = MediaQuery.of(context).size;
    final customGreen = Color(0xFF0BB57F);

    // 이미지 URL 추출
    final imageUrl = _getFirstImageUrl(plant.rtnThumbFileUrl);

    return InkWell(
      onTap: () {
        // 식물 상세 정보 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(cntntsNo: plant.cntntsNo),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            // 식물 이미지 (수정된 부분)
            Container(
              width: isTablet ? 60 : 48,
              height: isTablet ? 60 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.green[100],
              ),
              child:
                  imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          imageUrl, // 여기서 수정된 URL 사용
                          fit: BoxFit.cover,
                          width: isTablet ? 60 : 48,
                          height: isTablet ? 60 : 48,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: Color(0xFF0BB57F),
                                strokeWidth: 2.0,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '식물 이미지 로딩 실패 (리스트): ${plant.cntntsSj} - $imageUrl - $error',
                            );
                            return Icon(
                              Icons.spa,
                              color: Colors.green,
                              size: isTablet ? 30 : 24,
                            );
                          },
                        ),
                      )
                      : Icon(
                        Icons.spa,
                        color: Colors.green,
                        size: isTablet ? 30 : 24,
                      ),
            ),
            SizedBox(width: size.width * 0.04),
            // 식물 이름
            Expanded(
              child: Text(
                plant.cntntsSj,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            // + 아이콘 클릭 시 AddPlantScreen으로 이동
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPlantScreen()),
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
      ),
    );
  }

  // 그리드 항목 위젯 (API 데이터 사용)
  Widget _buildPlantGridItem(BuildContext context, Plant plant, bool isTablet) {
    final customGreen = Color(0xFF0BB57F);

    // 이미지 URL 추출
    final imageUrl = _getFirstImageUrl(plant.rtnThumbFileUrl);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // 식물 상세 정보 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(cntntsNo: plant.cntntsNo),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 식물 이미지 (수정된 부분)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green[100],
                ),
                child:
                    imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl, // 수정된 URL 사용
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
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
                                '식물 이미지 로딩 실패 (그리드): ${plant.cntntsSj} - $imageUrl - $error',
                              );
                              return Icon(
                                Icons.spa,
                                color: Colors.green,
                                size: 24,
                              );
                            },
                          ),
                        )
                        : Icon(Icons.spa, color: Colors.green, size: 24),
              ),
              SizedBox(width: 12),
              // 식물 이름
              Expanded(
                child: Text(
                  plant.cntntsSj,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              // + 아이콘
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPlantScreen()),
                  );
                },
                child: Icon(
                  Icons.add,
                  size: isTablet ? 24 : 20,
                  color: customGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
