import 'package:flutter/material.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/screens/homeScreen.dart';
import 'package:nunito/screens/plantdetailmyScreen.dart';
import 'package:nunito/screens/bluetoothconnectionScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nunito/services/bluetooth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nunito/widgets/toast.dart';
import 'dart:async';

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

  // 블루투스 연결 화면으로 이동
  Future<void> _connectBluetooth(
    String plantId,
    String plantName,
    Map<String, dynamic> plant,
  ) async {
    // 블루투스 연결 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothConnectionScreen(plant: plant),
      ),
    );

    // 연결 성공 시 결과 처리
    if (result == true) {
      CustomFluttertoast.showToast(
        context: context,
        msg: "'$plantName' 블루투스가 연결이 완료되었습니다. ",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFF0BB57F),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // 블루투스 연결 해제 확인 모달
  void _showDisconnectConfirmDialog(String plantId, String plantName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '블루투스 연결 해제',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            '"$plantName" 와(과)의 블루투스 연결을 해제하시겠습니까?',
            style: TextStyle(fontFamily: 'Pretendard', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _disconnectBluetooth(plantId, plantName);
              },
              child: Text(
                '해제',
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 블루투스 연결 해제 (Firebase 상태 업데이트 포함)
  Future<void> _disconnectBluetooth(String plantId, String plantName) async {
    try {
      // 🔧 1. 실제 블루투스 연결 해제 먼저!
      await BluetoothServiceManager.disconnect(); // ← 이 줄 추가!

      // 🔧 2. Firebase에 블루투스 연결 해제 상태 업데이트
      await FirebaseService.updateBluetoothConnection(
        plantId: plantId,
        isConnected: false,
      );

      CustomFluttertoast.showToast(
        context: context,
        msg: "'$plantName' 와(과) 블루투스 연결이 해제되었습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      CustomFluttertoast.showToast(
        context: context,
        msg: "블루투스 연결 해제에 실패했습니다: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
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

    // Firebase에서 블루투스 연결 상태 가져오기 (기본값: false)
    final isBluetoothConnected = plant['isBluetoothConnected'] ?? false;

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

          // 블루투스 버튼 (Firebase 상태 기반)
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
                  _connectBluetooth(plantId, plant['nickname'] ?? '식물', plant);
                } else {
                  _showDisconnectConfirmDialog(
                    plantId,
                    plant['nickname'] ?? '식물',
                  );
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    SizedBox(height: 12),

                    // 메뉴 항목들 (알림 설정 제거됨)
                    ListTile(
                      leading: Icon(Icons.visibility, color: Color(0xFF0BB57F)),
                      title: Text(
                        '내 식물 확인하기',
                        style: TextStyle(fontFamily: 'Pretendard'),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlantDetailMyScreen(plant: plant),
                          ),
                        );
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
          title: Text('내 식물과 이별하기', style: TextStyle(fontFamily: 'Pretendard')),
          content: Text(
            '정말로 "${plant['nickname']}"와(과) 이별하시겠습니까?\n이별한 식물과는 다시 만날 수 없습니다.',
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
                Navigator.pop(context); // 확인 다이얼로그 먼저 닫기

                await _deletePlantWithLoading(context, plant);
              },
              child: Text(
                '이별하기',
                style: TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 새로운 삭제 함수 (Context 문제 해결)
  Future<void> _deletePlantWithLoading(
    BuildContext context,
    Map<String, dynamic> plant,
  ) async {
    // BuildContext가 유효한지 확인
    if (!mounted) return;

    // Context 참조를 미리 저장
    final BuildContext dialogContext = context;

    // 로딩 다이얼로그 표시
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder:
          (BuildContext modalContext) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0BB57F)),
                  SizedBox(height: 16),
                  Text(
                    '식물과 이별 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    bool isSuccess = false;

    try {
      print('🗑️ 식물 삭제 시작: ${plant['nickname']} (${plant['id']})');

      // 1. 이미지 삭제 (타임아웃 설정, 실패해도 계속 진행)
      if (plant['imageUrl'] != null &&
          plant['imageUrl'].toString().isNotEmpty) {
        try {
          print('📸 이미지 삭제 시도: ${plant['imageUrl']}');
          await FirebaseService.deleteImage(
            plant['imageUrl'],
          ).timeout(Duration(seconds: 10));
          print('✅ 이미지 삭제 성공');
        } catch (e) {
          print('⚠️ 이미지 삭제 실패 (무시하고 계속): $e');
        }
      }

      // 2. Firestore 문서 삭제 (타임아웃 설정)
      print('📄 Firestore 문서 삭제 시도');
      await FirebaseService.deleteMyPlant(
        plant['id'],
      ).timeout(Duration(seconds: 15));
      print('✅ 식물 삭제 완료');

      isSuccess = true;
    } catch (e) {
      print('❌ 식물 삭제 실패: $e');
      isSuccess = false;
    }

    // 🔥 모달 닫기 (여러 방법 시도)
    print('🔄 모달 닫기 시도...');

    // 방법 1: Navigator의 가장 상위 라우트 제거
    try {
      if (Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
        print('✅ 방법1: rootNavigator로 모달 닫기 성공');
      } else {
        print('⚠️ 방법1: canPop이 false');
      }
    } catch (e1) {
      print('⚠️ 방법1 실패: $e1');

      // 방법 2: 일반 Navigator 사용
      try {
        Navigator.of(dialogContext).pop();
        print('✅ 방법2: 일반 Navigator로 모달 닫기 성공');
      } catch (e2) {
        print('⚠️ 방법2 실패: $e2');

        // 방법 3: 컨텍스트를 다시 찾아서 시도
        try {
          if (mounted && this.context.mounted) {
            Navigator.of(this.context, rootNavigator: true).pop();
            print('✅ 방법3: this.context로 모달 닫기 성공');
          }
        } catch (e3) {
          print('❌ 모든 방법 실패: $e3');
        }
      }
    }

    // 잠시 대기 후 메시지 표시
    await Future.delayed(Duration(milliseconds: 300));

    // 결과 메시지 표시 (this.context 사용)
    if (mounted && this.context.mounted) {
      if (isSuccess) {
        CustomFluttertoast.showToast(
          context: context,
          msg: "${plant['nickname']}와(과) 이별하였습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFF0BB57F),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        CustomFluttertoast.showToast(
          context: context,
          msg: "이별 중 오류가 발생했습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }
}

// 3개 점 애니메이션 위젯
class _ThreeDotsAnimation extends StatefulWidget {
  @override
  __ThreeDotsAnimationState createState() => __ThreeDotsAnimationState();
}

class __ThreeDotsAnimationState extends State<_ThreeDotsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 0, end: -10).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeInOut),
              ),
            )
            .toList();

    _startAnimations();
  }

  void _startAnimations() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (mounted) {
          _controllers[i].forward().then((_) {
            if (mounted) _controllers[i].reverse();
          });
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
      await Future.delayed(Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF0BB57F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
