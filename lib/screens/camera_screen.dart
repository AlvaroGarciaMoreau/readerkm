import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../main.dart';
import '../models/trip_data.dart';

class CameraScreen extends StatefulWidget {
  final double defaultFuelPrice;
  
  const CameraScreen({
    super.key, 
    required this.defaultFuelPrice,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron cámaras')),
      );
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Ignored: error initializing camera
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaner'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),
                _buildOverlay(),
                _buildCaptureButton(),
                if (_isProcessing) _buildProcessingIndicator(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Encuadra el cuadro de instrumentos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Asegúrate de que los datos de kilometraje\ny consumo sean visibles',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isProcessing ? null : _captureAndProcess,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing ? Colors.grey : Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
            ),
            child: Icon(
              Icons.camera_alt,
              size: 40,
              color: _isProcessing ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Procesando imagen...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      final String recognizedText = await _processImage(photo.path);
      
      if (mounted) {
        _showResultsDialog(recognizedText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String> _processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  void _showResultsDialog(String recognizedText) {
    final extractedData = _extractVehicleData(recognizedText);
    
    showDialog(
      context: context,
      builder: (context) => ResultsDialog(
        recognizedText: recognizedText,
        extractedData: extractedData,
        defaultFuelPrice: widget.defaultFuelPrice,
        onSave: (tripData) {
          // Cerrar el diálogo primero
          Navigator.pop(context);
          // Luego regresar a la pantalla anterior con los datos
          Navigator.pop(context, tripData);
        },
      ),
    );
  }

  Map<String, dynamic> _extractVehicleData(String text) {
    final Map<String, dynamic> data = {
      'totalKm': null,
      'tripKm': null,
      'consumption': null,
      'travelTime': null, // Nuevo: tiempo de viaje
    };

    print('🔍 ANÁLISIS AVANZADO DEL CUADRO HYUNDAI TUCSON:');
    print('Texto original: "$text"');

    // Dividir el texto en líneas para análisis posicional
    final lines = text.split('\n');
    print('📋 Líneas detectadas: ${lines.length}');
    for (int i = 0; i < lines.length; i++) {
      print('  Línea $i: "${lines[i].trim()}"');
    }

    // BUSCAR DATOS ESPECÍFICOS CON CONTEXTO POSICIONAL
    
    // 1. BUSCAR KILOMETRAJE DE VIAJE (con icono de flecha →)
    print('🎯 Buscando kilometraje de viaje...');
    data['tripKm'] = _extractTripKilometers(lines);
    
    // 2. BUSCAR CONSUMO (km/L con icono de surtidor +)
    print('⛽ Buscando consumo km/L...');
    data['consumption'] = _extractConsumption(lines);
    
    // 3. BUSCAR TIEMPO DE VIAJE (con icono de reloj)
    print('⏱️ Buscando tiempo de viaje...');
    data['travelTime'] = _extractTravelTime(lines);
    
    // 4. BUSCAR KILOMETRAJE TOTAL DEL VEHÍCULO
    print('🚗 Buscando kilometraje total...');
    data['totalKm'] = _extractTotalKilometers(lines);

    print('🎯 RESULTADOS FINALES:');
    print('   - Kilómetros del viaje: ${data['tripKm']} km');
    print('   - Consumo: ${data['consumption']} km/L');
    print('   - Tiempo de viaje: ${data['travelTime']}');
    print('   - Kilómetros totales: ${data['totalKm']} km');
    print('=' * 50);

    return data;
  }

  // Extraer kilómetros de viaje (buscar valores pequeños con contexto de "viaje actual")
  double? _extractTripKilometers(List<String> lines) {
    // Buscar líneas que contengan "viaje", "actual", "trip" o estén cerca de estos contextos
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      
      // Si encuentra contexto de viaje, buscar números en líneas cercanas
      if (line.contains('viaje') || line.contains('actual') || line.contains('trip')) {
        print('🔍 Contexto de viaje encontrado en línea $i: "${lines[i]}"');
        
        // Buscar en las siguientes 3 líneas
        for (int j = i; j < i + 4 && j < lines.length; j++) {
          final kmMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
              .firstMatch(lines[j]);
          
          if (kmMatch != null) {
            final kmStr = kmMatch.group(1)?.replaceAll(',', '.');
            final kmValue = double.tryParse(kmStr ?? '');
            
            // Validar que sea un valor típico de viaje (entre 0.1 y 999 km)
            if (kmValue != null && kmValue >= 0.1 && kmValue < 1000) {
              print('✅ Kilómetros de viaje encontrados: $kmValue km');
              return kmValue;
            }
          }
        }
      }
    }
    
    // Fallback: buscar el menor valor de km que no sea consumo
    final allKmValues = <double>[];
    for (final line in lines) {
      final matches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
          .allMatches(line);
      
      for (final match in matches) {
        final kmStr = match.group(1)?.replaceAll(',', '.');
        final kmValue = double.tryParse(kmStr ?? '');
        if (kmValue != null && kmValue >= 0.1 && kmValue < 1000) {
          allKmValues.add(kmValue);
        }
      }
    }
    
    if (allKmValues.isNotEmpty) {
      allKmValues.sort();
      final tripKm = allKmValues.first; // El más pequeño probablemente es el viaje
      print('✅ Kilómetros de viaje (fallback): $tripKm km');
      return tripKm;
    }
    
    print('❌ No se encontraron kilómetros de viaje');
    return null;
  }

  // Extraer consumo km/L (buscar patrones específicos de consumo)
  double? _extractConsumption(List<String> lines) {
    final consumptionPatterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*km\s*/\s*[lL]', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*km/[lL]', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*[kK][mM]\s*/\s*[lL]', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*[kK][mM]/[lL]', caseSensitive: false),
    ];
    
    for (final line in lines) {
      for (int i = 0; i < consumptionPatterns.length; i++) {
        final match = consumptionPatterns[i].firstMatch(line);
        if (match != null) {
          final consumptionStr = match.group(1)?.replaceAll(',', '.');
          final consumption = double.tryParse(consumptionStr ?? '');
          
          // Validar que sea un valor típico de consumo (entre 5 y 50 km/L para híbridos)
          if (consumption != null && consumption >= 5 && consumption <= 50) {
            print('✅ Consumo encontrado: $consumption km/L (patrón ${i+1})');
            return consumption;
          }
        }
      }
    }
    
    print('❌ No se encontró consumo km/L');
    return null;
  }

  // Extraer tiempo de viaje (formato hh:mm)
  String? _extractTravelTime(List<String> lines) {
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})\s*(?:h[mr]?|hrs?|min)?', caseSensitive: false);
    
