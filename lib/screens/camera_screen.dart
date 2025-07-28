import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../main.dart';
import 'home_screen.dart';

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

  Map<String, double?> _extractVehicleData(String text) {
    final Map<String, double?> data = {
      'totalKm': null,
      'tripKm': null,
      'consumption': null,
    };

    print('🔍 ANÁLISIS DEL TEXTO OCR:');
    print('Texto original: "$text"');

    // Limpiar el texto
    final cleanText = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    print('Texto limpio: "$cleanText"');
    
    // BUSCAR CONSUMO (km/L) CON PATRONES MEJORADOS
    List<RegExp> consumptionPatterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*km\s*/\s*[lL]', caseSensitive: false), // 15.8 km/L
      RegExp(r'(\d+(?:[.,]\d+)?)\s*km/[lL]', caseSensitive: false), // 15.8 km/L (sin espacios)
      RegExp(r'(\d+(?:[.,]\d+)?)\s*[kK][mM]\s*/\s*[lL]', caseSensitive: false), // 15.8 KM/L
      RegExp(r'(\d+(?:[.,]\d+)?)\s*[kK][mM]/[lL]', caseSensitive: false), // 15.8 KM/L
    ];
    
    print('🔥 Buscando consumo (km/L)...');
    for (int i = 0; i < consumptionPatterns.length; i++) {
      final pattern = consumptionPatterns[i];
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final consumptionStr = match.group(1)?.replaceAll(',', '.');
        data['consumption'] = double.tryParse(consumptionStr ?? '');
        print('✅ CONSUMO ENCONTRADO (patrón ${i+1}): "${match.group(0)}" → ${data['consumption']} km/L');
        break;
      } else {
        print('❌ Patrón ${i+1} no coincide');
      }
    }
    
    // BUSCAR KILÓMETROS
    print('🔥 Buscando kilómetros...');
    final kmMatches = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
        .allMatches(cleanText);
    
    List<double> kmValues = [];
    for (final match in kmMatches) {
      final kmStr = match.group(1)?.replaceAll(',', '.');
      final kmValue = double.tryParse(kmStr ?? '');
      if (kmValue != null && kmValue != data['consumption']) {
        kmValues.add(kmValue);
        print('📏 Km encontrado: "${match.group(0)}" → $kmValue km');
      }
    }
    
    // ASIGNAR KILÓMETROS DE MANERA INTELIGENTE
    if (kmValues.isNotEmpty) {
      kmValues.sort();
      print('📊 Valores km ordenados: $kmValues');
      
      // Separar valores pequeños (probable viaje) de grandes (probable total)
      final smallValues = kmValues.where((v) => v < 1000).toList();
      final largeValues = kmValues.where((v) => v >= 1000).toList();
      
      if (smallValues.isNotEmpty) {
        data['tripKm'] = smallValues.last; // El más grande de los pequeños
        print('✅ VIAJE ASIGNADO: ${data['tripKm']} km (del rango pequeño)');
      }
      if (largeValues.isNotEmpty) {
        data['totalKm'] = largeValues.first; // El más pequeño de los grandes
        print('✅ TOTAL ASIGNADO: ${data['totalKm']} km (del rango grande)');
      }
    }

    print('🎯 RESULTADOS FINALES:');
    print('   - Kilómetros del viaje: ${data['tripKm']} km');
    print('   - Consumo: ${data['consumption']} km/L');
    print('   - Kilómetros totales: ${data['totalKm']} km');
    print('=' * 50);

    return data;
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
  final Map<String, double?> extractedData;
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

  Widget _buildCostCalculation() {
    final tripKm = double.tryParse(_tripKmController.text) ?? 0;
    final consumption = double.tryParse(_consumptionController.text) ?? 0;
    final fuelPrice = double.tryParse(_fuelPriceController.text) ?? 0;
    
    final litersUsed = consumption > 0 ? tripKm / consumption : 0;
    final totalCost = litersUsed * fuelPrice;

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

      final tripData = TripData(
        distance: tripKm,
        consumption: consumption,
        fuelPrice: fuelPrice,
        totalCost: totalCost,
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
