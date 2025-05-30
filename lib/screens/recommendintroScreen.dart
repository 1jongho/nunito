import 'package:flutter/material.dart';
import 'dart:ui'; // BackdropFilter를 위해 필요
import 'package:nunito/screens/recommendScreen.dart';
import 'package:nunito/widgets/navbar.dart';

class PlantRecommendIntroScreen extends StatefulWidget {
  const PlantRecommendIntroScreen({super.key});

  @override
  State<PlantRecommendIntroScreen> createState() =>
      _PlantRecommendIntroScreenState();
}

class _PlantRecommendIntroScreenState extends State<PlantRecommendIntroScreen>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _leftArrowController;
  late AnimationController _rightArrowController;

  // 애니메이션들
  late Animation<Offset> _leftArrowAnimation;
  late Animation<Offset> _rightArrowAnimation;

  // 애니메이션 실행 상태를 제어하는 플래그 추가
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _leftArrowController = AnimationController(
      duration: Duration(milliseconds: 2000), // 속도를 조금 느리게
      vsync: this,
    );

    _rightArrowController = AnimationController(
      duration: Duration(milliseconds: 2000), // 속도를 조금 느리게
      vsync: this,
    );

    // 왼쪽 화살표 애니메이션 (왼쪽에서 오른쪽으로)
    _leftArrowAnimation = Tween<Offset>(
      begin: Offset(-0.3, 0),
      end: Offset(0.3, 0),
    ).animate(
      CurvedAnimation(parent: _leftArrowController, curve: Curves.easeInOut),
    );

    // 오른쪽 화살표 애니메이션 (오른쪽에서 왼쪽으로)
    _rightArrowAnimation = Tween<Offset>(
      begin: Offset(0.3, 0),
      end: Offset(-0.3, 0),
    ).animate(
      CurvedAnimation(parent: _rightArrowController, curve: Curves.easeInOut),
    );

    // 애니메이션 시작
    _startAnimations();
  }

  // 애니메이션을 반복 실행하는 함수 (화살표만)
  void _startAnimations() async {
    // 화살표 애니메이션을 계속 반복
    _startArrowAnimations();
  }

  // 화살표 애니메이션 (계속 반복) - 수정된 버전
  void _startArrowAnimations() async {
    _isAnimating = true;

    while (mounted && _isAnimating) {
      try {
        // mounted와 컨트롤러 상태를 각 단계마다 체크
        if (!mounted ||
            _leftArrowController.isAnimating ||
            _rightArrowController.isAnimating ||
            !_isAnimating)
          break;

        // 화살표들이 동시에 안으로 이동
        await Future.wait([
          _leftArrowController.forward(),
          _rightArrowController.forward(),
        ]);

        if (!mounted || !_isAnimating) break;
        await Future.delayed(Duration(milliseconds: 300));

        if (!mounted || !_isAnimating) break;

        // 화살표들이 동시에 밖으로 이동
        await Future.wait([
          _leftArrowController.reverse(),
          _rightArrowController.reverse(),
        ]);

        if (!mounted || !_isAnimating) break;
        await Future.delayed(Duration(milliseconds: 800));
      } catch (e) {
        // 애니메이션 중 에러가 발생하면 루프 종료
        print('애니메이션 에러: $e');
        break;
      }
    }
  }

  void _navigateToRecommendScreen() async {
    // 화살표 애니메이션 잠시 중지
    _isAnimating = false;

    // 짧은 딜레이
    await Future.delayed(Duration(milliseconds: 100));

    // 애니메이션 없는 즉시 전환
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => PlantRecommendScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      // 페이지에서 돌아왔을 때 애니메이션 재개
      if (mounted) {
        _isAnimating = true;
        _startArrowAnimations();
      }
    });
  }

  // 애니메이션을 안전하게 중지하는 함수
  void _stopAnimations() {
    _isAnimating = false;
  }

  @override
  void dispose() {
    _isAnimating = false;

    // 메모리 누수 방지를 위해 컨트롤러들 정리
    _leftArrowController.dispose();
    _rightArrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // 화면 전체를 터치했을 때 추천 화면으로 이동
        onTap: _navigateToRecommendScreen, // 수정된 함수 사용
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/image/recommendintro.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // 반투명 오버레이 (텍스트 가독성을 위해)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.7),
              ),

              // 메인 컨텐츠를 중앙에 배치
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 180),

                    // "나만의 식물 추천받기" 텍스트
                    _buildTitleText(),

                    SizedBox(height: 180),

                    // 화살표와 클릭 버튼이 있는 영역
                    _buildInteractionArea(),

                    SizedBox(height: 30),

                    // 안내 텍스트
                    Text(
                      '화면을 터치하여 시작하세요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 1),
    );
  }

  // 제목 텍스트를 만드는 위젯
  Widget _buildTitleText() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '나만의 식물',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '추천받기',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // 화살표와 클릭 버튼이 있는 상호작용 영역
  Widget _buildInteractionArea() {
    return Container(
      width: 280,
      height: 60,
      child: Stack(
        children: [
          // 왼쪽 화살표들
          Positioned(
            left: 0,
            top: 15,
            child: AnimatedBuilder(
              animation: _leftArrowAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: _leftArrowAnimation.value * 40, // 이동 거리 조절
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 32,
                      ),
                      Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 가운데 클릭 버튼
          Positioned(
            left: 90,
            top: 0,
            child: GestureDetector(
              onTap: _navigateToRecommendScreen, // 수정된 함수 사용
              child: Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0x90373737), // 반투명 배경
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'click',
                    style: TextStyle(
                      color: Color(0xFF0BB57F), // 앱의 메인 컬러
                      fontSize: 24,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 오른쪽 화살표들
          Positioned(
            right: 5,
            top: 15,
            child: AnimatedBuilder(
              animation: _rightArrowAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: _rightArrowAnimation.value * 40, // 이동 거리 조절
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                      Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 32,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
