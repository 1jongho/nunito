import 'package:flutter/material.dart';

class DatePickerModal extends StatefulWidget {
  // 초기 날짜 설정 (기본값 오늘)
  final DateTime? initialDate;

  // 날짜 선택 시 호출될 콜백
  final Function(DateTime) onDateSelected;

  // 선택 가능한 날짜 범위
  final DateTime? firstDate;
  final DateTime? lastDate;

  // 모달 제목
  final String title;

  const DatePickerModal({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.title = '날짜 선택',
  });

  // 정적 메서드로 모달 호출을 쉽게 함
  static Future<void> show({
    required BuildContext context,
    DateTime? initialDate,
    required Function(DateTime) onDateSelected,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '날짜 선택',
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DatePickerModal(
            initialDate: initialDate,
            onDateSelected: onDateSelected,
            firstDate: firstDate,
            lastDate: lastDate,
            title: title,
          ),
    );
  }

  @override
  State<DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<DatePickerModal> {
  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  // 년 목록 (기본적으로 현재 년도 기준 -10년 ~ +10년)
  late List<int> _years;

  // 현재 선택된 월에 따른 일 목록
  late List<int> _daysInMonth;

  @override
  void initState() {
    super.initState();

    // 초기 날짜 설정
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedYear = _selectedDate.year;
    _selectedMonth = _selectedDate.month;
    _selectedDay = _selectedDate.day;

    // 연도 목록 생성 (현재 연도 기준 -10년 ~ +10년)
    final currentYear = DateTime.now().year;
    _years = List.generate(21, (index) => currentYear - 10 + index);

    // 현재 선택된 월의 일 수 계산
    _updateDaysInMonth();
  }

  // 선택된 월에 따라 일 수 업데이트
  void _updateDaysInMonth() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    _daysInMonth = List.generate(daysInMonth, (index) => index + 1);

    // 만약 선택된 일이 새 월의
    if (_selectedDay > _daysInMonth.length) {
      _selectedDay = _daysInMonth.length;
    }
  }

  // 날짜 변경 시 호출될 메서드
  void _updateDate() {
    setState(() {
      _selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.4, // 화면 높이의 70%
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
                    widget.onDateSelected(_selectedDate);
                    Navigator.pop(context);
                  },
                  child: Text(
                    '선택',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      color: Color(0xFF0BB57F), // 초록색 버튼
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 피커 컨테이너
          Expanded(
            child: Row(
              children: [
                // 년 선택
                Expanded(child: _buildYearPicker()),
                // 월 선택
                Expanded(child: _buildMonthPicker()),
                // 일 선택
                Expanded(child: _buildDayPicker()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 년 선택 피커
  Widget _buildYearPicker() {
    return Container(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50, // 각 항목의 높이
        perspective: 0.005, // 3D 효과 정도
        diameterRatio: 1.2, // 휠 지름 비율
        physics: FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: _years.indexOf(_selectedYear),
        ),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedYear = _years[index];
            _updateDaysInMonth();
            _updateDate();
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _years.length,
          builder: (context, index) {
            final bool isSelected = _years[index] == _selectedYear;
            return Center(
              child: Text(
                '${_years[index]}년',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: isSelected ? 20 : 16,
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

  // 월 선택 피커
  Widget _buildMonthPicker() {
    return Container(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: _selectedMonth - 1,
        ),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedMonth = index + 1;
            _updateDaysInMonth();
            _updateDate();
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 12,
          builder: (context, index) {
            final month = index + 1;
            final bool isSelected = month == _selectedMonth;
            return Center(
              child: Text(
                '$month월',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: isSelected ? 20 : 16,
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

  // 일 선택 피커
  Widget _buildDayPicker() {
    return Container(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: _selectedDay - 1),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedDay = index + 1;
            _updateDate();
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _daysInMonth.length,
          builder: (context, index) {
            final day = index + 1;
            final bool isSelected = day == _selectedDay;
            return Center(
              child: Text(
                '$day일',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: isSelected ? 20 : 16,
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
