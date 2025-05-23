import 'package:flutter/material.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantMyScreen extends StatefulWidget {
  const PlantMyScreen({super.key});

  @override
  State<PlantMyScreen> createState() => _PlantMyScreenState();
}

class _PlantMyScreenState extends State<PlantMyScreen> {
  late Future<Stream<List<Map<String, dynamic>>>> _plantsStreamFuture;

  @override
  void initState() {
    super.initState();
    _plantsStreamFuture = _initializePlantsStream();
  }

  Future<Stream<List<Map<String, dynamic>>>> _initializePlantsStream() async {
    return FirebaseService.getMyPlantsStream();
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
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Stream<List<Map<String, dynamic>>>>(
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
                  child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                padding: EdgeInsets.all(16),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return _buildPlantCard(context, plant);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildPlantCard(BuildContext context, Map<String, dynamic> plant) {
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
        timeWithPlant = '${days}일째';
      } else if (days < 365) {
        final months = (days / 30).floor();
        timeWithPlant = '${months}개월째';
      } else {
        final years = (days / 365).floor();
        final remainingMonths = ((days % 365) / 30).floor();
        timeWithPlant = '${years}년 ${remainingMonths}개월째';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // 식물 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child:
                  plant['imageUrl'] != null && plant['imageUrl'].isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          plant['imageUrl'],
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
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
                              size: 40,
                            );
                          },
                        ),
                      )
                      : Icon(Icons.spa, color: Color(0xFF0BB57F), size: 40),
            ),

            SizedBox(width: 16),

            // 식물 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 애칭
                  Text(
                    plant['nickname'] ?? '이름 없음',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 4),

                  // 학명
                  Text(
                    plant['scientificName'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 8),

                  // 함께한 시간
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF0BB57F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeWithPlant,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0BB57F),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 관리 버튼들
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    _showPlantMenu(context, plant);
                  },
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
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
                        '정보 수정',
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
                        '삭제하기',
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
