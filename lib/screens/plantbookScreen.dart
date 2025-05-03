import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/addplantScreen.dart';

class PlantBookScreen extends StatelessWidget {
  const PlantBookScreen({super.key});

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
            // 검색창 크기 줄이기
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.04,
              ),
              child: SizedBox(
                height: size.height * 0.05,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '식물명을 입력해주세요.',
                    hintStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, size: 20),
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
                ),
              ),
            ),

            // 식물 카테고리 목록
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

  // 리스트 뷰 (모바일 및 태블릿 세로 모드용)
  Widget _buildListView(BuildContext context, bool isTablet) {
    return ListView(
      children: [
        _buildPlantCategoryItem(context, '가울테리아', isTablet),
        _buildPlantCategoryItem(context, '개운죽', isTablet),
        _buildPlantCategoryItem(context, '골드크레스트 \'윌마\'', isTablet),
        _buildPlantCategoryItem(context, '공작야자', isTablet),
        _buildPlantCategoryItem(context, '관음죽', isTablet),
        _buildPlantCategoryItem(context, '구문초', isTablet),
        _buildPlantCategoryItem(context, '구즈마니아', isTablet),
        _buildPlantCategoryItem(context, '군자란', isTablet),
        _buildPlantCategoryItem(context, '글레코마', isTablet),
      ],
    );
  }

  // 그리드 뷰 (태블릿 가로 모드 및 더 큰 화면용)
  Widget _buildGridView(BuildContext context, bool isTablet) {
    final plantNames = [
      '가울테리아',
      '개운죽',
      '골드크레스트 \'윌마\'',
      '공작야자',
      '관음죽',
      '구문초',
      '구즈마니아',
      '군자란',
      '글레코마',
    ];

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plantNames.length,
      itemBuilder: (context, index) {
        return _buildPlantCategoryGridItem(
          context,
          plantNames[index],
          isTablet,
        );
      },
    );
  }

  // 리스트 아이템 위젯
  Widget _buildPlantCategoryItem(
    BuildContext context,
    String name,
    bool isTablet,
  ) {
    final size = MediaQuery.of(context).size;
    final customGreen = Color(0xFF0BB57F);

    return InkWell(
      onTap: () {
        // 식물 상세 정보 페이지로 이동
        // 예: Navigator.push(context, MaterialPageRoute(...));
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
            // 식물 아이콘
            Container(
              width: isTablet ? 60 : 48,
              height: isTablet ? 60 : 48,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.spa,
                color: Colors.green,
                size: isTablet ? 30 : 24,
              ),
            ),
            SizedBox(width: size.width * 0.04),
            // 식물 카테고리 이름
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            // + 아이콘 클릭 시 AddPlantScreen으로 이동하도록 수정
            InkWell(
              onTap: () {
                // 식물 추가 화면으로 이동
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

  // _buildPlantCategoryGridItem 함수도 동일하게 수정
  Widget _buildPlantCategoryGridItem(
    BuildContext context,
    String name,
    bool isTablet,
  ) {
    final customGreen = Color(0xFF0BB57F);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // 식물 상세 정보 페이지로 이동
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 식물 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.spa, color: Colors.green),
              ),
              SizedBox(width: 12),
              // 식물 카테고리 이름
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              // + 아이콘 클릭 시 AddPlantScreen으로 이동하도록 수정
              InkWell(
                onTap: () {
                  // 식물 추가 화면으로 이동
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
