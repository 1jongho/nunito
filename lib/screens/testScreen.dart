import 'package:flutter/material.dart';
import 'package:nunito/services/firebase_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = '준비';
  List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _runBasicTest() async {
    setState(() {
      _isLoading = true;
      _status = '테스트 진행 중...';
      _logs.clear();
    });

    try {
      _addLog('🔍 기본 테스트 시작');

      // 1. 익명 인증 테스트
      _addLog('1. 익명 인증 테스트...');
      bool authResult = await FirebaseService.signInAnonymously();
      if (authResult) {
        _addLog('✅ 익명 인증 성공');
      } else {
        _addLog('❌ 익명 인증 실패');
        throw Exception('익명 인증 실패');
      }

      // 2. Firebase 연결 테스트
      _addLog('2. Firebase 연결 테스트...');
      bool connectionResult = await FirebaseService.checkFirebaseConnection();
      if (connectionResult) {
        _addLog('✅ Firebase 연결 성공');
      } else {
        _addLog('❌ Firebase 연결 실패');
        throw Exception('Firebase 연결 실패');
      }

      // 3. 인증 상태 확인
      _addLog('3. 인증 상태 확인...');
      Map<String, dynamic> authStatus = await FirebaseService.checkAuthStatus();
      if (authStatus['isAuthenticated'] == true) {
        _addLog('✅ 인증 상태 정상: ${authStatus['uid']}');
      } else {
        _addLog('❌ 인증 상태 이상: ${authStatus['error']}');
        throw Exception('인증 상태 이상');
      }

      // 4. Firestore 권한 테스트
      _addLog('4. Firestore 권한 테스트...');
      bool permissionResult = await FirebaseService.testFirestorePermissions();
      if (permissionResult) {
        _addLog('✅ Firestore 권한 정상');
      } else {
        _addLog('❌ Firestore 권한 문제');
        throw Exception('Firestore 권한 문제');
      }

      // 5. 식물 목록 조회 테스트
      _addLog('5. 식물 목록 조회 테스트...');
      List<Map<String, dynamic>> plants = await FirebaseService.getMyPlants();
      _addLog('✅ 식물 목록 조회 성공: ${plants.length}개');

      setState(() {
        _status = '모든 테스트 통과! ✅';
      });
    } catch (e) {
      _addLog('❌ 테스트 실패: $e');
      setState(() {
        _status = '테스트 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runFullDiagnostics() async {
    setState(() {
      _isLoading = true;
      _status = '전체 진단 진행 중...';
      _logs.clear();
    });

    try {
      _addLog('🏥 전체 진단 시작');

      Map<String, dynamic> diagnostics = await FirebaseService.runDiagnostics();

      diagnostics.forEach((key, value) {
        _addLog('📊 $key: $value');
      });

      setState(() {
        _status = '전체 진단 완료';
      });
    } catch (e) {
      _addLog('❌ 진단 실패: $e');
      setState(() {
        _status = '진단 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestPlant() async {
    setState(() {
      _isLoading = true;
      _status = '테스트 식물 추가 중...';
    });

    try {
      _addLog('🌱 테스트 식물 추가 시작');

      String plantId = await FirebaseService.addMyPlant(
        nickname: '테스트 식물',
        scientificName: 'Testus Plantus',
        startDate: DateTime.now(),
      );

      _addLog('✅ 테스트 식물 추가 성공: $plantId');
      setState(() {
        _status = '테스트 식물 추가 완료';
      });
    } catch (e) {
      _addLog('❌ 테스트 식물 추가 실패: $e');
      setState(() {
        _status = '테스트 식물 추가 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase 테스트', style: TextStyle(fontFamily: 'Pretendard')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 표시
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.orange[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상태',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (_isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(fontFamily: 'Pretendard'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // 테스트 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runBasicTest,
                    child: Text(
                      '기본 테스트',
                      style: TextStyle(fontFamily: 'Pretendard'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0BB57F),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runFullDiagnostics,
                    child: Text(
                      '전체 진단',
                      style: TextStyle(fontFamily: 'Pretendard'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _addTestPlant,
              child: Text(
                '테스트 식물 추가',
                style: TextStyle(fontFamily: 'Pretendard'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
              ),
            ),

            SizedBox(height: 16),

            // 로그 표시
            Text(
              '로그',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child:
                    _logs.isEmpty
                        ? Center(
                          child: Text(
                            '로그가 없습니다.\n테스트를 실행해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Courier New',
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
