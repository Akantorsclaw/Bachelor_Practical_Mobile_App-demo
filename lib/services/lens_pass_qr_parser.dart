import '../models/lens_passport_data.dart';

/// Parses QR payload links from myhoyalens.com into structured passport data.
class LensPassQrParser {
  const LensPassQrParser();

  LensPassportData? parse(String raw) {
    if (raw.trim().isEmpty) return null;

    final normalized = _normalizeInput(raw.trim());
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;

    final params = uri.queryParameters;
    if (params.isEmpty) return null;

    return LensPassportData(
      customerCode: _val(params, 'CC'),
      orderDate: _formatOrderDate(_val(params, 'OD')),
      orderNumber: _val(params, 'ON'),
      lensDesign: _mapLensDesign(_val(params, 'LC')),
      material: _mapMaterial(_val(params, 'MC')),
      photochromicOption: _mapPhotochromic(_val(params, 'PC')),
      antiReflexCoating: _mapCoating(_val(params, 'AC')),
      designVariationCode: _val(params, 'DVC'),
      myDesignSelection: _val(params, 'MDS'),
      patientName: _val(params, 'PN'),
      right: LensEyeValues(
        spherePower: _val(params, 'SR'),
        cylinderPower: _val(params, 'CR'),
        cylinderAxis: _val(params, 'XR'),
        additionPower: _val(params, 'AR'),
        pupilDistance: _val(params, 'PDR'),
        eyepointHeight: _val(params, 'EPR'),
        inset: _val(params, 'IR'),
        corneaVertexDistance: _val(params, 'RFC'),
        pantoscopicAngle: _val(params, 'RPA'),
        axialLength: _val(params, 'ALR'),
        frameOrLensMeasurement: _val(params, 'FL'),
      ),
      left: LensEyeValues(
        spherePower: _val(params, 'SL'),
        cylinderPower: _val(params, 'CL'),
        cylinderAxis: _val(params, 'XL'),
        additionPower: _val(params, 'AL'),
        pupilDistance: _val(params, 'PDL'),
        eyepointHeight: _val(params, 'EPL'),
        inset: _val(params, 'IL'),
        corneaVertexDistance: _val(params, 'LFC'),
        pantoscopicAngle: _val(params, 'LPA'),
        axialLength: _val(params, 'ALL'),
        frameOrLensMeasurement: _val(params, 'FL'),
      ),
      frameFaceAngle: _val(params, 'FFA'),
    );
  }

  String _normalizeInput(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('?')) return 'https://www.myhoyalens.com/$raw';
    if (raw.contains('&') && raw.contains('=')) {
      return 'https://www.myhoyalens.com/?$raw';
    }
    return raw;
  }

  String _val(Map<String, String> params, String key) {
    final value = params[key]?.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }

  String _formatOrderDate(String value) {
    if (value.length == 8) {
      return '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}';
    }
    return value;
  }

  String _mapLensDesign(String code) {
    const map = {
      'HES': 'Hoyalux iD MySense',
      'HEP': 'Hoyalux iD MySense Prestige',
      'HES F': 'Hoyalux iD MySense',
      'HES B': 'Hoyalux iD MySense',
      'HEP F': 'Hoyalux iD MySense Prestige',
      'HEP B': 'Hoyalux iD MySense Prestige',
    };
    return map[code] ?? code;
  }

  String _mapMaterial(String code) {
    const map = {
      '50': '1.50',
      '54C': '1.50UV',
      'PNX': '1.53',
      'M8': '1.60',
      'E8': '1.60',
      '67': '1.67',
      'E1': '1.67',
      '74': '1.74',
      '557': 'EYBLU 1.55',
      'M87': 'EYBLU 1.60',
      'M17': 'EYBLU 1.67',
    };
    return map[code] ?? code;
  }

  String _mapPhotochromic(String code) {
    if (code == '-' || code.isEmpty) return '-';
    const map = {
      '5B': 'Sensity 2 Brown',
      '5G': 'Sensity 2 Grey',
      '5O': 'Sensity 2 Green',
      '5S': 'Sensity 2 Blue',
      'XB': 'Sensity Dark Brown',
      'XG': 'Sensity Dark Grey',
      'XO': 'Sensity Dark Green',
      'FB': 'Sensity Fast Brown',
      'FG': 'Sensity Fast Grey',
    };
    return map[code] ?? code;
  }

  String _mapCoating(String code) {
    if (code == '-' || code.isEmpty) return '-';
    const map = {'H-VL2': 'Hi-Vision MEIRYO'};
    return map[code] ?? code;
  }
}
