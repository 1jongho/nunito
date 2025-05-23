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

class PlantDetail {
  final String cntntsNo; // 컨텐츠 번호
  final String cntntsSj; // 식물명 (추가된 필드)
  final String plntbneNm; // 식물학 명
  final String plntzrNm; // 식물영 명
  final String distbNm;
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
  final String lighttdemanddoCodeNm; // 광요구도 코드명
  final String toxctyInfo; // 독성 정보
  final String dlthtsManageInfo; // 병충해 관리 정보
  final String speclmanageInfo; // 특별관리 정보
  final String fncltyInfo; // 기능성 정보
  final String watercycleSprngCodeNm; // 물주기 봄 코드명
  final String watercycleSummerCodeNm; // 물주기 여름 코드명
  final String watercycleAutumnCodeNm; // 물주기 가을 코드명
  final String watercycleWinterCodeNm; // 물주기 겨울 코드명

  PlantDetail({
    required this.cntntsNo,
    this.cntntsSj = '', // 추가된 필드 (기본값 빈 문자열)
    required this.plntbneNm,
    required this.plntzrNm,
    this.distbNm = '',
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
    required this.lighttdemanddoCodeNm,
    required this.toxctyInfo,
    required this.dlthtsManageInfo,
    required this.speclmanageInfo,
    required this.fncltyInfo,
    required this.watercycleSprngCodeNm,
    this.watercycleSummerCodeNm = '',
    this.watercycleAutumnCodeNm = '',
    this.watercycleWinterCodeNm = '',
  });
}
