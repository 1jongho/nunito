import 'package:flutter/material.dart';
import 'package:nunito/widgets/navbar.dart';
import 'package:nunito/services/plant_api_service.dart';
import 'package:nunito/models/plant.dart';

class PlantDetailScreen extends StatefulWidget {
  final String cntntsNo; // 식물 컨텐츠 번호

  const PlantDetailScreen({super.key, required this.cntntsNo});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  // 생성자 수정: apiKey 파라미터 제거
  final PlantApiService _apiService = PlantApiService();
  bool _isLoading = true;
  PlantDetail? _plantDetail;

  @override
  void initState() {
    super.initState();
    _loadPlantDetail();
  }

  Future<void> _loadPlantDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await _apiService.getPlantDetail(widget.cntntsNo);
      setState(() {
        _plantDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('식물 상세 정보를 가져오는 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('식물 상세 정보를 불러오는데 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('식물 상세 정보'),
        centerTitle: true,
        backgroundColor: Color(0xFF0BB57F),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Color(0xFF0BB57F)),
              )
              : _plantDetail == null
              ? Center(child: Text('식물 정보를 불러올 수 없습니다.'))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 식물 이름 및 학명
                    Center(
                      child: Text(
                        _plantDetail!.plntbneNm,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        _plantDetail!.plntzrNm,
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // 섹션들 (기본 정보, 관리 정보, 기타 정보)
                    _buildInfoSection('기본 정보', [
                      _buildInfoItem('과명', _plantDetail!.fmlNm),
                      _buildInfoItem('원산지', _plantDetail!.orgplceInfo),
                    ]),

                    _buildInfoSection('관리 정보', [
                      // watercycleSprngCodeNm 대신 waterCycleInfo 사용
                      _buildInfoItem('물 주기', _plantDetail!.waterCycleInfo),
                      _buildInfoItem('습도', _plantDetail!.hdCodeNm),
                      _buildInfoItem('광도', _plantDetail!.lighttdemanddoCodeNm),
                    ]),

                    _buildInfoSection('추가 정보', [
                      _buildInfoItem('조언 정보', _plantDetail!.adviseInfo),
                      _buildInfoItem('성장 높이', _plantDetail!.growthHgInfo),
                      _buildInfoItem('독성 정보', _plantDetail!.toxctyInfo),
                      _buildInfoItem('병충해 관리', _plantDetail!.dlthtsManageInfo),
                      _buildInfoItem('특별 관리', _plantDetail!.speclmanageInfo),
                      _buildInfoItem('기능성 정보', _plantDetail!.fncltyInfo),
                    ]),
                  ],
                ),
              ),
    );
  }

  // 정보 섹션 위젯
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF0BB57F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // 정보 항목 위젯
  Widget _buildInfoItem(String label, String value) {
    // 값이 비어있으면 표시하지 않음
    if (value.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8),
          Divider(),
        ],
      ),
    );
  }
}
