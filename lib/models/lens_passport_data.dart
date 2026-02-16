/// Parsed payload used by the digital lens passport screens.
class LensPassportData {
  const LensPassportData({
    required this.customerCode,
    required this.orderDate,
    required this.orderNumber,
    required this.lensDesign,
    required this.material,
    required this.photochromicOption,
    required this.antiReflexCoating,
    required this.designVariationCode,
    required this.myDesignSelection,
    required this.patientName,
    required this.right,
    required this.left,
    required this.frameFaceAngle,
  });

  final String customerCode;
  final String orderDate;
  final String orderNumber;
  final String lensDesign;
  final String material;
  final String photochromicOption;
  final String antiReflexCoating;
  final String designVariationCode;
  final String myDesignSelection;
  final String patientName;
  final LensEyeValues right;
  final LensEyeValues left;
  final String frameFaceAngle;

  factory LensPassportData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    return LensPassportData(
      customerCode: (map['customerCode'] ?? '-') as String,
      orderDate: (map['orderDate'] ?? '-') as String,
      orderNumber: (map['orderNumber'] ?? '-') as String,
      lensDesign: (map['lensDesign'] ?? '-') as String,
      material: (map['material'] ?? '-') as String,
      photochromicOption: (map['photochromicOption'] ?? '-') as String,
      antiReflexCoating: (map['antiReflexCoating'] ?? '-') as String,
      designVariationCode: (map['designVariationCode'] ?? '-') as String,
      myDesignSelection: (map['myDesignSelection'] ?? '-') as String,
      patientName: (map['patientName'] ?? '-') as String,
      right: LensEyeValues.fromMap(map['right'] as Map<String, dynamic>?),
      left: LensEyeValues.fromMap(map['left'] as Map<String, dynamic>?),
      frameFaceAngle: (map['frameFaceAngle'] ?? '-') as String,
    );
  }

  static const LensPassportData empty = LensPassportData(
    customerCode: '-',
    orderDate: '-',
    orderNumber: '-',
    lensDesign: '-',
    material: '-',
    photochromicOption: '-',
    antiReflexCoating: '-',
    designVariationCode: '-',
    myDesignSelection: '-',
    patientName: '-',
    right: LensEyeValues.empty,
    left: LensEyeValues.empty,
    frameFaceAngle: '-',
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'customerCode': customerCode,
      'orderDate': orderDate,
      'orderNumber': orderNumber,
      'lensDesign': lensDesign,
      'material': material,
      'photochromicOption': photochromicOption,
      'antiReflexCoating': antiReflexCoating,
      'designVariationCode': designVariationCode,
      'myDesignSelection': myDesignSelection,
      'patientName': patientName,
      'right': right.toMap(),
      'left': left.toMap(),
      'frameFaceAngle': frameFaceAngle,
    };
  }
}

class LensEyeValues {
  const LensEyeValues({
    required this.spherePower,
    required this.cylinderPower,
    required this.cylinderAxis,
    required this.additionPower,
    required this.pupilDistance,
    required this.eyepointHeight,
    required this.inset,
    required this.corneaVertexDistance,
    required this.pantoscopicAngle,
    required this.axialLength,
    required this.frameOrLensMeasurement,
  });

  final String spherePower;
  final String cylinderPower;
  final String cylinderAxis;
  final String additionPower;
  final String pupilDistance;
  final String eyepointHeight;
  final String inset;
  final String corneaVertexDistance;
  final String pantoscopicAngle;
  final String axialLength;
  final String frameOrLensMeasurement;

  factory LensEyeValues.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    return LensEyeValues(
      spherePower: (map['spherePower'] ?? '-') as String,
      cylinderPower: (map['cylinderPower'] ?? '-') as String,
      cylinderAxis: (map['cylinderAxis'] ?? '-') as String,
      additionPower: (map['additionPower'] ?? '-') as String,
      pupilDistance: (map['pupilDistance'] ?? '-') as String,
      eyepointHeight: (map['eyepointHeight'] ?? '-') as String,
      inset: (map['inset'] ?? '-') as String,
      corneaVertexDistance: (map['corneaVertexDistance'] ?? '-') as String,
      pantoscopicAngle: (map['pantoscopicAngle'] ?? '-') as String,
      axialLength: (map['axialLength'] ?? '-') as String,
      frameOrLensMeasurement: (map['frameOrLensMeasurement'] ?? '-') as String,
    );
  }

  static const LensEyeValues empty = LensEyeValues(
    spherePower: '-',
    cylinderPower: '-',
    cylinderAxis: '-',
    additionPower: '-',
    pupilDistance: '-',
    eyepointHeight: '-',
    inset: '-',
    corneaVertexDistance: '-',
    pantoscopicAngle: '-',
    axialLength: '-',
    frameOrLensMeasurement: '-',
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'spherePower': spherePower,
      'cylinderPower': cylinderPower,
      'cylinderAxis': cylinderAxis,
      'additionPower': additionPower,
      'pupilDistance': pupilDistance,
      'eyepointHeight': eyepointHeight,
      'inset': inset,
      'corneaVertexDistance': corneaVertexDistance,
      'pantoscopicAngle': pantoscopicAngle,
      'axialLength': axialLength,
      'frameOrLensMeasurement': frameOrLensMeasurement,
    };
  }
}
