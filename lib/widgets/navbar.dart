import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nunito/screens/homeScreen.dart';
import 'package:nunito/screens/plantbook.dart';
import 'package:nunito/screens/recommend.dart';

class CustomNavigationBar extends StatefulWidget {
  final int currentIndex;

  const CustomNavigationBar({super.key, this.currentIndex = 0});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index, BuildContext context) {
    // 현재 선택된 탭과 누른 탭이 같으면 아무것도 하지 않음
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // 페이지 전환
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Recommend(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PlantBook(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, 'assets/icon/main_T.svg', 'assets/icon/main_F.svg'),
          _buildNavItem(
            1,
            'assets/icon/recommend_T.svg',
            'assets/icon/recommend_F.svg',
          ),
          _buildNavItem(
            2,
            'assets/icon/plantbook_T.svg',
            'assets/icon/plantbook_F.svg',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String selectedIcon, String unselectedIcon) {
    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Container(
        padding: EdgeInsets.all(12),
        child: SvgPicture.asset(
          _selectedIndex == index ? selectedIcon : unselectedIcon,
          width: 32,
          height: 32,
        ),
      ),
    );
  }
}