    for (final line in lines) {
      final match = timePattern.firstMatch(line);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
        
        // Validar que sea un tiempo razonable (0-23h, 0-59min)
        if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
          final timeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
          print('✅ Tiempo de viaje encontrado: $timeStr');
          return timeStr;
        }
      }
    }
    
    print('❌ No se encontró tiempo de viaje');
    return null;
  }

  // Extraer kilómetros totales del vehículo (valores grandes, típicamente >1000)
  double? _extractTotalKilometers(List<String> lines) {
    final allKmValues = <double>[];
    
    for (final line in lines) {
      final matches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
          .allMatches(line);
      
      for (final match in matches) {
        final kmStr = match.group(1)?.replaceAll(',', '.');
        final kmValue = double.tryParse(kmStr ?? '');
        
        // Buscar valores grandes típicos del odómetro total
        if (kmValue != null && kmValue >= 1000) {
          allKmValues.add(kmValue);
        }
      }
    }
    
    if (allKmValues.isNotEmpty) {
      allKmValues.sort();
      final totalKm = allKmValues.last; // El más grande probablemente es el total
      print('✅ Kilómetros totales encontrados: $totalKm km');
      return totalKm;
    }
    
    print('❌ No se encontraron kilómetros totales');
    return null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}

class ResultsDialog extends StatefulWidget {
  final String recognizedText;
  final Map<String, dynamic> extractedData;
  final double defaultFuelPrice;
  final Function(TripData) onSave;

  const ResultsDialog({
    super.key,
    required this.recognizedText,
    required this.extractedData,
    required this.defaultFuelPrice,
    required this.onSave,
  });

  @override
  State<ResultsDialog> createState() => _ResultsDialogState();
}

