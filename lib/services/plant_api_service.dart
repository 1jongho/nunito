// lib/services/plant_api_service.dart
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class PlantApiService {
  final String apiKey; // 농사로에서 발급받은 API 키
  final String baseUrl = 'http://api.nongsaro.go.kr/service/garden';

  PlantApiService({required this.apiKey});

  // 실내정원용 식물 목록 가져오기
  Future<List<Plant>> getPlantList({
    int pageNo = 1,
    int numOfRows = 10,
    String? searchParam,
  }) async {
    String url =
        '$baseUrl/gardenList?apiKey=$apiKey&pageNo=$pageNo&numOfRows=$numOfRows';

    // 검색어가 있으면 추가
    if (searchParam != null && searchParam.isNotEmpty) {
      url += '&sType=sCntntsSj&sText=$searchParam';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      return items.map((item) {
        return Plant(
          cntntsNo: _getElementText(item, 'cntntsNo'),
          cntntsSj: _getElementText(item, 'cntntsSj'),
          rtnFileUrl: _getElementText(item, 'rtnFileUrl'),
          rtnThumbFileUrl: _getElementText(item, 'rtnThumbFileUrl'),
        );
      }).toList();
    } else {
      throw Exception('Failed to load plants');
    }
  }

  // 식물 상세 정보 가져오기
  Future<PlantDetail> getPlantDetail(String cntntsNo) async {
    final url = Uri.parse(
      '$baseUrl/gardenDtl?apiKey=$apiKey&cntntsNo=$cntntsNo',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final item = document.findAllElements('item').first;

      return PlantDetail(
        cntntsNo: _getElementText(item, 'cntntsNo'),
        plntbneNm: _getElementText(item, 'plntbneNm'),
        plntzrNm: _getElementText(item, 'plntzrNm'),
        fmlNm: _getElementText(item, 'fmlNm'),
        fmlCodeNm: _getElementText(item, 'fmlCodeNm'),
        orgplceInfo: _getElementText(item, 'orgplceInfo'),
        adviseInfo: _getElementText(item, 'adviseInfo'),
        growthHgInfo: _getElementText(item, 'growthHgInfo'),
        growthAraInfo: _getElementText(item, 'growthAraInfo'),
        lefStleInfo: _getElementText(item, 'lefStleInfo'),
        grwhTpCodeNm: _getElementText(item, 'grwhTpCodeNm'),
        waterCycleInfo: _getElementText(item, 'watercycleSprngCodeNm'),
        hdCodeNm: _getElementText(item, 'hdCodeNm'),
        lightCodeNm: _getElementText(item, 'lighttdemanddoCodeNm'),
      );
    } else {
      throw Exception('Failed to load plant detail');
    }
  }

  // XML 요소의 텍스트 가져오기 (null 처리 포함)
  String _getElementText(xml.XmlElement item, String elementName) {
    final element = item.findElements(elementName).firstOrNull;
    return element?.innerText ?? '';
  }
}

// 식물 목록을 위한 모델 클래스
class Plant {
  final String cntntsNo; // 컨텐츠 번호
  final String cntntsSj; // 식물명
  final String rtnFileUrl; // 이미지 URL
  final String rtnThumbFileUrl; // 썸네일 URL

  Plant({
    required this.cntntsNo,
    required this.cntntsSj,
    required this.rtnFileUrl,
    required this.rtnThumbFileUrl,
  });
}

// 식물 상세 정보를 위한 모델 클래스
class PlantDetail {
  final String cntntsNo; // 컨텐츠 번호
  final String plntbneNm; // 식물학 명
  final String plntzrNm; // 식물영 명
  final String fmlNm; // 과 명
  final String fmlCodeNm; // 과 코드명
  final String orgplceInfo; // 원산지 정보
  final String adviseInfo; // 조언 정보
  final String growthHgInfo; // 성장 높이 정보
  final String growthAraInfo; // 성장 넓이 정보
  final String lefStleInfo; // 잎 형태 정보
  final String grwhTpCodeNm; // 생육 온도 코드명
  final String waterCycleInfo; // 물주기 정보
  final String hdCodeNm; // 습도 코드명
  final String lightCodeNm; // 광요구도 코드명

  PlantDetail({
    required this.cntntsNo,
    required this.plntbneNm,
    required this.plntzrNm,
    required this.fmlNm,
    required this.fmlCodeNm,
    required this.orgplceInfo,
    required this.adviseInfo,
    required this.growthHgInfo,
    required this.growthAraInfo,
    required this.lefStleInfo,
    required this.grwhTpCodeNm,
    required this.waterCycleInfo,
    required this.hdCodeNm,
    required this.lightCodeNm,
  });
}
