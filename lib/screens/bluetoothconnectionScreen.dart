import 'package:flutter/material.dart';
import 'package:nunito/services/bluetooth_service.dart';
import 'package:nunito/services/firebase_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nunito/widgets/toast.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final Map<String, dynamic> plant;

  const BluetoothConnectionScreen({super.key, required this.plant});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  List<UniversalBluetoothDevice> _pairedDevices = [];
  final List<UniversalBluetoothDevice> _discoveredDevices = [];
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _bluetoothEnabled = false;
  bool _showPairedDevices = true;
  String _connectionStatus = ''; // 연결 상태 메시지 추가

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      // 권한 확인
      bool hasPermission = await BluetoothServiceManager.requestPermissions();
      if (!hasPermission) {
        _showErrorDialog('블루투스 권한이 필요합니다.');
        return;
      }

      // 블루투스 상태 확인
      bool enabled = await BluetoothServiceManager.isBluetoothEnabled();
      if (!enabled) {
        bool enableResult = await BluetoothServiceManager.enableBluetooth();
        if (!enableResult) {
          _showErrorDialog('블루투스를 활성화해주세요.');
          return;
        }
      }

      setState(() {
        _bluetoothEnabled = true;
      });

      // 페어링된 기기 목록 가져오기
      await _loadPairedDevices();
    } catch (e) {
      print('❌ 블루투스 초기화 오류: $e');
      _showErrorDialog('블루투스 초기화에 실패했습니다.');
    }
  }

  Future<void> _loadPairedDevices() async {
    try {
      List<UniversalBluetoothDevice> devices =
          await BluetoothServiceManager.getPairedDevices();
      setState(() {
        _pairedDevices = devices;
      });
    } catch (e) {
      print('❌ 페어링된 기기 로드 오류: $e');
    }
  }

  void _startDiscovery() {
    if (_isDiscovering) return;

    setState(() {
      _isDiscovering = true;
      _discoveredDevices.clear();
      _showPairedDevices = false;
    });

    BluetoothServiceManager.startDiscovery().listen(
      (device) {
        setState(() {
          bool exists = _discoveredDevices.any(
            (d) => d.address == device.address,
          );
          if (!exists) {
            _discoveredDevices.add(device);
          }
        });
      },
      onError: (error) {
        print('❌ 기기 검색 오류: $error');
        _stopDiscovery();
      },
      onDone: () {
        _stopDiscovery();
      },
    );

    // 30초 후 자동 중지
    Future.delayed(Duration(seconds: 30), () {
      if (_isDiscovering) {
        _stopDiscovery();
      }
    });
  }

  void _stopDiscovery() {
    if (!_isDiscovering) return;

    BluetoothServiceManager.cancelDiscovery();
    setState(() {
      _isDiscovering = false;
    });
  }

  // 🔧 개선된 연결 메서드
  Future<void> _connectToDevice(UniversalBluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = '연결 중...';
    });

    try {
      // 1단계: 물리적 연결 시도
      setState(() {
        _connectionStatus = '${device.name}에 연결 시도 중...';
      });

      bool success = await BluetoothServiceManager.connectToDevice(device);

      if (!success) {
        throw Exception('연결에 실패했습니다');
      }

      // 2단계: 실제 연결 상태 재확인
      setState(() {
        _connectionStatus = '연결 상태 확인 중...';
      });

      await Future.delayed(Duration(seconds: 2)); // 연결 안정화 대기

      bool reallyConnected = await BluetoothServiceManager.isReallyConnected();
      if (!reallyConnected) {
        throw Exception('연결이 완료되지 않았습니다');
      }

      // 3단계: Firebase 상태 업데이트
      setState(() {
        _connectionStatus = 'Firebase 업데이트 중...';
      });

      await FirebaseService.updateBluetoothConnection(
        plantId: widget.plant['id'],
        isConnected: true,
        deviceId: device.address,
      );

      // 4단계: 연결 모니터링 시작
      BluetoothServiceManager.startConnectionMonitoring();

      // 성공 메시지
      setState(() {
        _connectionStatus = '연결 완료!';
      });
      CustomFluttertoast.showToast(
        context: context,
        msg: "✅ ${device.name}에 성공적으로 연결되었습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFF0BB57F),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // 잠시 대기 후 이전 화면으로 돌아가기
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ 연결 실패: $e');

      setState(() {
        _connectionStatus = '연결 실패';
      });

      // 실패 시 정리 작업
      await BluetoothServiceManager.disconnect();

      _showErrorDialog('연결 실패: ${e.toString()}\n\n다시 시도해주세요.');
    } finally {
      setState(() {
        _isConnecting = false;
        _connectionStatus = '';
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('오류', style: TextStyle(fontFamily: 'Pretendard')),
            content: Text(message, style: TextStyle(fontFamily: 'Pretendard')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('확인', style: TextStyle(fontFamily: 'Pretendard')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '블루투스 연결',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF363636),
        elevation: 0,
      ),
      body: _bluetoothEnabled ? _buildDeviceList() : _buildBluetoothDisabled(),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children: [
        // 식물 정보
        Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF0F8F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF0BB57F).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.spa, color: Color(0xFF0BB57F), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plant['nickname'] ?? '내 식물',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      '센서와 연결할 기기를 선택하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 연결 상태 표시 (연결 중일 때만)
        if (_isConnecting && _connectionStatus.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 탭 바 (기존과 동일)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showPairedDevices = true;
                    });
                    _stopDiscovery();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _showPairedDevices
                              ? Color(0xFF0BB57F)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '페어링된 기기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _showPairedDevices
                                ? Colors.white
                                : Color(0xFF0BB57F),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: _isDiscovering ? null : _startDiscovery,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          !_showPairedDevices
                              ? Color(0xFF0BB57F)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDiscovering) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  !_showPairedDevices
                                      ? Colors.white
                                      : Color(0xFF0BB57F),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Text(
                          _isDiscovering ? '검색 중...' : '기기 검색',
                          style: TextStyle(
                            color:
                                !_showPairedDevices
                                    ? Colors.white
                                    : Color(0xFF0BB57F),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // 기기 목록
        Expanded(child: _buildCurrentDeviceList()),
      ],
    );
  }

  // 나머지 메서드들은 기존과 동일...
  Widget _buildCurrentDeviceList() {
    List<UniversalBluetoothDevice> currentDevices =
        _showPairedDevices ? _pairedDevices : _discoveredDevices;

    if (currentDevices.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: currentDevices.length,
      itemBuilder: (context, index) {
        return _buildDeviceItem(currentDevices[index], _showPairedDevices);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _showPairedDevices ? '페어링된 기기가 없습니다' : '검색된 기기가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _showPairedDevices
                ? '기기 검색 탭에서 새 기기를 찾아보세요'
                : '기기 검색을 시작하려면 위의 \'기기 검색\' 버튼을 눌러주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(UniversalBluetoothDevice device, bool isPaired) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
          color: Color(0xFF0BB57F),
          size: 24,
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
            ),
            if (isPaired)
              Text(
                '페어링됨',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0BB57F),
                  fontFamily: 'Pretendard',
                ),
              ),
          ],
        ),
        trailing:
            _isConnecting
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0BB57F),
                  ),
                )
                : ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0BB57F),
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 32),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    '연결',
                    style: TextStyle(fontSize: 12, fontFamily: 'Pretendard'),
                  ),
                ),
        tileColor: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildBluetoothDisabled() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '블루투스가 비활성화되어 있습니다',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '설정에서 블루투스를 활성화해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeBluetooth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0BB57F),
              foregroundColor: Colors.white,
            ),
            child: Text('다시 시도', style: TextStyle(fontFamily: 'Pretendard')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isDiscovering) {
      _stopDiscovery();
    }
    BluetoothServiceManager.stopConnectionMonitoring();
    super.dispose();
  }
}
