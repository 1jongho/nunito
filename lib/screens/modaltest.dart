// lib/screens/modaltest.dart
import 'package:flutter/material.dart';
import 'package:nunito/widgets/modal/date_picker_modal.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:intl/intl.dart';

class ModalTestScreen extends StatefulWidget {
  const ModalTestScreen({super.key});

  @override
  State<ModalTestScreen> createState() => _ModalTestScreenState();
}

class _ModalTestScreenState extends State<ModalTestScreen> {
  DateTime? _selectedDate;
  final customGreen = Color(0xFF0BB57F);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '날짜 선택 모달 테스트',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: customGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 선택된 날짜 표시
            if (_selectedDate != null)
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: customGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: customGreen),
                ),
                child: Column(
                  children: [
                    Text(
                      '선택된 날짜',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy년 MM월 dd일').format(_selectedDate!),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: customGreen,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '날짜를 선택해주세요',
                style: TextStyle(fontFamily: 'Pretendard', fontSize: 18),
              ),

            SizedBox(height: 30),

            // 날짜 선택 버튼
            ElevatedButton.icon(
              onPressed: () {
                // 날짜 선택 모달 표시
                DatePickerModal.show(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  onDateSelected: (selectedDate) {
                    setState(() {
                      _selectedDate = selectedDate;
                    });

                    // 날짜가 선택되었을 때 스낵바 표시
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${DateFormat('yyyy년 MM월 dd일').format(selectedDate)} 선택되었습니다',
                          style: TextStyle(fontFamily: 'Pretendard'),
                        ),
                        backgroundColor: customGreen,
                      ),
                    );
                  },
                  title: '날짜 선택',
                );
              },
              icon: Icon(Icons.calendar_today),
              label: Text(
                '날짜 선택하기',
                style: TextStyle(fontFamily: 'Pretendard'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: customGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            SizedBox(height: 16),

            // + 아이콘으로 날짜 선택
            ElevatedButton.icon(
              onPressed: () {
                // 날짜 선택 모달 표시
                DatePickerModal.show(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  onDateSelected: (selectedDate) {
                    setState(() {
                      _selectedDate = selectedDate;
                    });
                  },
                  title: '+ 아이콘으로 선택',
                );
              },
              icon: Icon(Icons.add),
              label: Text(
                '+ 아이콘으로 날짜 선택',
                style: TextStyle(fontFamily: 'Pretendard'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: customGreen,
                side: BorderSide(color: customGreen),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            SizedBox(height: 30),

            // 날짜 초기화 버튼
            if (_selectedDate != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                icon: Icon(Icons.refresh),
                label: Text('날짜 초기화'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(),
    );
  }
}
