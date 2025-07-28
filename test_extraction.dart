// Test para verificar la extracción de datos
// Basado en la imagen del cuadro de instrumentos

void main() {
  // Simulamos el texto que el OCR podría reconocer de tu imagen
  final testTexts = [
    'P 245km Viaje actual 16.9km 0:18h:m 15.8km/L CHG ECO PWR 32°C 1113km',
    '245km 16.9km 15.8km/L 1113km',
    'P 245 km Viaje actual 16.9 km 15.8 km/L 1113 km',
    '16.9km 15.8km/L', // Caso mínimo
    'Viaje actual: 16.9 km, Consumo: 15.8 km/L',
  ];
  
  print('=== TESTING EXTRACTION PATTERNS ===');
  
  for (int i = 0; i < testTexts.length; i++) {
    print('\n--- Test ${i + 1} ---');
    print('Input: "${testTexts[i]}"');
    
    final result = extractVehicleDataTest(testTexts[i]);
    
    print('Kilómetros del viaje: ${result['tripKm']}');
    print('Consumo: ${result['consumption']}');
    print('Kilómetros totales: ${result['totalKm']}');
    
    // Verificar si los resultados esperados son correctos
    final expected = (result['tripKm'] == 16.9 && result['consumption'] == 15.8);
    print('✅ Expected results: ${expected ? "PASS" : "FAIL"}');
  }
}

Map<String, double?> extractVehicleDataTest(String text) {
  final Map<String, double?> data = {
    'totalKm': null,
    'tripKm': null,
    'consumption': null,
  };

  // Limpiar el texto
  final cleanText = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
  
  // Buscar consumo (km/L)
  final consumptionPatterns = [
    RegExp(r'(\d+(?:[.,]\d+)?)\s*km\s*/\s*[lL]', caseSensitive: false),
    RegExp(r'(\d+(?:[.,]\d+)?)\s*km/[lL]', caseSensitive: false),
  ];
  
  for (final pattern in consumptionPatterns) {
    final match = pattern.firstMatch(cleanText);
    if (match != null) {
      final consumptionStr = match.group(1)?.replaceAll(',', '.');
      data['consumption'] = double.tryParse(consumptionStr ?? '');
      break;
    }
  }
  
  // Buscar kilómetros
  final kmMatches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
      .allMatches(cleanText);
  
  List<double> kmValues = [];
  for (final match in kmMatches) {
    final kmStr = match.group(1)?.replaceAll(',', '.');
    final kmValue = double.tryParse(kmStr ?? '');
    if (kmValue != null && kmValue != data['consumption']) {
      kmValues.add(kmValue);
    }
  }
  
  if (kmValues.isNotEmpty) {
    kmValues.sort();
    data['tripKm'] = kmValues.first; // El más pequeño
    if (kmValues.length > 1) {
      data['totalKm'] = kmValues.last; // El más grande
    }
  }
  
  return data;
}
