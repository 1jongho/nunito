import 'package:flutter/material.dart';

class AlarmSettingModal extends StatefulWidget {
  final String title;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String unit;
  final Function(int selectedValue) onValueSelected;

  const AlarmSettingModal({
    super.key,
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.unit,
    required this.onValueSelected,
  });

  // 정적 메서드로 모달 호출을 쉽게 함
  static Future<void> show({
    required BuildContext context,
    required String title,
    required int minValue,
    required int maxValue,
    required int initialValue,
    required String unit,
    required Function(int selectedValue) onValueSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AlarmSettingModal(
            title: title,
            minValue: minValue,
            maxValue: maxValue,
            initialValue: initialValue,
            unit: unit,
            onValueSelected: onValueSelected,
          ),
    );
  }

  @override
  State<AlarmSettingModal> createState() => _AlarmSettingModalState();
}

class _AlarmSettingModalState extends State<AlarmSettingModal> {
  late int _selectedValue;
  late List<int> _valueRange;

  @override
  void initState() {
    super.initState();

    _selectedValue = widget.initialValue;

    // 값 범위 생성 (관리자가 설정한 최소값~최대값)
    _valueRange = List.generate(
      widget.maxValue - widget.minValue + 1,
      (index) => widget.minValue + index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 모달 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 취소 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.grey,
                    ),
                  ),
                ),
                // 모달 제목
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 확인 버튼
                TextButton(
                  onPressed: () {
                    widget.onValueSelected(_selectedValue);
                    Navigator.pop(context);
                  },
                  child: Text(
                    '선택',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      color: Color(0xFF0BB57F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 설명 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${widget.minValue}${widget.unit} ~ ${widget.maxValue}${widget.unit} 범위에서 선택해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 피커 컨테이너
          Expanded(child: _buildValuePicker()),
        ],
      ),
    );
  }

  // 값 선택 피커
  Widget _buildValuePicker() {
    return Container(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: _valueRange.indexOf(_selectedValue),
        ),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedValue = _valueRange[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _valueRange.length,
          builder: (context, index) {
            final value = _valueRange[index];
            final bool isSelected = value == _selectedValue;
            return Center(
              child: Text(
                '$value${widget.unit}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: isSelected ? 24 : 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Color(0xFF0BB57F) : Colors.black,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
