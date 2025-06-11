import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// 네임스페이스 사용으로 충돌 해결
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

// 통합 블루투스 디바이스 클래스
class UniversalBluetoothDevice {
  final String name;
  final String address;
  final dynamic platformDevice;
  final bool isPaired;

  UniversalBluetoothDevice({
    required this.name,
    required this.address,
    required this.platformDevice,
    this.isPaired = false,
  });

  @override
  String toString() => 'Device: $name ($address)';
}

class BluetoothServiceManager {
  // 공통 상태
  static bool isConnected = false;
  static String connectedDeviceName = '';
  static String? lastConnectedDeviceAddress;

  // Flutter Blue Plus 관련 (iOS/Android 공통)
  static fbp.BluetoothDevice? _connectedDevice;
  static fbp.BluetoothCharacteristic? _writeCharacteristic;
  static fbp.BluetoothCharacteristic? _readCharacteristic;
  static StreamSubscription? _scanSubscription;
  static StreamSubscription? _deviceConnectionSubscription;

  // 스캔 결과를 저장할 컨트롤러
  static StreamController<UniversalBluetoothDevice>? _discoveryController;

  // 연결 상태 주기적 체크
  static Timer? _connectionCheckTimer;

  /// 초기화
  static Future<void> initialize() async {
    print('🔧 블루투스 서비스 초기화 시작...');

    try {
      // Flutter Blue Plus 초기화
      print('📱 Flutter Blue Plus 초기화');

      // 블루투스 상태 확인
      fbp.BluetoothAdapterState state =
          await fbp.FlutterBluePlus.adapterState.first;
      print('📱 블루투스 상태: $state');

      if (state != fbp.BluetoothAdapterState.on) {
        print('⚠️ 블루투스가 꺼져있습니다');
      }
    } catch (e) {
      print('❌ 블루투스 상태 확인 실패: $e');
    }

    print('✅ 블루투스 서비스 초기화 완료');
  }

  /// iOS 블루투스 권한 확인 (Flutter Blue Plus 기반)
  static Future<bool> checkiOSBluetoothPermissions() async {
    try {
      print('🍎 iOS 블루투스 권한 확인 시작...');

      // 1. 블루투스 어댑터 상태 확인 (재시도 로직 추가)
      fbp.BluetoothAdapterState adapterState =
          await _getBluetoothStateWithRetry();

      print('📡 블루투스 어댑터 상태: $adapterState');

      // 2. 블루투스가 꺼져있는 경우
      if (adapterState == fbp.BluetoothAdapterState.off) {
        print('📱 블루투스가 꺼져있습니다.');
        return false;
      }

      // 3. 블루투스가 켜져있고 사용 가능한 경우
      if (adapterState == fbp.BluetoothAdapterState.on) {
        print('✅ 블루투스가 활성화되어 있습니다.');

        // 스캔 테스트로 권한 확인
        try {
          print('🔍 권한 테스트를 위한 짧은 스캔 시작...');

          // 1초 동안 테스트 스캔
          await fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 1));

          print('✅ 블루투스 스캔 권한이 허용되어 있습니다.');
          return true;
        } catch (scanError) {
          print('❌ 블루투스 스캔 권한이 거부되었습니다: $scanError');

          if (scanError.toString().contains('unauthorized') ||
              scanError.toString().contains('permission')) {
            print('📱 설정 > 개인정보 보호 및 보안 > 블루투스에서 권한을 확인해주세요.');
            return false;
          }
          return true; // 다른 오류는 권한 문제가 아닐 수 있음
        }
      }

      // 4. 권한이 명확하지 않은 경우 (unknown, unauthorized 등)
      if (adapterState == fbp.BluetoothAdapterState.unauthorized) {
        print('❌ 블루투스 권한이 거부되었습니다.');
        print(
          '📱 설정 > 개인정보 보호 및 보안 > 블루투스 > ${await _getAppName()}에서 권한을 허용해주세요.',
        );
        return false;
      }

      // 5. unknown 상태인 경우 재시도
      if (adapterState == fbp.BluetoothAdapterState.unknown) {
        print('⚠️ 블루투스 상태가 아직 초기화되지 않았습니다. 잠시 후 다시 확인해주세요.');
        return false;
      }

