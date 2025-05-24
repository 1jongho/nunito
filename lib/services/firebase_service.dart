import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ========== 디버깅 및 상태 확인 ==========

  /// Firebase 연결 상태 확인
  static Future<bool> checkFirebaseConnection() async {
    try {
      print('🔍 Firebase 연결 상태 확인 중...');

      // Firestore 연결 테스트
      await _firestore.runTransaction((transaction) async {
        // 더미 트랜잭션으로 연결 테스트
        return true;
      });

      print('✅ Firebase 연결 정상');
      return true;
    } catch (e) {
      print('❌ Firebase 연결 실패: $e');
      return false;
    }
  }

  /// 인증 상태 상세 확인
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      print('🔍 인증 상태 확인 중...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않음');
        return {'isAuthenticated': false, 'error': '사용자가 로그인되지 않음'};
      }

      print('✅ 사용자 인증 상태:');
      print('  - UID: ${user.uid}');
      print('  - 익명: ${user.isAnonymous}');
      print('  - 생성일: ${user.metadata.creationTime}');
      print('  - 마지막 로그인: ${user.metadata.lastSignInTime}');

      return {
        'isAuthenticated': true,
        'uid': user.uid,
        'isAnonymous': user.isAnonymous,
        'creationTime': user.metadata.creationTime,
        'lastSignInTime': user.metadata.lastSignInTime,
      };
    } catch (e) {
      print('❌ 인증 상태 확인 실패: $e');
      return {'isAuthenticated': false, 'error': e.toString()};
    }
  }

  /// 익명 로그인 (강화된 오류 처리)
  static Future<bool> signInAnonymously() async {
    try {
      print('🔍 익명 로그인 시작...');

      if (_auth.currentUser != null) {
        print('✅ 기존 사용자 세션 발견: ${_auth.currentUser?.uid}');
        return true;
      }

      print('🔄 새로운 익명 사용자 생성 중...');
      UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        print('✅ 익명 로그인 성공: ${userCredential.user?.uid}');
        return true;
      } else {
        print('❌ 익명 로그인 실패: 사용자 객체가 null');
        return false;
      }
    } catch (e) {
      print('❌ 익명 로그인 중 오류 발생: $e');
      print('오류 유형: ${e.runtimeType}');

      // 구체적인 오류 메시지
      if (e is FirebaseAuthException) {
        print('Firebase Auth 오류 코드: ${e.code}');
        print('Firebase Auth 오류 메시지: ${e.message}');
      }

      return false;
    }
  }

  /// Firestore 권한 테스트
  static Future<bool> testFirestorePermissions() async {
    try {
      print('🔍 Firestore 권한 테스트 중...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 권한 테스트 실패: 사용자가 로그인되지 않음');
        return false;
      }

      // 테스트 문서 생성 시도
      DocumentReference testDoc =
          _firestore.collection('permission_test').doc();
      await testDoc.set({
        'userId': user.uid,
        'testTime': FieldValue.serverTimestamp(),
      });

      print('✅ 문서 생성 권한 정상');

      // 테스트 문서 읽기 시도
      DocumentSnapshot snapshot = await testDoc.get();
      if (snapshot.exists) {
        print('✅ 문서 읽기 권한 정상');
      }

      // 테스트 문서 삭제
      await testDoc.delete();
      print('✅ 문서 삭제 권한 정상');

      return true;
    } catch (e) {
      print('❌ Firestore 권한 테스트 실패: $e');

      if (e is FirebaseException) {
        print('Firebase 오류 코드: ${e.code}');
        print('Firebase 오류 메시지: ${e.message}');
      }

      return false;
    }
  }

  /// 내 식물 목록 조회 (강화된 디버깅)
  static Future<List<Map<String, dynamic>>> getMyPlants() async {
    try {
      print('🔍 내 식물 목록 조회 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않음');
        throw Exception('로그인이 필요합니다. 앱을 재시작해주세요.');
      }

      print('✅ 사용자 확인: ${user.uid}');

      // orderBy 없이 쿼리 (인덱스 불필요)
      print('🔄 Firestore 쿼리 실행 중 (orderBy 제거)...');
      QuerySnapshot snapshot =
          await _firestore
              .collection('my_plants')
              .where('userId', isEqualTo: user.uid)
              .get(); // orderBy 제거

      print('✅ 쿼리 실행 완료');
      print('📊 조회된 문서 수: ${snapshot.docs.length}');

      // 데이터 변환 후 앱에서 정렬
      List<Map<String, dynamic>> plants = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          plants.add(data);
          print('✅ 문서 변환 완료: ${doc.id}');
        } catch (e) {
          print('❌ 문서 변환 실패 (${doc.id}): $e');
        }
      }

      // 앱에서 수동 정렬 (createdAt 기준 내림차순)
      plants.sort((a, b) {
        try {
          Timestamp? aTime = a['createdAt'] as Timestamp?;
          Timestamp? bTime = b['createdAt'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime); // 내림차순
        } catch (e) {
          print('정렬 중 오류: $e');
          return 0;
        }
      });

      print('✅ 최종 반환 데이터 수: ${plants.length}');
      return plants;
    } catch (e) {
      print('❌ 식물 목록 조회 중 오류 발생: $e');
      print('오류 스택: ${StackTrace.current}');

      if (e is FirebaseException) {
        print('Firebase 오류 코드: ${e.code}');
        print('Firebase 오류 메시지: ${e.message}');

        switch (e.code) {
          case 'permission-denied':
            throw Exception('데이터 접근 권한이 없습니다. Firebase 보안 규칙을 확인해주세요.');
          case 'unavailable':
            throw Exception('Firebase 서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.');
          case 'unauthenticated':
            throw Exception('인증이 필요합니다. 앱을 재시작해주세요.');
          case 'failed-precondition':
            throw Exception('데이터베이스 인덱스를 생성 중입니다. 잠시 후 다시 시도해주세요.');
          default:
            throw Exception('데이터를 불러오는 중 오류가 발생했습니다: ${e.message}');
        }
      }

      throw Exception('식물 목록을 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 실시간 스트림 (강화된 오류 처리)
  static Stream<List<Map<String, dynamic>>> getMyPlantsStream() async* {
    try {
      print('🔍 실시간 스트림 생성 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 스트림 생성 실패: 사용자가 로그인되지 않음');
        throw Exception('로그인이 필요합니다.');
      }

      print('✅ 스트림 사용자 확인: ${user.uid}');

      yield* _firestore
          .collection('my_plants')
          .where('userId', isEqualTo: user.uid)
          // .orderBy('createdAt', descending: true) // 임시로 제거
          .snapshots()
          .map((snapshot) {
            print('📊 스트림 업데이트: ${snapshot.docs.length}개 문서');

            List<Map<String, dynamic>> plants =
                snapshot.docs.map((doc) {
                  Map<String, dynamic> data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }).toList();

            // 앱에서 수동 정렬
            plants.sort((a, b) {
              try {
                Timestamp? aTime = a['createdAt'] as Timestamp?;
                Timestamp? bTime = b['createdAt'] as Timestamp?;

                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;

                return bTime.compareTo(aTime); // 내림차순
              } catch (e) {
                return 0;
              }
            });

            return plants;
          })
          .handleError((error) {
            print('❌ 스트림 오류: $error');

            if (error is FirebaseException) {
              print('Firebase 스트림 오류 코드: ${error.code}');
              print('Firebase 스트림 오류 메시지: ${error.message}');
            }

            throw error;
          });
    } catch (e) {
      print('❌ 스트림 생성 중 오류 발생: $e');
      yield [];
    }
  }

  /// 전체 시스템 진단
  static Future<Map<String, dynamic>> runDiagnostics() async {
    print('\n🏥 Firebase 시스템 진단 시작...\n');

    Map<String, dynamic> diagnostics = {};

    // 1. Firebase 연결 상태
    diagnostics['firebase_connection'] = await checkFirebaseConnection();

    // 2. 인증 상태
    diagnostics['auth_status'] = await checkAuthStatus();

    // 3. Firestore 권한
    diagnostics['firestore_permissions'] = await testFirestorePermissions();

    // 4. 기기 정보
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        diagnostics['device_info'] = {
          'platform': 'Android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        diagnostics['device_info'] = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      diagnostics['device_info'] = {'error': e.toString()};
    }

    print('\n📋 진단 결과:');
    diagnostics.forEach((key, value) {
      print('  $key: $value');
    });
    print('\n');

    return diagnostics;
  }

  static DateTime _getNextSunday() {
    DateTime now = DateTime.now();
    int daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0) daysUntilSunday = 7; // 오늘이 일요일이면 다음 주
    return DateTime(now.year, now.month, now.day + daysUntilSunday);
  }

  static Future<String> addMyPlant({
    required String nickname,
    required String scientificName,
    required DateTime startDate,
    String? imageUrl,
    Map<String, dynamic>? alarmSettings,
  }) async {
    try {
      print('🔍 식물 추가 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      print('✅ 사용자 확인: ${user.uid}');
      print('📝 식물 정보: $nickname ($scientificName)');

      DocumentReference docRef = await _firestore.collection('my_plants').add({
        'userId': user.uid,
        'nickname': nickname,
        'scientificName': scientificName,
        'startDate': Timestamp.fromDate(startDate),
        'imageUrl': imageUrl,
        'alarmSettings': alarmSettings ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // 블루투스 연결 상태 필드 추가 (기본값: false)
        'isBluetoothConnected': false,
        'bluetoothConnectedAt': null, // 연결된 시간 (연결되면 업데이트)
        'bluetoothDeviceId': null, // 연결된 블루투스 기기 ID (향후 사용)
        // 조회 통계 관련 필드
        'viewCount': 0,
        'lastViewedAt': null,
        'weeklyResetDate': Timestamp.fromDate(_getNextSunday()),
      });

      print('✅ 식물 추가 성공: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ 식물 추가 실패: $e');
      throw Exception('식물 정보 저장에 실패했습니다: ${e.toString()}');
    }
  }

  static Future<void> updateBluetoothConnection({
    required String plantId,
    required bool isConnected,
    String? deviceId,
  }) async {
    try {
      print('🔄 블루투스 상태 업데이트: $plantId, 연결: $isConnected');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      Map<String, dynamic> updateData = {
        'isBluetoothConnected': isConnected,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isConnected) {
        updateData['bluetoothConnectedAt'] = FieldValue.serverTimestamp();
        if (deviceId != null) {
          updateData['bluetoothDeviceId'] = deviceId;
        }
      } else {
        updateData['bluetoothConnectedAt'] = null;
        updateData['bluetoothDeviceId'] = null;
      }

      await _firestore.collection('my_plants').doc(plantId).update(updateData);

      print('✅ 블루투스 상태 업데이트 완료');
    } catch (e) {
      print('❌ 블루투스 상태 업데이트 실패: $e');
      throw Exception('블루투스 상태 업데이트에 실패했습니다: ${e.toString()}');
    }
  }

  static Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      print('🔍 이미지 업로드 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      print('✅ 사용자 확인: ${user.uid}');
      print('📁 파일 이름: $fileName');

      final storageRef = _storage
          .ref()
          .child('plant_images')
          .child(user.uid)
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 이미지 업로드 성공: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      throw Exception('이미지 업로드에 실패했습니다: ${e.toString()}');
    }
  }

  static Future<void> deleteMyPlant(String plantId) async {
    try {
      print('🔍 식물 삭제 시작: $plantId');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않음');
        throw Exception('로그인이 필요합니다.');
      }

      // 문서 존재 여부 확인
      DocumentSnapshot doc = await _firestore
          .collection('my_plants')
          .doc(plantId)
          .get()
          .timeout(Duration(seconds: 10));

      if (!doc.exists) {
        print('⚠️ 삭제하려는 식물이 존재하지 않음: $plantId');
        throw Exception('삭제하려는 식물을 찾을 수 없습니다.');
      }

      // 권한 확인 (본인의 식물인지)
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data?['userId'] != user.uid) {
        print('❌ 삭제 권한 없음: ${data?['userId']} != ${user.uid}');
        throw Exception('이 식물을 삭제할 권한이 없습니다.');
      }

      // 관련 데이터들도 함께 삭제 (일지, 센서 데이터 등)
      WriteBatch batch = _firestore.batch();

      // 1. 식물 문서 삭제
      batch.delete(doc.reference);

      // 2. 관련 일지들 삭제 (존재 여부 확인 후)
      try {
        // 먼저 컬렉션이 존재하고 데이터가 있는지 확인
        QuerySnapshot diarySnapshot = await _firestore
            .collection('plant_diaries')
            .where('plantId', isEqualTo: plantId)
            .where('userId', isEqualTo: user.uid)
            .limit(1) // 한 개만 확인
            .get()
            .timeout(Duration(seconds: 3));

        if (diarySnapshot.docs.isNotEmpty) {
          // 데이터가 있으면 전체 삭제 진행
          QuerySnapshot allDiariesSnapshot = await _firestore
              .collection('plant_diaries')
              .where('plantId', isEqualTo: plantId)
              .where('userId', isEqualTo: user.uid)
              .get()
              .timeout(Duration(seconds: 5));

          print('📖 삭제할 일지 개수: ${allDiariesSnapshot.docs.length}');

          for (QueryDocumentSnapshot diaryDoc in allDiariesSnapshot.docs) {
            try {
              await diaryDoc.reference.delete().timeout(Duration(seconds: 3));
              print('✅ 일지 삭제 성공: ${diaryDoc.id}');
            } catch (deleteError) {
              print('⚠️ 개별 일지 삭제 실패: ${diaryDoc.id} - $deleteError');
            }
          }
        } else {
          print('ℹ️ 삭제할 일지가 없음 (정상)');
        }
      } catch (e) {
        print('⚠️ 일지 삭제 실패 (무시): $e');
        // 컬렉션이 없거나 권한 문제일 수 있음 - 무시하고 계속
      }

      // 3. 관련 센서 데이터들 삭제 (존재 여부 확인 후)
      try {
        // 먼저 컬렉션이 존재하고 데이터가 있는지 확인
        QuerySnapshot sensorSnapshot = await _firestore
            .collection('sensor_data')
            .where('plantId', isEqualTo: plantId)
            .where('userId', isEqualTo: user.uid)
            .limit(1) // 한 개만 확인
            .get()
            .timeout(Duration(seconds: 3));

        if (sensorSnapshot.docs.isNotEmpty) {
          // 데이터가 있으면 전체 삭제 진행
          QuerySnapshot allSensorSnapshot = await _firestore
              .collection('sensor_data')
              .where('plantId', isEqualTo: plantId)
              .where('userId', isEqualTo: user.uid)
              .get()
              .timeout(Duration(seconds: 5));

          print('📊 삭제할 센서 데이터 개수: ${allSensorSnapshot.docs.length}');

          for (QueryDocumentSnapshot sensorDoc in allSensorSnapshot.docs) {
            try {
              await sensorDoc.reference.delete().timeout(Duration(seconds: 3));
              print('✅ 센서 데이터 삭제 성공: ${sensorDoc.id}');
            } catch (deleteError) {
              print('⚠️ 개별 센서 데이터 삭제 실패: ${sensorDoc.id} - $deleteError');
            }
          }
        } else {
          print('ℹ️ 삭제할 센서 데이터가 없음 (정상)');
        }
      } catch (e) {
        print('⚠️ 센서 데이터 삭제 실패 (무시): $e');
        // 컬렉션이 없거나 권한 문제일 수 있음 - 무시하고 계속
      }

      // 배치 실행 (메인 식물 문서만)
      batch.delete(doc.reference);
      await batch.commit().timeout(Duration(seconds: 15));

      print('✅ 식물 삭제 성공: $plantId');
    } catch (e) {
      print('❌ 식물 삭제 실패: $e');

      if (e is TimeoutException) {
        throw Exception('삭제 요청이 시간 초과되었습니다. 네트워크 연결을 확인해주세요.');
      } else if (e is FirebaseException) {
        switch (e.code) {
          case 'permission-denied':
            throw Exception('삭제 권한이 없습니다.');
          case 'not-found':
            throw Exception('삭제하려는 식물을 찾을 수 없습니다.');
          case 'unavailable':
            throw Exception('Firebase 서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.');
          default:
            throw Exception('삭제 중 오류가 발생했습니다: ${e.message}');
        }
      } else {
        throw Exception('식물 정보 삭제에 실패했습니다: ${e.toString()}');
      }
    }
  }

  // 개선된 이미지 삭제 함수
  static Future<void> deleteImage(String imageUrl) async {
    try {
      print('🔍 이미지 삭제 시작: $imageUrl');

      if (imageUrl.isEmpty) {
        print('⚠️ 빈 이미지 URL');
        return;
      }

      // URL 유효성 검사
      if (!imageUrl.contains('firebase') && !imageUrl.contains('googleapis')) {
        print('⚠️ Firebase Storage URL이 아님: $imageUrl');
        throw Exception('올바른 Firebase Storage URL이 아닙니다.');
      }

      Reference imageRef = _storage.refFromURL(imageUrl);

      // 파일 존재 여부 확인
      try {
        await imageRef.getMetadata().timeout(Duration(seconds: 5));
      } catch (e) {
        if (e.toString().contains('object-not-found') ||
            e.toString().contains('not-found')) {
          print('⚠️ 이미지가 이미 삭제되었거나 존재하지 않음');
          return; // 이미 없는 파일은 삭제 성공으로 간주
        }
        rethrow;
      }

      // 실제 삭제
      await imageRef.delete().timeout(Duration(seconds: 10));

      print('✅ 이미지 삭제 성공');
    } catch (e) {
      print('❌ 이미지 삭제 실패: $e');

      if (e is TimeoutException) {
        throw Exception('이미지 삭제가 시간 초과되었습니다.');
      } else if (e is FirebaseException) {
        switch (e.code) {
          case 'object-not-found':
          case 'not-found':
            print('ℹ️ 이미지가 이미 삭제됨 (성공으로 처리)');
            return; // 이미 없는 파일은 성공으로 간주
          case 'unauthorized':
            throw Exception('이미지 삭제 권한이 없습니다.');
          case 'retry-limit-exceeded':
            throw Exception('이미지 삭제 재시도 한도를 초과했습니다.');
          default:
            throw Exception('이미지 삭제 중 오류가 발생했습니다: ${e.message}');
        }
      } else {
        throw Exception('이미지 삭제에 실패했습니다: ${e.toString()}');
      }
    }
  }

  // Firebase 서비스에 추가
  static Future<void> checkAndResetAllPlants() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot snapshot =
          await _firestore
              .collection('my_plants')
              .where('userId', isEqualTo: user.uid)
              .get();

      WriteBatch batch = _firestore.batch();
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Timestamp? resetTimestamp = data['weeklyResetDate'] as Timestamp?;

        if (resetTimestamp != null && now.isAfter(resetTimestamp.toDate())) {
          // 리셋이 필요한 식물
          batch.update(doc.reference, {
            'viewCount': 0,
            'weeklyResetDate': Timestamp.fromDate(_getNextSunday()),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print('✅ 만료된 식물들의 조회수 리셋 완료');
    } catch (e) {
      print('❌ 일괄 리셋 실패: $e');
    }
  }

  /// 식물 조회수 증가 (7일 주기 리셋)
  static Future<void> incrementPlantViewCount(String plantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      print('📊 조회수 증가 시작: $plantId');

      DocumentReference plantRef = _firestore
          .collection('my_plants')
          .doc(plantId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot plantDoc = await transaction.get(plantRef);

        if (!plantDoc.exists) {
          throw Exception('식물 문서를 찾을 수 없습니다.');
        }

        Map<String, dynamic> data = plantDoc.data() as Map<String, dynamic>;

        // 현재 조회수 가져오기 (기본값: 0)
        int currentViewCount = data['viewCount'] ?? 0;

        // 주간 리셋 날짜 확인
        Timestamp? resetTimestamp = data['weeklyResetDate'] as Timestamp?;
        DateTime now = DateTime.now();

        // 리셋 날짜가 없거나 지난 경우 새로운 리셋 날짜 설정
        bool needsReset = false;
        if (resetTimestamp == null || now.isAfter(resetTimestamp.toDate())) {
          needsReset = true;
        }

        Map<String, dynamic> updateData = {
          'viewCount': needsReset ? 1 : currentViewCount + 1, // 리셋 또는 증가
          'lastViewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 리셋이 필요한 경우 새로운 리셋 날짜 설정
        if (needsReset) {
          updateData['weeklyResetDate'] = Timestamp.fromDate(_getNextSunday());
          print('🔄 주간 조회수 리셋: $plantId');
        }

        transaction.update(plantRef, updateData);

        print('✅ 조회수 업데이트: ${needsReset ? 1 : currentViewCount + 1}');
      });
    } catch (e) {
      print('❌ 조회수 증가 실패: $e');
      throw Exception('조회수 업데이트에 실패했습니다: ${e.toString()}');
    }
  }

  /// 인기 식물 3개 조회 (7일간 조회수 기준)
  static Future<List<Map<String, dynamic>>> getTopViewedPlantsThisWeek() async {
    try {
      print('🔍 이번 주 인기 식물 조회 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않음');
        return [];
      }

      // 먼저 만료된 식물들 리셋 체크
      await checkAndResetAllPlants();

      // 조회수 기준으로 정렬하여 상위 3개 조회
      QuerySnapshot snapshot =
          await _firestore
              .collection('my_plants')
              .where('userId', isEqualTo: user.uid)
              .orderBy('viewCount', descending: true) // 조회수 높은 순
              .limit(3) // 상위 3개만
              .get();

      print('✅ 인기 식물 쿼리 완료: ${snapshot.docs.length}개');

      List<Map<String, dynamic>> plants = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          plants.add(data);

          // 디버깅 정보
          print('📊 ${data['nickname']}: ${data['viewCount'] ?? 0}회 조회');
        } catch (e) {
          print('❌ 문서 변환 실패 (${doc.id}): $e');
        }
      }

      // 조회수가 0인 경우 최신 등록순으로 정렬
      if (plants.isEmpty ||
          plants.every((plant) => (plant['viewCount'] ?? 0) == 0)) {
        print('📝 조회수가 없어서 최신 등록순으로 조회');

        QuerySnapshot fallbackSnapshot =
            await _firestore
                .collection('my_plants')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .limit(3)
                .get();

        plants =
            fallbackSnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();
      }

      print('✅ 최종 반환 식물 수: ${plants.length}');
      return plants;
    } catch (e) {
      print('❌ 인기 식물 조회 실패: $e');

      // 오류 발생 시 기본 조회로 폴백
      try {
        print('🔄 기본 조회로 폴백 시도...');
        return await getMyPlants();
      } catch (fallbackError) {
        print('❌ 폴백도 실패: $fallbackError');
        return [];
      }
    }
  }

  /// 특정 날짜의 일지 조회
  static Future<String> getDiary(String plantId, DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // 익명 로그인 시도
        await signInAnonymously();
      }

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String documentId = '${plantId}_$dateKey';

      print('📖 일지 조회 시작: $documentId');

      DocumentSnapshot doc =
          await _firestore.collection('plant_diaries').doc(documentId).get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        String content = data?['content'] ?? '';
        print('✅ 일지 조회 성공: ${content.length}자');
        return content;
      } else {
        print('📝 해당 날짜의 일지가 없음');
        return '';
      }
    } catch (e) {
      print('❌ 일지 조회 실패: $e');
      throw Exception('일지를 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 일지 저장
  static Future<void> saveDiary(
    String plantId,
    DateTime date,
    String content,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // 익명 로그인 시도
        await signInAnonymously();
      }

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String documentId = '${plantId}_$dateKey';

      print('💾 일지 저장 시작: $documentId');

      await _firestore.collection('plant_diaries').doc(documentId).set({
        'userId': _auth.currentUser?.uid,
        'plantId': plantId,
        'date': Timestamp.fromDate(date),
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ 일지 저장 성공: ${content.length}자');
    } catch (e) {
      print('❌ 일지 저장 실패: $e');
      throw Exception('일지 저장에 실패했습니다: ${e.toString()}');
    }
  }

  /// 일지 삭제
  static Future<void> deleteDiary(String plantId, DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String documentId = '${plantId}_$dateKey';

      print('🗑️ 일지 삭제 시작: $documentId');

      await _firestore.collection('plant_diaries').doc(documentId).delete();

      print('✅ 일지 삭제 성공');
    } catch (e) {
      print('❌ 일지 삭제 실패: $e');
      throw Exception('일지 삭제에 실패했습니다: ${e.toString()}');
    }
  }

  /// 랜덤 센서 데이터 생성 (모의 IoT 센서)
  static Map<String, dynamic> generateRandomSensorData() {
    final random = DateTime.now().millisecondsSinceEpoch;

    // 시간에 따라 변화하는 랜덤 값들
    int moisture = 40 + (random % 30); // 40-70%
    int temperature = 18 + (random % 12); // 18-30°C
    double conductivity = 1.0 + ((random % 20) / 10.0); // 1.0-3.0 mS/cm

    return {
      'moisture': moisture,
      'temperature': temperature,
      'conductivity': double.parse(conductivity.toStringAsFixed(1)),
      'lastUpdated': DateTime.now(),
    };
  }

  /// 센서 데이터 저장 (Firebase에 기록용)
  static Future<void> saveSensorData(
    String plantId,
    Map<String, dynamic> sensorData,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      print('📊 센서 데이터 저장 시작: $plantId');

      await _firestore.collection('sensor_data').add({
        'userId': _auth.currentUser?.uid,
        'plantId': plantId,
        'moisture': sensorData['moisture'],
        'temperature': sensorData['temperature'],
        'conductivity': sensorData['conductivity'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ 센서 데이터 저장 성공');
    } catch (e) {
      print('❌ 센서 데이터 저장 실패: $e');
      // 센서 데이터 저장 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  /// 최신 센서 데이터 조회 (현재는 사용하지 않지만 향후를 위해 유지)
  static Future<Map<String, dynamic>?> getLatestSensorData(
    String plantId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      print('📊 최신 센서 데이터 조회 시작: $plantId');

      QuerySnapshot snapshot =
          await _firestore
              .collection('sensor_data')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('plantId', isEqualTo: plantId)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data =
            snapshot.docs.first.data() as Map<String, dynamic>;
        print('✅ 최신 센서 데이터 조회 성공');
        return data;
      } else {
        print('📊 센서 데이터가 없음');
        return null;
      }
    } catch (e) {
      print('❌ 센서 데이터 조회 실패: $e');
      return null;
    }
  }

  static Future<void> migrateExistingPlantsForBluetooth() async {
    try {
      print('🔄 기존 식물 데이터 블루투스 필드 마이그레이션 시작...');

      final user = _auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      // 모든 내 식물 조회
      QuerySnapshot snapshot =
          await _firestore
              .collection('my_plants')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .get();

      WriteBatch batch = _firestore.batch();
      int migrationCount = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // isBluetoothConnected 필드가 없는 경우에만 추가
        if (!data.containsKey('isBluetoothConnected')) {
          batch.update(doc.reference, {
            'isBluetoothConnected': false, // 기본값: 연결 안됨
            'bluetoothConnectedAt': null,
            'bluetoothDeviceId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          migrationCount++;
          print('✅ 마이그레이션 대상: ${data['nickname']} (${doc.id})');
        }
      }

      if (migrationCount > 0) {
        await batch.commit();
        print('✅ 블루투스 필드 마이그레이션 완료: $migrationCount개 식물');
      } else {
        print('ℹ️ 마이그레이션할 식물이 없습니다 (모든 식물이 이미 업데이트됨)');
      }
    } catch (e) {
      print('❌ 블루투스 필드 마이그레이션 실패: $e');
      throw Exception('마이그레이션에 실패했습니다: ${e.toString()}');
    }
  }
}
