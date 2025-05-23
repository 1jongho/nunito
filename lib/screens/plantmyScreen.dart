import 'package:flutter/material.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/homeScreen.dart'; // HomeScreen import 추가
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantMyScreen extends StatefulWidget {
  const PlantMyScreen({super.key});

  @override
  State<PlantMyScreen> createState() => _PlantMyScreenState();
}

class _PlantMyScreenState extends State<PlantMyScreen> {
  late Future<Stream<List<Map<String, dynamic>>>> _plantsStreamFuture;
  final Map<String, bool> _bluetoothStates = {}; // 각 식물별 블루투스 연결 상태

  @override
  void initState() {
    super.initState();
    _plantsStreamFuture = _initializePlantsStream();
  }

  Future<Stream<List<Map<String, dynamic>>>> _initializePlantsStream() async {
    return FirebaseService.getMyPlantsStream();
  }

  // 블루투스 연결 해제
  void _disconnectBluetooth(String plantId, String plantName) {
    setState(() {
      _bluetoothStates[plantId] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$plantName와 블루투스 연결이 해제되었습니다.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _connectBluetooth(String plantId, String plantName) async {
    // 연결 중 모달 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF0BB57F),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  '블루투스 연결 중...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '"$plantName" 와/과 연결을 시도하고 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // 5초 후 연결 완료
    await Future.delayed(Duration(seconds: 5));

    // 모달 닫기
    Navigator.of(context).pop();

    // 블루투스 상태 업데이트
    setState(() {
      _bluetoothStates[plantId] = true;
    });

    // 연결 완료 스낵바
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$plantName와 블루투스 연결이 완료되었습니다.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        backgroundColor: Color(0xFF0BB57F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          '내 식물',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Color(0xFF363636),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF363636),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () {
            // HomeScreen으로 이동 (기존 스택 모두 제거)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '식물명을 입력해주세요.',
                  hintStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // 식물 목록
          Expanded(
            child: FutureBuilder<Stream<List<Map<String, dynamic>>>>(
              future: _plantsStreamFuture,
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
                  );
                }

                if (streamSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          '오류가 발생했습니다',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${streamSnapshot.error}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _plantsStreamFuture = _initializePlantsStream();
                            });
                          },
                          child: Text(
                            '다시 시도',
                            style: TextStyle(fontFamily: 'Pretendard'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: streamSnapshot.data,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0BB57F),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '데이터 로드 오류',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontFamily: 'Pretendard',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final plants = snapshot.data ?? [];

                    if (plants.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              '등록된 식물이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '첫 번째 식물을 추가해보세요!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return _buildPlantItem(context, plant);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildPlantItem(BuildContext context, Map<String, dynamic> plant) {
    final plantId = plant['id'] ?? '';
    final isBluetoothConnected = _bluetoothStates[plantId] ?? false;

    // Timestamp를 DateTime으로 변환
    DateTime? startDate;
    if (plant['startDate'] is Timestamp) {
      startDate = (plant['startDate'] as Timestamp).toDate();
    }

    // 함께한 시간 계산
    String timeWithPlant = '';
    if (startDate != null) {
      final difference = DateTime.now().difference(startDate);
      final days = difference.inDays;

      if (days == 0) {
        timeWithPlant = '오늘 시작';
      } else if (days < 30) {
        timeWithPlant = '$days일째';
      } else if (days < 365) {
        final months = (days / 30).floor();
        timeWithPlant = '$months개월째';
      } else {
        final years = (days / 365).floor();
        final remainingMonths = ((days % 365) / 30).floor();
        timeWithPlant = '$years년 $remainingMonths개월째';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 식물 이미지와 정보 (클릭 가능)
          Expanded(
            child: InkWell(
              onTap: () {
                _showPlantMenu(context, plant);
              },
              child: Row(
                children: [
                  // 식물 이미지
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child:
                        plant['imageUrl'] != null &&
                                plant['imageUrl'].toString().isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                plant['imageUrl'].toString(),
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: Color(0xFF0BB57F),
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.spa,
                                    color: Color(0xFF0BB57F),
                                    size: 30,
                                  );
                                },
                              ),
                            )
                            : Icon(
                              Icons.spa,
                              color: Color(0xFF0BB57F),
                              size: 30,
                            ),
                  ),

                  SizedBox(width: 12),

                  // 식물 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 애칭
                        Text(
                          plant['nickname'] ?? '이름 없음',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                            color: Color(0xFF363636),
                          ),
                        ),
                        SizedBox(height: 4),

                        // 학명
                        Text(
                          plant['scientificName'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0BB57F),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 블루투스 버튼 (연결/해제 토글)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isBluetoothConnected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
            ),
            child: IconButton(
              onPressed: () {
                if (!isBluetoothConnected) {
                  _connectBluetooth(plantId, plant['nickname'] ?? '식물');
                } else {
                  _disconnectBluetooth(plantId, plant['nickname'] ?? '식물');
                }
              },
              icon: Icon(
                isBluetoothConnected
                    ? Icons.bluetooth
                    : Icons.bluetooth_disabled,
                color: isBluetoothConnected ? Colors.blue : Colors.grey,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlantMenu(BuildContext context, Map<String, dynamic> plant) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 식물 정보
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      plant['nickname'] ?? '이름 없음',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 16),

                    // 메뉴 항목들
                    ListTile(
                      leading: Icon(Icons.edit, color: Color(0xFF0BB57F)),
                      title: Text(
                        '내 식물 확인하기',
                        style: TextStyle(fontFamily: 'Pretendard'),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: 식물 정보 수정 화면으로 이동
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.notifications, color: Colors.orange),
                      title: Text(
                        '알림 설정',
                        style: TextStyle(fontFamily: 'Pretendard'),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: 알림 설정 화면으로 이동
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        '내 식물과 이별하기',
                        style: TextStyle(fontFamily: 'Pretendard'),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmDialog(context, plant);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    Map<String, dynamic> plant,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('식물 삭제', style: TextStyle(fontFamily: 'Pretendard')),
          content: Text(
            '정말로 "${plant['nickname']}"을(를) 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard'),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // 로딩 다이얼로그 표시
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0BB57F),
                        ),
                      ),
                );

                try {
                  // 이미지가 있다면 Storage에서도 삭제
                  if (plant['imageUrl'] != null &&
                      plant['imageUrl'].isNotEmpty) {
                    await FirebaseService.deleteImage(plant['imageUrl']);
                  }

                  // Firestore에서 식물 정보 삭제
                  await FirebaseService.deleteMyPlant(plant['id']);

                  // 로딩 다이얼로그 닫기
                  Navigator.pop(context);

                  // 성공 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('식물이 삭제되었습니다.'),
                      backgroundColor: Color(0xFF0BB57F),
                    ),
                  );
                } catch (e) {
                  // 로딩 다이얼로그 닫기
                  Navigator.pop(context);

                  // 오류 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 중 오류가 발생했습니다: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                '삭제',
                style: TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
              ),
            ),
          ],
        );
      },
    );
  }
}