      print('⚠️ 블루투스 상태가 명확하지 않습니다: $adapterState');
      return false;
    } catch (e) {
      print('❌ iOS 블루투스 권한 확인 실패: $e');
      return false;
    }
  }

  /// 블루투스 상태를 재시도하며 확인
  static Future<fbp.BluetoothAdapterState> _getBluetoothStateWithRetry({
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        fbp.BluetoothAdapterState state = await fbp
            .FlutterBluePlus
            .adapterState
            .first
            .timeout(Duration(seconds: 3));

        // unknown이 아니면 바로 반환
        if (state != fbp.BluetoothAdapterState.unknown) {
          return state;
        }

        // unknown이면 잠시 대기 후 재시도
        if (i < maxRetries - 1) {
          print('⏳ 블루투스 초기화 대기 중... (${i + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('❌ 블루투스 상태 확인 시도 ${i + 1} 실패: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    // 모든 재시도가 실패하면 unknown 반환
    return fbp.BluetoothAdapterState.unknown;
  }

  /// 앱 이름 가져오기
  static Future<String> _getAppName() async {
    try {
      return 'Nunito'; // 실제 앱 이름
    } catch (e) {
      return '이 앱';
    }
  }

  /// 개선된 권한 요청 메서드
  static Future<bool> requestPermissionsImproved() async {
    print('🔧 개선된 권한 요청 시작...');

    if (Platform.isIOS) {
      // iOS: Flutter Blue Plus 기반 권한 확인
      bool bluetoothPermission = await checkiOSBluetoothPermissions();

      if (bluetoothPermission) {
        print('✅ iOS 블루투스 권한 확인 완료');
        return true;
      } else {
        print('❌ iOS 블루투스 권한이 필요합니다.');

        // 설정 앱으로 안내
        _showPermissionGuidance();
        return false;
      }
    } else {
      // Android: 기존 permission_handler 사용
      return await _requestAndroidPermissions();
    }
  }

  /// 권한 안내 메시지 출력
  static void _showPermissionGuidance() {
    print('');
    print('📱 ========== 블루투스 권한 설정 안내 ==========');
    print('1. iPhone 설정 앱을 열어주세요');
    print('2. "개인정보 보호 및 보안"을 선택하세요');
    print('3. "블루투스"를 선택하세요');
    print('4. "Nunito" 앱을 찾아서 권한을 허용해주세요');
    print('5. 앱을 다시 시작해주세요');
    print('===============================================');
    print('');
  }

  /// Android 권한 요청 (기존 방식 유지)
  static Future<bool> _requestAndroidPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      bool allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      print('🤖 Android 권한 결과: ${allGranted ? "허용" : "거부"}');
      return allGranted;
    } catch (e) {
      print('❌ Android 권한 요청 실패: $e');
      return false;
    }
  }

  /// 블루투스 상태 실시간 모니터링
  static Stream<bool> get bluetoothStateStream {
    return fbp.FlutterBluePlus.adapterState.map((state) {
      bool isAvailable = state == fbp.BluetoothAdapterState.on;
      print('📡 블루투스 상태 변경: $state (사용가능: $isAvailable)');
      return isAvailable;
    });
  }

  /// 상세한 블루투스 상태 진단
  static Future<void> runBluetoothDiagnostics() async {
    print('\n🔍 ========== 블루투스 상태 진단 ==========');

    try {
      // 1. 플랫폼 정보
      print('📱 플랫폼: ${Platform.operatingSystem}');
      print('📱 버전: ${Platform.operatingSystemVersion}');

      // 2. Flutter Blue Plus 상태
      print('\n📡 Flutter Blue Plus 상태:');
      try {
        fbp.BluetoothAdapterState state = await fbp
            .FlutterBluePlus
            .adapterState
            .first
            .timeout(Duration(seconds: 3));
        print('   어댑터 상태: $state');

        // 상태별 상세 설명
        switch (state) {
          case fbp.BluetoothAdapterState.unknown:
            print('   → 블루투스 상태를 알 수 없습니다');
            break;
          case fbp.BluetoothAdapterState.unavailable:
            print('   → 이 기기는 블루투스를 지원하지 않습니다');
            break;
          case fbp.BluetoothAdapterState.unauthorized:
            print('   → 블루투스 권한이 거부되었습니다');
            break;
          case fbp.BluetoothAdapterState.turningOn:
            print('   → 블루투스가 켜지는 중입니다');
            break;
          case fbp.BluetoothAdapterState.on:
            print('   → ✅ 블루투스가 정상 작동 중입니다');
            break;
          case fbp.BluetoothAdapterState.turningOff:
            print('   → 블루투스가 꺼지는 중입니다');
            break;
          case fbp.BluetoothAdapterState.off:
            print('   → 블루투스가 꺼져있습니다');
            break;
        }
      } catch (e) {
        print('   ❌ 어댑터 상태 확인 실패: $e');
      }

      // 3. Permission Handler 상태 (참고용)
      if (Platform.isIOS) {
        print('\n📋 Permission Handler 상태 (참고용):');
        List<Permission> permissions = [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ];

        for (Permission permission in permissions) {
          try {
            PermissionStatus status = await permission.status;
            print('   ${permission.toString()}: $status');
          } catch (e) {
            print('   ${permission.toString()}: 확인 실패 - $e');
          }
        }
        print('   ⚠️ iOS에서는 이 값들이 정확하지 않을 수 있습니다');
      }

      // 4. 스캔 테스트
      print('\n🔍 스캔 권한 테스트:');
      try {
        print('   테스트 스캔 시작...');
        await fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 1));
        print('   ✅ 스캔 권한이 정상입니다');
      } catch (e) {
        print('   ❌ 스캔 권한 오류: $e');

        if (e.toString().contains('unauthorized')) {
          print('   → 블루투스 권한이 거부되었습니다');
        } else if (e.toString().contains('off')) {
          print('   → 블루투스가 꺼져있습니다');
        }
      }

      // 5. 연결된 기기 확인
      print('\n📱 연결된 기기:');
      try {
        List<fbp.BluetoothDevice> connectedDevices =
            fbp.FlutterBluePlus.connectedDevices;
        if (connectedDevices.isEmpty) {
          print('   연결된 기기가 없습니다');
        } else {
          for (var device in connectedDevices) {
            print('   - ${device.platformName} (${device.remoteId})');
          }
        }
      } catch (e) {
        print('   ❌ 연결된 기기 확인 실패: $e');
      }
    } catch (e) {
      print('❌ 진단 중 오류 발생: $e');
    }

    print('=========================================\n');
  }

  /// 간단한 블루투스 사용 가능 여부 확인
  static Future<bool> isBluetoothUsable() async {
    try {
      // 1. 어댑터 상태 확인
      fbp.BluetoothAdapterState state = await fbp
          .FlutterBluePlus
          .adapterState
          .first
          .timeout(Duration(seconds: 3));

      if (state != fbp.BluetoothAdapterState.on) {
        return false;
      }

      // 2. 스캔 테스트
      await fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 1));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 권한 요청 (기존 호환성을 위해 유지)
  static Future<bool> requestPermissions() async {
    return await requestPermissionsImproved();
  }

  static Future<bool> requestPermissionsStepByStep() async {
    return await requestPermissionsImproved();
  }

  /// 권한 상태 상세 확인
  static Future<void> checkDetailedPermissions() async {
    print('\n🔍 ========== 권한 상태 상세 확인 ==========');

    List<Permission> permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    for (Permission permission in permissions) {
      PermissionStatus status = await permission.status;
      bool isServiceStatus = await permission.isRestricted;

      print('${permission.toString()}:');
      print('   상태: $status');
      print('   제한됨: $isServiceStatus');
      print('   영구거부: ${status.isPermanentlyDenied}');
      print('   재요청 가능: ${await permission.shouldShowRequestRationale}');
      print('');
    }

    print('========================================\n');
  }

  /// 상세 권한 디버깅
  static Future<void> debugPermissions() async {
    print('\n🔍 ========== 권한 디버깅 시작 ==========');

    try {
      // 1. 플랫폼 확인
      print('📱 플랫폼: ${Platform.operatingSystem}');
      print('📱 버전: ${Platform.operatingSystemVersion}');

      // 2. 개별 권한 상태 확인
      List<Permission> permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      print('\n📋 현재 권한 상태:');
      for (Permission permission in permissions) {
        try {
          PermissionStatus status = await permission.status;
          bool isRestricted = await permission.isRestricted;
          bool shouldShow = await permission.shouldShowRequestRationale;

          print('${permission.toString()}:');
          print('  상태: $status');
          print('  제한됨: $isRestricted');
          print('  재요청 가능: $shouldShow');
          print('');
        } catch (e) {
          print('${permission.toString()}: 오류 - $e');
        }
      }

      // 3. 개별적으로 권한 요청 시도
      print('📋 개별 권한 요청 시도:');

      for (Permission permission in permissions) {
        try {
          print('🔄 ${permission.toString()} 요청 중...');
          PermissionStatus result = await permission.request();
          print('  결과: $result');

          // 1초 대기
          await Future.delayed(Duration(seconds: 1));
        } catch (e) {
          print('  오류: $e');
        }
      }

      // 4. Flutter Blue Plus 상태 확인
      print('\n📋 Flutter Blue Plus 상태:');
      try {
        fbp.BluetoothAdapterState state = await fbp
            .FlutterBluePlus
            .adapterState
            .first
            .timeout(Duration(seconds: 5));
        print('  어댑터 상태: $state');
      } catch (e) {
        print('  어댑터 상태 확인 실패: $e');
      }
    } catch (e) {
      print('❌ 디버깅 중 오류: $e');
    }

    print('========================================\n');
  }

  /// 블루투스 활성화 상태 확인
  static Future<bool> isBluetoothEnabled() async {
    try {
      fbp.BluetoothAdapterState state =
          await fbp.FlutterBluePlus.adapterState.first;
      return state == fbp.BluetoothAdapterState.on;
    } catch (e) {
      print('❌ 블루투스 상태 확인 오류: $e');
      return false;
    }
  }

  /// 블루투스 활성화 요청
  static Future<bool> enableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        // Android에서는 시스템 블루투스 설정 열기
        await fbp.FlutterBluePlus.turnOn();
      } else {
        // iOS에서는 시스템 설정에서만 활성화 가능
        print('🍎 iOS에서는 설정 > 블루투스에서 활성화해주세요');
      }

      // 잠시 대기 후 상태 재확인
      await Future.delayed(Duration(seconds: 1));
      return await isBluetoothEnabled();
    } catch (e) {
      print('❌ 블루투스 활성화 오류: $e');
      return false;
    }
  }

  /// 연결된 기기 목록 가져오기
  static Future<List<UniversalBluetoothDevice>> getPairedDevices() async {
    List<UniversalBluetoothDevice> devices = [];

    try {
      print('📱 연결된 기기 확인');

      // 현재 연결된 기기들 가져오기
      List<fbp.BluetoothDevice> connectedDevices =
          fbp.FlutterBluePlus.connectedDevices;

      devices =
          connectedDevices
              .map(
                (device) => UniversalBluetoothDevice(
                  name:
                      device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device',
                  address: device.remoteId.str,
                  platformDevice: device,
                  isPaired: true,
                ),
              )
              .toList();

      print('✅ 연결된 기기 ${devices.length}개 발견');
      return devices;
    } catch (e) {
      print('❌ 연결된 기기 검색 오류: $e');
      return [];
    }
  }

  /// 기기 검색 시작
  static Stream<UniversalBluetoothDevice> startDiscovery() {
    // 기존 컨트롤러가 있으면 닫기
    _discoveryController?.close();

    // 새 컨트롤러 생성
    _discoveryController =
        StreamController<UniversalBluetoothDevice>.broadcast();

    _performDiscovery();

    return _discoveryController!.stream;
  }

  static Future<void> _performDiscovery() async {
    try {
      print('📱 기기 검색 시작');

      // 기존 스캔 중지
      if (fbp.FlutterBluePlus.isScanningNow) {
        await fbp.FlutterBluePlus.stopScan();
      }

      // 발견된 기기들을 추적
      Set<String> discoveredDevices = {};

      // 스캔 결과 리스너 설정
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          fbp.BluetoothDevice device = result.device;
          String deviceId = device.remoteId.str;

          // 중복 방지
          if (!discoveredDevices.contains(deviceId)) {
            discoveredDevices.add(deviceId);

            String deviceName =
                device.platformName.isNotEmpty
                    ? device.platformName
                    : (result.advertisementData.advName.isNotEmpty
                        ? result.advertisementData.advName
                        : 'Unknown Device');

            UniversalBluetoothDevice universalDevice = UniversalBluetoothDevice(
              name: deviceName,
              address: deviceId,
              platformDevice: device,
              isPaired: false,
            );

            _discoveryController?.add(universalDevice);
            print('🔍 기기 발견: $deviceName ($deviceId)');
          }
        }
      });

      // 스캔 시작 (30초 타임아웃)
      await fbp.FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        androidUsesFineLocation: false,
      );

      print('✅ 기기 검색 완료');
    } catch (e) {
      print('❌ 기기 검색 오류: $e');
      _discoveryController?.addError(e);
    }
  }

  /// 기기 검색 중지
  static Future<void> cancelDiscovery() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _discoveryController?.close();
      _discoveryController = null;
      print('🛑 기기 검색 중지');
    } catch (e) {
      print('❌ 기기 검색 중지 오류: $e');
    }
  }

  /// 🔧 진짜 블루투스 연결을 확인하는 개선된 메서드
  static Future<bool> connectToDevice(UniversalBluetoothDevice device) async {
    try {
      print('🔗 연결 시도: ${device.name} (${device.address})');

      // 기존 연결 해제
      await disconnect();

      fbp.BluetoothDevice bluetoothDevice =
          device.platformDevice as fbp.BluetoothDevice;

      // 1단계: 기기에 연결 시도
      print('🔄 1단계: 물리적 연결 시도...');
      await bluetoothDevice.connect(timeout: Duration(seconds: 15));
      print('📡 물리적 연결 시도 완료');

      // 2단계: 실제 연결 상태 확인 (더 엄격하게)
      print('🔄 2단계: 실제 연결 상태 확인...');
      bool isActuallyConnected = false;

      for (int i = 0; i < 15; i++) {
        // 7.5초 동안 확인
        await Future.delayed(Duration(milliseconds: 500));

        try {
          fbp.BluetoothConnectionState currentState = await bluetoothDevice
              .connectionState
              .first
              .timeout(Duration(seconds: 2));
          print('🔍 연결 상태 확인 ${i + 1}/15: $currentState');

          if (currentState == fbp.BluetoothConnectionState.connected) {
            // 3단계: 추가 검증 - 실제 연결 테스트
            try {
              // 서비스 발견으로 실제 연결 검증
              List<fbp.BluetoothService> services = await bluetoothDevice
                  .discoverServices()
                  .timeout(Duration(seconds: 3));
              print('✅ 서비스 발견 성공: ${services.length}개 - 진짜 연결됨!');
              isActuallyConnected = true;
              break;
            } catch (serviceError) {
              print('⚠️ 서비스 발견 실패: $serviceError - 가짜 연결일 수 있음');
              // 서비스 발견 실패하면 계속 시도
              continue;
            }
          }
        } catch (timeoutError) {
          print('⚠️ 연결 상태 확인 타임아웃: $timeoutError');
          continue;
        }
      }

      if (!isActuallyConnected) {
        print('❌ 연결 시도했지만 실제로는 연결되지 않음');

        // 가짜 연결 정리
        try {
          await bluetoothDevice.disconnect();
        } catch (e) {
          print('⚠️ 가짜 연결 정리 중 오류: $e');
        }

        return false;
      }

      // 4단계: 연결 상태 모니터링 설정
      print('🔄 4단계: 연결 모니터링 설정...');
      _deviceConnectionSubscription?.cancel(); // 기존 구독 취소
      _deviceConnectionSubscription = bluetoothDevice.connectionState.listen(
        (state) {
          print('🔗 연결 상태 변경: $state');
          if (state == fbp.BluetoothConnectionState.disconnected) {
            _handleConnectionLost();
          }
        },
        onError: (error) {
          print('❌ 연결 모니터링 오류: $error');
          _handleConnectionLost();
        },
      );

      // 5단계: 서비스 및 특성 설정
      print('🔄 5단계: 서비스 및 특성 설정...');
      try {
        List<fbp.BluetoothService> services =
            await bluetoothDevice.discoverServices();
        print('🔍 발견된 서비스 ${services.length}개');

        // 특성 찾기
        bool characteristicsFound = false;
        for (fbp.BluetoothService service in services) {
          for (fbp.BluetoothCharacteristic characteristic
              in service.characteristics) {
            print(
              '📋 특성 발견: ${characteristic.uuid} (속성: ${characteristic.properties})',
            );

            // 쓰기 가능한 특성 찾기
            if (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse) {
              _writeCharacteristic = characteristic;
              characteristicsFound = true;
              print('✅ 쓰기 특성 설정: ${characteristic.uuid}');
            }

            // 읽기 또는 알림 가능한 특성 찾기
            if (characteristic.properties.read ||
                characteristic.properties.notify) {
              _readCharacteristic = characteristic;
              characteristicsFound = true;
              print('✅ 읽기 특성 설정: ${characteristic.uuid}');

              // 알림 구독
              if (characteristic.properties.notify) {
                try {
                  await characteristic.setNotifyValue(true);
                  characteristic.lastValueStream.listen((data) {
                    _onDataReceived(data);
                  });
                  print('🔔 알림 구독 성공');
                } catch (e) {
                  print('⚠️ 알림 구독 실패: $e');
                }
              }
            }
          }
        }

        if (!characteristicsFound) {
          print('⚠️ 사용 가능한 특성을 찾지 못했지만 연결은 유지');
        }
      } catch (serviceError) {
        print('⚠️ 서비스 발견 실패: $serviceError (연결은 유지)');
      }

      // 6단계: 연결 정보 저장
      _connectedDevice = bluetoothDevice;
      isConnected = true;
      connectedDeviceName = device.name;
      lastConnectedDeviceAddress = device.address;

      // 7단계: 실제 데이터 전송 테스트 (선택적)
      print('🔄 7단계: 실제 데이터 전송 테스트...');
      if (_writeCharacteristic != null) {
        try {
          // 실제 데이터 전송 시도
          await sendData('REAL_CONNECTION_TEST');
          print('📤 실제 데이터 전송 테스트 성공');
        } catch (testError) {
          print('⚠️ 데이터 전송 테스트 실패: $testError (하지만 연결은 유지)');
        }
      } else {
        print('⚠️ 쓰기 특성이 없어서 데이터 전송 테스트 생략');
      }

      // 8단계: 추가 연결 검증
      print('🔄 8단계: 최종 연결 검증...');
      await Future.delayed(Duration(seconds: 1)); // 1초 대기

      try {
        fbp.BluetoothConnectionState finalState = await bluetoothDevice
            .connectionState
            .first
            .timeout(Duration(seconds: 2));
        if (finalState != fbp.BluetoothConnectionState.connected) {
          print('❌ 최종 검증 실패: 연결이 불안정함');
          await disconnect();
          return false;
        }
      } catch (e) {
        print('❌ 최종 검증 실패: $e');
        await disconnect();
        return false;
      }

      print('🎉 블루투스 연결 완전히 성공: ${device.name}');
      print('📊 특성 정보:');
      print('   - 쓰기 특성: ${_writeCharacteristic != null ? "있음" : "없음"}');
      print('   - 읽기 특성: ${_readCharacteristic != null ? "있음" : "없음"}');

      return true;
    } catch (e) {
      print('❌ 연결 실패: $e');

      // 연결 실패 시 완전히 정리
      await disconnect();

      return false;
    }
  }

  /// 🔍 진짜 연결 상태를 확인하는 강화된 메서드
  static Future<bool> isReallyConnected() async {
    try {
      if (_connectedDevice == null) {
        print('🔍 연결 상태 확인: 연결된 기기가 없음');
        return false;
      }

      // 1단계: 연결 상태 확인
      fbp.BluetoothConnectionState state = await _connectedDevice!
          .connectionState
          .first
          .timeout(Duration(seconds: 3));
      print('🔍 현재 연결 상태: $state');

      if (state != fbp.BluetoothConnectionState.connected) {
        print('❌ 연결 상태가 아님');
        return false;
      }

      // 2단계: 서비스 재확인으로 실제 연결 검증
      try {
        List<fbp.BluetoothService> services = await _connectedDevice!
            .discoverServices()
            .timeout(Duration(seconds: 5));
        print('✅ 서비스 재확인 성공: ${services.length}개 - 진짜 연결됨');
        return true;
      } catch (serviceError) {
        print('❌ 서비스 재확인 실패: $serviceError - 가짜 연결');
        return false;
      }
    } catch (e) {
      print('❌ 연결 상태 확인 실패: $e');
      return false;
    }
  }

  /// 🔧 개선된 데이터 전송 메서드 (실제 연결 확인 포함)
  static Future<bool> sendData(String data) async {
    try {
      // 먼저 실제 연결 상태 확인
      if (!await isReallyConnected()) {
        print('❌ 실제 연결되지 않음 - 데이터 전송 불가');
        return false;
      }

      if (_writeCharacteristic == null) {
        print('❌ 쓰기 특성이 없음 - 데이터 전송 불가');
        return false;
      }

      List<int> bytes = utf8.encode(data);
      await _writeCharacteristic!.write(bytes);
      print('📤 실제 데이터 전송 성공: $data');

      return true;
    } catch (e) {
      print('❌ 데이터 전송 오류: $e');
      return false;
    }
  }

  /// 연결 해제
  static Future<void> disconnect() async {
    try {
      _deviceConnectionSubscription?.cancel();

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _writeCharacteristic = null;
      _readCharacteristic = null;
      isConnected = false;
      connectedDeviceName = '';
      lastConnectedDeviceAddress = null;

      print('🔌 연결 해제 완료');
    } catch (e) {
      print('❌ 연결 해제 오류: $e');
    }
  }

  /// 연결 상태 확인
  static bool get connectionStatus {
    return isConnected && _connectedDevice != null;
  }

  /// 연결된 기기 이름 가져오기
  static String get getConnectedDeviceName => connectedDeviceName;

  /// 센서 데이터 요청
  static Future<bool> requestSensorData() async {
    return await sendData('GET_SENSOR_DATA');
  }

  /// 연결 상태 주기적 체크 시작
  static void startConnectionMonitoring() {
    _connectionCheckTimer?.cancel();

    _connectionCheckTimer = Timer.periodic(Duration(seconds: 10), (
      timer,
    ) async {
      if (isConnected) {
        bool reallyConnected = await isReallyConnected();
        if (!reallyConnected) {
          print('⚠️ 연결이 끊어진 것을 감지함');
          _handleConnectionLost();
        }
      }
    });
  }

  /// 연결 상태 주기적 체크 중지
  static void stopConnectionMonitoring() {
    _connectionCheckTimer?.cancel();
  }

  /// 데이터 수신 처리
  static void _onDataReceived(List<int> data) {
    try {
      String received = String.fromCharCodes(data);
      print('📥 데이터 수신: $received');

      // 센서 데이터 처리
      _handleReceivedData(received);
    } catch (e) {
      print('❌ 데이터 처리 오류: $e');
    }
  }

  /// 수신 데이터 처리
  static void _handleReceivedData(String data) {
    try {
      // JSON 파싱 시도
      Map<String, dynamic> sensorData = json.decode(data);
      print('📊 센서 데이터: $sensorData');
    } catch (e) {
      // 일반 텍스트
      print('💬 메시지: $data');
    }
  }

  /// 연결 끊어짐 처리
  static void _handleConnectionLost() {
    print('💔 연결이 끊어졌습니다');
    isConnected = false;
    _connectedDevice = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
    connectedDeviceName = '';
    lastConnectedDeviceAddress = null;
  }
}

// 기존 코드와의 호환성을 위한 별칭
typedef BluetoothService = BluetoothServiceManager;
