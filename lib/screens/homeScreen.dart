import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/plantmyScreen.dart';
import 'package:nunito/screens/addplantsearchScreen.dart'; // 추가
import 'package:nunito/screens/settingScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                  MaterialPageRoute(builder: (context) => SettingScreen()),
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
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildPlantItem();
              },
            ),

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
                  if (_currentPage < 2) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantItem() {
    return Center(
      child: Container(
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
                  '초록이',
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
                  '골드크레스트 "윌마"',
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

  Widget _buildPageIndicator() {
    return Transform.translate(
      offset: Offset(0, -120),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlantMyScreen()),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 30,
                decoration: ShapeDecoration(
                  color: const Color(0xCCF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
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
          // 수정된 부분: AddPlantScreen 대신 AddPlantSearchScreen으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlantSearchScreen()),
          );
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
