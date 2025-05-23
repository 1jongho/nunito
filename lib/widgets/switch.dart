import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final double width;
  final double height;
  final Duration animationDuration;
  final Widget? activeIcon;
  final Widget? inactiveIcon;

  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF0BB57F),
    this.inactiveColor = const Color(0xFFFFFFFF),
    this.activeTrackColor = const Color(0xFFE0F7F0),
    this.inactiveTrackColor = const Color(0xFFE0E0E0),
    this.width = 50.0,
    this.height = 30.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.activeIcon,
    this.inactiveIcon,
  }) : super(key: key);

  @override
  _CustomSwitchState createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.value) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 썸의 크기와 여백을 고정값으로 설정
    final double thumbSize = widget.height - 4; // 썸 크기 고정
    final double padding = 2.0; // 패딩 고정
    final double maxOffset =
        widget.width - thumbSize - (padding * 2); // 최대 이동 거리

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // CustomSwitch만 터치 효과 복원
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.height / 2),
        onTap: () {
          if (widget.onChanged != null) {
            widget.onChanged!(!widget.value);
          }
        },
        child: Container(
          // 고정된 크기 설정
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            // boxShadow 제거됨
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: widget.width, // 명시적으로 크기 고정
                height: widget.height, // 명시적으로 크기 고정
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  color: Color.lerp(
                    widget.inactiveTrackColor,
                    widget.activeTrackColor,
                    _animation.value,
                  ),
                ),
                child: Stack(
                  children: [
                    // 썸 (동그라미 부분) - Positioned 사용으로 정확한 위치 제어
                    Positioned(
                      left: padding + (_animation.value * maxOffset),
                      top: padding,
                      child: Container(
                        width: thumbSize, // 고정된 썸 크기
                        height: thumbSize, // 고정된 썸 크기
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            widget.inactiveColor,
                            widget.activeColor,
                            _animation.value,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        // 아이콘 센터 정렬
                        child: Center(
                          child:
                              widget.value
                                  ? widget.activeIcon
                                  : widget.inactiveIcon,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