class _ResultsDialogState extends State<ResultsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tripKmController = TextEditingController();
  final _consumptionController = TextEditingController();
  late final TextEditingController _fuelPriceController;

  @override
  void initState() {
    super.initState();
    
    // Extraer y asignar los datos automáticamente
    final tripKm = widget.extractedData['tripKm'];
    final consumption = widget.extractedData['consumption'];
    
    _tripKmController.text = tripKm != null ? tripKm.toString() : '';
    _consumptionController.text = consumption != null ? consumption.toString() : '';
    _fuelPriceController = TextEditingController(
      text: widget.defaultFuelPrice.toStringAsFixed(2),
    );
    
    // Añadir listeners para actualizar el cálculo en tiempo real
    _tripKmController.addListener(_updateCalculation);
    _consumptionController.addListener(_updateCalculation);
    _fuelPriceController.addListener(_updateCalculation);
  }
  
  void _updateCalculation() {
    setState(() {
      // El build se ejecutará de nuevo y mostrará el cálculo actualizado
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos Extraídos'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar texto reconocido
                ExpansionTile(
                  title: const Text(
                    'Texto reconocido',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.recognizedText.isEmpty
                            ? 'No se pudo reconocer texto'
                            : widget.recognizedText,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mostrar qué se detectó automáticamente
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🤖 Detección automática:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildDetectionRow(
                        icon: Icons.speed,
                        label: 'Kilómetros',
                        value: widget.extractedData['tripKm'],
                        unit: 'km',
                      ),
                      _buildDetectionRow(
                        icon: Icons.local_gas_station,
                        label: 'Consumo',
                        value: widget.extractedData['consumption'],
                        unit: 'km/L',
                      ),
                      _buildDetectionRowString(
                        icon: Icons.schedule,
                        label: 'Tiempo',
                        value: widget.extractedData['travelTime'],
                        unit: '',
                      ),
                      _buildDetectionRow(
                        icon: Icons.car_crash,
                        label: 'Km totales',
                        value: widget.extractedData['totalKm'],
                        unit: 'km',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campos editables
                const Text(
                  'Confirma o edita los datos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tripKmController,
                  decoration: const InputDecoration(
                    labelText: 'Kilómetros del viaje',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa los kilómetros';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _consumptionController,
                  decoration: const InputDecoration(
                    labelText: 'Consumo',
                    suffixText: 'km/L',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el consumo';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fuelPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio de la gasolina',
                    suffixText: '€/L',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el precio de la gasolina';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCostCalculation(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveTrip,
          child: const Text('Guardar Viaje'),
        ),
      ],
    );
  }

  Widget _buildDetectionRow({
    required IconData icon,
    required String label,
    required double? value,
    required String unit,
  }) {
    final isDetected = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${isDetected ? '$value $unit' : 'No detectado'}',
              style: TextStyle(
                fontSize: 12,
                color: isDetected ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: isDetected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            isDetected ? Icons.check_circle : Icons.error,
            size: 16,
            color: isDetected ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionRowString({
    required IconData icon,
    required String label,
    required String? value,
    required String unit,
  }) {
    final isDetected = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${isDetected ? '$value $unit' : 'No detectado'}',
              style: TextStyle(
                fontSize: 12,
                color: isDetected ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: isDetected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            isDetected ? Icons.check_circle : Icons.error,
            size: 16,
            color: isDetected ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCostCalculation() {
    final tripKm = double.tryParse(_tripKmController.text) ?? 0;
    final consumption = double.tryParse(_consumptionController.text) ?? 0;
    final fuelPrice = double.tryParse(_fuelPriceController.text) ?? 0;
    
    final litersUsed = consumption > 0 ? tripKm / consumption : 0;
    final totalCost = litersUsed * fuelPrice;
    final litersPer100Km = tripKm > 0 ? (litersUsed / tripKm) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Cálculo del Gasto:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text('Litros consumidos: ${litersUsed.toStringAsFixed(2)} L'),
          Text(
            'Costo total: €${totalCost.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Consumo: ${litersPer100Km.toStringAsFixed(2)} L/100km',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      final tripKm = double.parse(_tripKmController.text);
      final consumption = double.parse(_consumptionController.text);
      final fuelPrice = double.parse(_fuelPriceController.text);
      
      final litersUsed = tripKm / consumption;
      final totalCost = litersUsed * fuelPrice;
      final litersPer100Km = (litersUsed / tripKm) * 100;

      // Obtener datos adicionales extraídos
      final travelTime = widget.extractedData['travelTime'] as String?;
      final totalKm = widget.extractedData['totalKm'] as double?;

      final tripData = TripData(
        distance: tripKm,
        consumption: consumption,
        fuelPrice: fuelPrice,
        totalCost: totalCost,
        litersPer100Km: litersPer100Km,
        travelTime: travelTime,
        totalKm: totalKm,
        date: DateTime.now(),
      );

      widget.onSave(tripData);
    }
  }

  @override
  void dispose() {
    _tripKmController.removeListener(_updateCalculation);
    _consumptionController.removeListener(_updateCalculation);
    _fuelPriceController.removeListener(_updateCalculation);
    _tripKmController.dispose();
    _consumptionController.dispose();
    _fuelPriceController.dispose();
    super.dispose();
  }
}
