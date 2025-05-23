import 'dart:io';
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

        // 조회 통계 관련 필드 추가
        'viewCount': 0, // 이번 주 조회수
        'lastViewedAt': null, // 마지막 조회 시간
        'weeklyResetDate': Timestamp.fromDate(_getNextSunday()), // 다음 일요일
      });

      print('✅ 식물 추가 성공: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ 식물 추가 실패: $e');
      throw Exception('식물 정보 저장에 실패했습니다: ${e.toString()}');
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

      await _firestore.collection('my_plants').doc(plantId).delete();

      print('✅ 식물 삭제 성공: $plantId');
    } catch (e) {
      print('❌ 식물 삭제 실패: $e');
      throw Exception('식물 정보 삭제에 실패했습니다: ${e.toString()}');
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      print('🔍 이미지 삭제 시작: $imageUrl');

      Reference imageRef = _storage.refFromURL(imageUrl);
      await imageRef.delete();

      print('✅ 이미지 삭제 성공');
    } catch (e) {
      print('❌ 이미지 삭제 실패: $e');
      throw Exception('이미지 삭제에 실패했습니다: ${e.toString()}');
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
}
