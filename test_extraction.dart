
void main() {
  final testCases = [
    {
      'name': 'Foto 1 - 4.2 km, 4.1 L/100km',
      'text': 'P \u26FD 47 km \n Viaje actual \n 4.2 km \n 0:12 h:m \n 4.1 L/100km \n 25470 km',
    },
    {
      'name': 'Foto 2 - 16.8 km, 7.4 L/100km',
      'text': 'P \u26FD 52 km \n Viaje actual \n 16.8 km \n 0:16 h:m \n 7.4 L/100km \n 25466 km',
    },
    {
      'name': 'Error OCR L as 1',
      'text': 'Viaje actual \n 16.8 km \n 0:16 h:m \n 7.4 1/100km',
    },
    {
      'name': 'Error OCR 100km as hookm',
      'text': 'Viaje actual \n 5.5 km \n 0:05 h:m \n 6.2 L/hookm',
    }
  ];

  for (var test in testCases) {
    print('--- Test: ${test['name']} ---');
    final result = extractVehicleData(test['text'] as String);
    print('Trip: ${result['tripKm']} km');
    print('Consumo: ${result['consumption']} ${result['consumptionUnit']}');
    print('Total: ${result['totalKm']} km');
    print('');
  }
}

Map<String, dynamic> extractVehicleData(String text) {
  final Map<String, dynamic> data = {
    'totalKm': null,
    'tripKm': null,
    'consumption': null,
    'consumptionUnit': 'L/100km',
  };

  final lines = text.split('\n').map((l) => l.trim()).toList();

  final anchorPattern = RegExp(r'(viaje|actual|trip|vi.je|act.al)', caseSensitive: false);
  int anchorIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (anchorPattern.hasMatch(lines[i])) {
      anchorIndex = i;
      break;
    }
  }

  // Extract Consumption
  final helperData = extractConsumptionWithUnit(lines, anchorIndex: anchorIndex);
  if (helperData != null) {
    data['consumption'] = helperData['value'];
    data['consumptionUnit'] = helperData['unit'];
  }

  // Extract Trip Km
  data['tripKm'] = extractTripKilometers(lines, anchorIndex: anchorIndex);
  
  // Extract Total Km
  data['totalKm'] = extractTotalKilometers(lines);

  return data;
}

double? extractTripKilometers(List<String> lines, {int anchorIndex = -1}) {
  if (anchorIndex != -1) {
    for (int i = anchorIndex + 1; i <= anchorIndex + 4 && i < lines.length; i++) {
      final kmMatch = RegExp(r'(\d+[.,]\d+)\s*k[mr]n?', caseSensitive: false).firstMatch(lines[i]);
      if (kmMatch != null) {
        final val = double.tryParse(kmMatch.group(1)!.replaceAll(',', '.'));
        if (val != null && val >= 0.1 && val < 500) return val;
      }
    }
  }
  return null; 
}

Map<String, dynamic>? extractConsumptionWithUnit(List<String> lines, {int anchorIndex = -1}) {
  if (anchorIndex != -1) {
    for (int i = anchorIndex + 1; i <= anchorIndex + 5 && i < lines.length; i++) {
      final result = extractConsumptionFromLine(lines[i]);
      if (result != null) return result;
    }
  }
  for (final line in lines) {
    final result = extractConsumptionFromLine(line);
    if (result != null) return result;
  }
  return null;
}

Map<String, dynamic>? extractConsumptionFromLine(String line) {
  final l100kmPatterns = [
    RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]\s*/?\s*100\s*[kK][mM]', caseSensitive: false),
    RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]?\s*/?\s*[hH][oO][oO][kK][mM]', caseSensitive: false),
    RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]\s*/\s*100', caseSensitive: false),
  ];
  for (final pattern in l100kmPatterns) {
    final match = pattern.firstMatch(line);
    if (match != null) {
      final val = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0 && val < 50) return {'value': val, 'unit': 'L/100km'};
    }
  }
  return null;
}

double? extractTotalKilometers(List<String> lines) {
  for (final line in lines) {
    final matches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false).allMatches(line);
    for (final match in matches) {
      final val = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (val != null && val >= 1000) return val;
    }
  }
  return null;
}
