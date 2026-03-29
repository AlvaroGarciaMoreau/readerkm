import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../main.dart';
import '../models/trip_data.dart';
import '../services/image_upload_service.dart';
import '../services/preferences_service.dart';

// Extraer tiempo de viaje (buscar patrones tipo 1:23, 12:59, etc)
String? _extractTravelTime(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line);
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '');
      final minutes = int.tryParse(match.group(2) ?? '');
      if (hours != null && minutes != null && hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
    }
  }
  return null;
}

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
  String? _lastCapturedImagePath; // ← NUEVO

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Cuadro'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: CameraPreview(_controller!),
                ),
                _buildOverlay(),
                _buildCaptureButton(),
                if (_isProcessing) _buildProcessingIndicator(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Encuadra los datos de consumo y km',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isProcessing ? null : _captureAndProcess,
          child: Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isProcessing ? Colors.grey : Colors.white,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 36,
                color: _isProcessing ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            const SizedBox(height: 24),
            const Text(
              'ANALIZANDO DATOS...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
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
      _lastCapturedImagePath = photo.path;
      
      // Preprocesar antes de OCR para mejorar lectura en baja luz
      final String processedPath = await _preprocessImage(photo.path);
      final String recognizedText = await _processImage(processedPath);
      
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

  Future<String> _preprocessImage(String originalPath) async {
    try {
      final File imageFile = File(originalPath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) return originalPath;

      // 1. Convertir a escala de grises
      image = img.grayscale(image);
      
      // 2. Aumentar contraste significativamente (ayuda mucho en pantallas digitales)
      image = img.contrast(image, contrast: 150); // Valor de 0 a 255
      
      // 3. Opcional: Redimensionar si es muy grande para acelerar proceso (opcional)
      if (image.width > 1200) {
        image = img.copyResize(image, width: 1200);
      }

      final tempDir = await getTemporaryDirectory();
      final String processedPath = p.join(tempDir.path, 'processed_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final List<int> processedBytes = img.encodeJpg(image, quality: 85);
      await File(processedPath).writeAsBytes(processedBytes);
      
      return processedPath;
    } catch (e) {
      debugPrint('Error en preprocesamiento: $e');
      return originalPath; // Fallback a original
    }
  }

  void _showResultsDialog(String recognizedText) {
    assert(() {
      debugPrint('--- OCR TEXT ---');
      debugPrint(recognizedText);
      return true;
    }());
    final extractedData = _extractVehicleData(recognizedText);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultsDialog(
        recognizedText: recognizedText,
        extractedData: extractedData,
        defaultFuelPrice: widget.defaultFuelPrice,
        imagePath: _lastCapturedImagePath,
        onSave: (tripData) {
          Navigator.pop(context);
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
      'travelTime': null,
      'consumptionUnit': 'L/100km',
      'consumptionOriginal': null,
    };

    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Buscar ancla contextual "Viaje actual"
    final anchorPattern = RegExp(r'(viaje|actual|trip|vi.je|act.al)', caseSensitive: false);
    int anchorIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (anchorPattern.hasMatch(lines[i])) {
        anchorIndex = i;
        break;
      }
    }

    // 2. Extraer Consumo (prioridad)
    double? consumptionValue;
    String consumptionUnit = 'L/100km';

    // Intentar extraer consumo cerca del ancla o en todo el texto
    final helperData = _extractConsumptionWithUnit(lines, anchorIndex: anchorIndex);
    if (helperData != null) {
      consumptionValue = helperData['value'];
      consumptionUnit = helperData['unit'];
      data['consumptionOriginal'] = consumptionValue;
    }

    // 3. Extraer Kilómetros de Viaje
    data['tripKm'] = _extractTripKilometers(lines, anchorIndex: anchorIndex);
    
    data['consumption'] = consumptionValue;
    data['consumptionUnit'] = consumptionUnit;
    data['travelTime'] = _extractTravelTime(lines);
    data['totalKm'] = _extractTotalKilometers(lines);

    return data;
  }

  double? _extractTripKilometers(List<String> lines, {int anchorIndex = -1}) {
    // 1. Si tenemos ancla, buscar justo debajo (línea +1 o +2)
    if (anchorIndex != -1) {
      for (int i = anchorIndex + 1; i <= anchorIndex + 4 && i < lines.length; i++) {
        // En los Hyundai/Kia, el primer dato tras el ancla es la distancia
        // Suele tener decimales: "16.8 km"
        final kmMatch = RegExp(r'(\d+[.,]\d+)\s*k[mr]n?', caseSensitive: false).firstMatch(lines[i]);
        if (kmMatch != null) {
          final kmStr = kmMatch.group(1)?.replaceAll(',', '.');
          final val = double.tryParse(kmStr ?? '');
          if (val != null && val >= 0.1 && val < 500) return val;
        }
      }
    }

    // 2. Fallback: búsqueda general con contexto
    final contextPattern = RegExp(r'(viaje|actual|trip|vi.je|act.al)', caseSensitive: false);
    for (int i = 0; i < lines.length; i++) {
      if (contextPattern.hasMatch(lines[i])) {
        for (int j = i; j < i + 4 && j < lines.length; j++) {
          final kmMatch = RegExp(r'(\d+[.,]\d+)\s*k[mr]n?', caseSensitive: false).firstMatch(lines[j]);
          if (kmMatch != null) {
            final kmStr = kmMatch.group(1)?.replaceAll(',', '.');
            final val = double.tryParse(kmStr ?? '');
            if (val != null && val >= 0.1 && val < 500) return val;
          }
        }
      }
    }

    // 3. Último recurso: cualquier valor con decimales entre 0.1 y 300 km
    final allKmValues = <double>[];
    for (final line in lines) {
      final matches = RegExp(r'(\d+[.,]\d+)\s*k[mr]n?', caseSensitive: false).allMatches(line);
      for (final m in matches) {
        final valStr = m.group(1);
        if (valStr != null) {
          final val = double.tryParse(valStr.replaceAll(',', '.'));
          if (val != null && val >= 0.1 && val < 300) allKmValues.add(val);
        }
      }
    }

    if (allKmValues.isNotEmpty) {
      allKmValues.sort();
      return allKmValues.first;
    }
    return null;
  }

  Map<String, dynamic>? _extractConsumptionWithUnit(List<String> lines, {int anchorIndex = -1}) {
    // 1. Si hay ancla, buscar en las líneas siguientes (típicamente línea +3 o +4)
    if (anchorIndex != -1) {
      for (int i = anchorIndex + 1; i <= anchorIndex + 5 && i < lines.length; i++) {
        final result = _extractConsumptionFromLine(lines[i]);
        if (result != null) return result;
      }
    }

    // 2. Búsqueda exhaustiva por todo el texto
    for (final line in lines) {
      final result = _extractConsumptionFromLine(line);
      if (result != null) return result;
    }

    return null;
  }

  Map<String, dynamic>? _extractConsumptionFromLine(String line) {
    // Patrones para L/100km (muy robustos para errores OCR)
    final l100kmPatterns = [
      // Estándar: "4.1 L/100km"
      RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]\s*/?\s*100\s*[kK][mM]', caseSensitive: false),
      // Error común "hookm": "4.1 hookm" o "4.1 L/hookm"
      RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]?\s*/?\s*[hH][oO][oO][kK][mM]', caseSensitive: false),
      // Sin unidad final: "4.1 L/100"
      RegExp(r'(\d+[.,]?\d*)\s*[lL1i!|]\s*/\s*100', caseSensitive: false),
    ];
    
    for (final pattern in l100kmPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final valStr = match.group(1)?.replaceAll(',', '.');
        final val = double.tryParse(valStr ?? '');
        if (val != null && val > 0 && val < 50) { // Consumo realista
          return {'value': val, 'unit': 'L/100km'};
        }
      }
    }

    // Patrones para km/L
    final kmLPatterns = [
      RegExp(r'(\d+[.,]?\d*)\s*[kK][mM]\s*/\s*[lL1i!|]', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)\s*[kK][mM]/[lL1i!|]', caseSensitive: false),
    ];

    for (final pattern in kmLPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final valStr = match.group(1)?.replaceAll(',', '.');
        final val = double.tryParse(valStr ?? '');
        if (val != null && val > 0 && val < 50) {
          return {'value': val, 'unit': 'km/L'};
        }
      }
    }

    return null;
  }

  double? _extractTotalKilometers(List<String> lines) {
    final allKmValues = <double>[];
    for (final line in lines) {
      final matches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
          .allMatches(line);
      for (final match in matches) {
        final kmStr = match.group(1)?.replaceAll(',', '.');
        final kmValue = double.tryParse(kmStr ?? '');
        if (kmValue != null && kmValue >= 1000) {
          allKmValues.add(kmValue);
        }
      }
    }
    if (allKmValues.isNotEmpty) {
      allKmValues.sort();
      return allKmValues.last;
    }
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
  final String? imagePath;
  final Function(TripData) onSave;

  const ResultsDialog({
    super.key,
    required this.recognizedText,
    required this.extractedData,
    required this.defaultFuelPrice,
    this.imagePath,
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
  String _manualConsumptionUnit = 'km/L';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tripKm = widget.extractedData['tripKm'];
    final consumption = widget.extractedData['consumption'];
    final consumptionUnit = widget.extractedData['consumptionUnit'] ?? 'L/100km';
    
    _tripKmController.text = tripKm != null ? tripKm.toString() : '';
    _consumptionController.text = consumption != null ? consumption.toStringAsFixed(2) : '';
    _fuelPriceController = TextEditingController(
      text: widget.defaultFuelPrice.toStringAsFixed(2),
    );
    _manualConsumptionUnit = (consumption != null && consumption > 0) 
        ? consumptionUnit 
        : 'L/100km';
    
    _tripKmController.addListener(_updateCalculation);
    _consumptionController.addListener(_updateCalculation);
    _fuelPriceController.addListener(_updateCalculation);
  }

  void _updateCalculation() => setState(() {});

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar Datos',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa que la detección automática sea correcta.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OCR Insight Pill
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildDetectionItem(Icons.route, 'KM Viaje', widget.extractedData['tripKm']),
                      const Divider(height: 12),
                      _buildDetectionItem(Icons.local_gas_station, 'Consumo detectado', widget.extractedData['consumption'], isConsumption: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Input Fields (Larger for presbyopia)
                _buildFieldLabel('DISTANCIA RECORRIDA (km)'),
                TextFormField(
                  controller: _tripKmController,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Ej: 120.5'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 20),
                
                _buildFieldLabel('CONSUMO MEDIO'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _consumptionController,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Ej: 5.4'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _manualConsumptionUnit,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'km/L', child: Text('km/L', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'L/100km', child: Text('L/100km', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) => setState(() => _manualConsumptionUnit = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildFieldLabel('PRECIO GASOLINA (€/L)'),
                TextFormField(
                  controller: _fuelPriceController,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Ej: 1.59'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                
                const SizedBox(height: 32),
                
                // RESULTS SUMMARY
                _buildResultPill(),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('GUARDAR VIAJE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCELAR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Colors.grey.shade600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  Widget _buildDetectionItem(IconData icon, String label, dynamic value, {bool isConsumption = false}) {
    final detected = value != null;
    return Row(
      children: [
        Icon(icon, size: 16, color: detected ? Colors.blue.shade700 : Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(
          detected ? (isConsumption ? '${widget.extractedData['consumptionOriginal'] ?? value.toStringAsFixed(1)} ${widget.extractedData['consumptionUnit']}' : '${value.toStringAsFixed(1)} km') : 'No detectado',
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w900, 
            color: detected ? Colors.blue.shade900 : Colors.red.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildResultPill() {
    final tripKm = double.tryParse(_tripKmController.text.replaceAll(',', '.')) ?? 0;
    final consumption = double.tryParse(_consumptionController.text.replaceAll(',', '.')) ?? 0;
    final fuelPrice = double.tryParse(_fuelPriceController.text.replaceAll(',', '.')) ?? 0;
    final isL100km = _manualConsumptionUnit == 'L/100km';

    double litersPer100Km = 0;
    if (isL100km) {
      litersPer100Km = consumption;
    } else {
      litersPer100Km = consumption > 0 ? 100 / consumption : 0;
    }
    
    final totalCost = (tripKm / 100) * litersPer100Km * fuelPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        children: [
          const Text('COSTE ESTIMADO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green)),
          const SizedBox(height: 4),
          Text(
            '${totalCost.toStringAsFixed(2)} €',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final tripKm = double.parse(_tripKmController.text.replaceAll(',', '.'));
      final consumption = double.parse(_consumptionController.text.replaceAll(',', '.'));
      final fuelPrice = double.parse(_fuelPriceController.text.replaceAll(',', '.'));
      final isL100km = _manualConsumptionUnit == 'L/100km';

      double litersPer100Km = isL100km ? consumption : (consumption > 0 ? 100 / consumption : 0);
      double totalCost = (tripKm / 100) * litersPer100Km * fuelPrice;

      final travelTime = widget.extractedData['travelTime'] as String?;
      final totalKm = widget.extractedData['totalKm'] as double?;

      String? imageUrl;
      String? imageFilename;

      if (widget.imagePath != null) {
        final email = await PreferencesService.loadEmail();
        if (email != null && email.isNotEmpty) {
          final uploadResult = await ImageUploadService.uploadTripImage(
            imagePath: widget.imagePath!,
            email: email,
          ).timeout(const Duration(seconds: 45), onTimeout: () => null);

          if (uploadResult != null && uploadResult['success'] == true) {
            imageUrl = uploadResult['url'];
            imageFilename = uploadResult['filename'];
          }
        }
      }

      final tripData = TripData(
        distance: tripKm,
        consumption: consumption,
        consumptionUnit: _manualConsumptionUnit,
        fuelPrice: fuelPrice,
        totalCost: totalCost,
        litersPer100Km: litersPer100Km,
        travelTime: travelTime,
        totalKm: totalKm,
        date: DateTime.now(),
        imageUrl: imageUrl,
        imageFilename: imageFilename,
      );

      if (mounted) {
        widget.onSave(tripData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
