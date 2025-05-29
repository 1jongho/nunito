import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:nunito/models/plant.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantApiService {
  late final String apiKey;
  final String baseUrl = 'http://api.nongsaro.go.kr/service/garden';

  PlantApiService() {
    // .env 파일에서 API 키 가져오기
    apiKey = dotenv.get('NONGSARO_API_KEY');
  }

  // 실내정원용 식물 목록 가져오기
  Future<List<Plant>> getPlantList({
    int pageNo = 1,
    int numOfRows = 20,
    String? searchParam,
  }) async {
    String url =
        '$baseUrl/gardenList?apiKey=$apiKey&pageNo=$pageNo&numOfRows=$numOfRows';

    // 검색어가 있으면 추가
    if (searchParam != null && searchParam.isNotEmpty) {
      url += '&sType=sCntntsSj&sText=$searchParam';
    }

    final response = await http.get(Uri.parse(url));

    print('API 응답 상태 코드: ${response.statusCode}'); // 상태 코드 출력

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
      throw Exception('식물 정보를 불러오지 못했습니다.');
    }
  }

  // XML 요소의 텍스트 가져오기 (null 처리 포함)
  String _getElementText(xml.XmlElement item, String elementName) {
    final element = item.findElements(elementName).firstOrNull;
    return element?.innerText ?? '';
  }

  Future<PlantDetail> getPlantDetail(String cntntsNo) async {
    final url = Uri.parse(
      '$baseUrl/gardenDtl?apiKey=$apiKey&cntntsNo=$cntntsNo',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final item = document.findAllElements('item').first;

      // ========== 계절별 물주기 정보 파싱 ==========
      String sprngWaterCycle = _getElementText(item, 'watercycleSprngCodeNm');
      String summerWaterCycle = _getElementText(item, 'watercycleSummerCodeNm');
      String autumnWaterCycle = _getElementText(item, 'watercycleAutumnCodeNm');
      String winterWaterCycle = _getElementText(item, 'watercycleWinterCodeNm');

      String cntntsSj = _getElementText(item, 'cntntsSj');

      return PlantDetail(
        cntntsNo: _getElementText(item, 'cntntsNo'),
        cntntsSj: cntntsSj,
        distbNm: _getElementText(item, 'distbNm'),
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
        waterCycleInfo: _getElementText(item, 'waterCycleInfo'),
        hdCodeNm: _getElementText(item, 'hdCodeNm'),
        lighttdemanddoCodeNm: _getElementText(item, 'lighttdemanddoCodeNm'),
        toxctyInfo: _getElementText(item, 'toxctyInfo'),
        dlthtsManageInfo: _getElementText(item, 'dlthtsManageInfo'),
        speclmanageInfo: _getElementText(item, 'speclmanageInfo'),
        fncltyInfo: _getElementText(item, 'fncltyInfo'),
        watercycleSprngCodeNm: sprngWaterCycle,

        // ========== 계절별 물주기 필드 추가 ==========
        watercycleSummerCodeNm: summerWaterCycle,
        watercycleAutumnCodeNm: autumnWaterCycle,
        watercycleWinterCodeNm: winterWaterCycle,
        // =========================================
      );
    } else {
      throw Exception('Failed to load plant detail');
    }
  }
}
