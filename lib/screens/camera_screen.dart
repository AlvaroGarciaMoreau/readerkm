import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
      _lastCapturedImagePath = photo.path; // ← NUEVO: Guardar path
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
    // DEBUG: Log OCR text for troubleshooting
    assert(() {
      // Solo en modo debug
      debugPrint('--- TEXTO OCR COMPLETO ---');
      debugPrint(recognizedText);
      debugPrint('-------------------------');
      final lines = recognizedText.split('\n');
      for (var i = 0; i < lines.length; i++) {
        debugPrint('Línea $i: ${lines[i]}');
      }
      return true;
    }());
    final extractedData = _extractVehicleData(recognizedText);
    
    showDialog(
      context: context,
      builder: (context) => ResultsDialog(
        recognizedText: recognizedText,
        extractedData: extractedData,
        defaultFuelPrice: widget.defaultFuelPrice,
        imagePath: _lastCapturedImagePath, // ← NUEVO: Pasar path de imagen
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
      'travelTime': null,
      'consumptionUnit': 'L/100km', // por defecto
      'consumptionOriginal': null, // valor original detectado
    };

    // Dividir el texto en líneas para análisis posicional
    final lines = text.split('\n');

    // Detectar si el consumo está en km/L o L/100km (más robusto)
    final l100kmPatterns = [
      RegExp(r'(\d+[.,]?\d*)\s*[lL]\s*/\s*100\s*[kK][mM]', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)[lL]/?100[kK][mM]', caseSensitive: false),
      // Detectar cualquier letra antes de 'ookm' (errores de OCR como Yookm, hookm, lookm, etc)
      RegExp(r'(\d+[.,]?\d*)[a-zA-Z]ookm', caseSensitive: false),
    ];

    double? consumptionValue;
    String consumptionUnit = 'L/100km';

    // Buscar consumo en cada línea
    for (final line in lines) {
      // Buscar L/100km
      for (final l100kmPattern in l100kmPatterns) {
        final l100kmMatch = l100kmPattern.firstMatch(line);
        if (l100kmMatch != null) {
          final l100kmStr = l100kmMatch.group(1)?.replaceAll(',', '.');
          final l100km = double.tryParse(l100kmStr ?? '');
          if (l100km != null && l100km > 0) {
            consumptionValue = l100km;
            consumptionUnit = 'L/100km';
            data['consumptionOriginal'] = l100km;
            break;
          }
        }
      }
      if (consumptionValue != null) break;
      // Buscar km/L
      final kmLPatterns = [
        RegExp(r'(\d+[.,]?\d*)\s*[kK][mM]\s*/\s*[lL]', caseSensitive: false),
        RegExp(r'(\d+[.,]?\d*)[kK][mM]/?[lL]', caseSensitive: false),
  // Permitir valores como 'xx.x km/' y asumir km/L
  RegExp(r'(\d+[.,]?\d*)\s*[kK][mM]\s*/', caseSensitive: false),
      ];
      for (final kmLPattern in kmLPatterns) {
        final kmLMatch = kmLPattern.firstMatch(line);
        if (kmLMatch != null) {
          final kmLStr = kmLMatch.group(1)?.replaceAll(',', '.');
          final kmL = double.tryParse(kmLStr ?? '');
          if (kmL != null && kmL > 0) {
            consumptionValue = kmL;
            consumptionUnit = 'km/L';
            data['consumptionOriginal'] = kmL;
            break;
          }
        }
      }
      if (consumptionValue != null) break;
      // Fallback: buscar patrones simples pegados
      final fallbackL100 = RegExp(r'(\d+[.,]\d+)[l1iI][/\\]?[1iIlL][0Oo]{2}[kK][mM]').firstMatch(line);
      if (fallbackL100 != null) {
        final l100kmStr = fallbackL100.group(1)?.replaceAll(',', '.');
        final l100km = double.tryParse(l100kmStr ?? '');
        if (l100km != null && l100km > 0) {
          consumptionValue = l100km;
          consumptionUnit = 'L/100km';
          data['consumptionOriginal'] = l100km;
          break;
        }
      }
      final fallbackKmL = RegExp(r'(\d+[.,]\d+)[kK][mM][/\\]?[lL1iI]').firstMatch(line);
      if (fallbackKmL != null) {
        final kmLStr = fallbackKmL.group(1)?.replaceAll(',', '.');
        final kmL = double.tryParse(kmLStr ?? '');
        if (kmL != null && kmL > 0) {
          consumptionValue = kmL;
          consumptionUnit = 'km/L';
          data['consumptionOriginal'] = kmL;
          break;
        }
      }
    }

    // Si no se detectó con los patrones nuevos, usar el método anterior
    if (consumptionValue == null) {
      consumptionValue = _extractConsumption(lines);
      consumptionUnit = 'km/L';
      data['consumptionOriginal'] = consumptionValue;
    }

    // BUSCAR DATOS ESPECÍFICOS CON CONTEXTO POSICIONAL
    data['tripKm'] = _extractTripKilometers(lines);
    data['consumption'] = consumptionValue;
    data['consumptionUnit'] = consumptionUnit;
    data['travelTime'] = _extractTravelTime(lines);
    data['totalKm'] = _extractTotalKilometers(lines);

    return data;
  }

  // Extraer kilómetros de viaje (buscar valores pequeños con contexto de "viaje actual")
  double? _extractTripKilometers(List<String> lines) {
    // Buscar líneas que contengan "viaje", "actual", "trip" o estén cerca de estos contextos
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      // Si encuentra contexto de viaje, buscar números en líneas cercanas
      if (line.contains('viaje') || line.contains('actual') || line.contains('trip')) {
        // Buscar en las siguientes 3 líneas
        for (int j = i; j < i + 4 && j < lines.length; j++) {
          final kmMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*km(?!\s*/)', caseSensitive: false)
              .firstMatch(lines[j]);
          if (kmMatch != null) {
            final kmStr = kmMatch.group(1)?.replaceAll(',', '.');
            final kmValue = double.tryParse(kmStr ?? '');
            // Validar que sea un valor típico de viaje (entre 0.1 y 999 km)
            if (kmValue != null && kmValue >= 0.1 && kmValue < 1000) {
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
      return tripKm;
    }
    return null;
  }

  // Extraer consumo km/L (buscar patrones específicos de consumo)
  double? _extractConsumption(List<String> lines) {
    final l100kmPatterns = [
      RegExp(r'(\d+[.,]?\d*)\s*[lL]\s*/\s*100\s*[kK][mM]', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)[lL]/?100[kK][mM]', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)hookm', caseSensitive: false),
    ];
    for (final line in lines) {
      for (final l100kmPattern in l100kmPatterns) {
        final match = l100kmPattern.firstMatch(line);
        if (match != null) {
          final l100kmStr = match.group(1)?.replaceAll(',', '.');
          final l100km = double.tryParse(l100kmStr ?? '');
          if (l100km != null && l100km > 0) {
            return 100 / l100km;
          }
        }
      }
      final kmLPattern = RegExp(r'(\d+[.,]?\d*)\s*[kK][mM]\s*/\s*[lL]', caseSensitive: false);
      final kmLMatch = kmLPattern.firstMatch(line);
      if (kmLMatch != null) {
        final kmLStr = kmLMatch.group(1)?.replaceAll(',', '.');
        final kmL = double.tryParse(kmLStr ?? '');
        if (kmL != null && kmL > 0) {
          return kmL;
        }
      }
    }
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
      return totalKm;
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
  final String? imagePath; // ← NUEVO
  final Function(TripData) onSave;

  const ResultsDialog({
    super.key,
    required this.recognizedText,
    required this.extractedData,
    required this.defaultFuelPrice,
    this.imagePath, // ← NUEVO
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
    // Extraer y asignar los datos automáticamente
    final tripKm = widget.extractedData['tripKm'];
    final consumption = widget.extractedData['consumption'];
    final consumptionUnit = widget.extractedData['consumptionUnit'] ?? 'L/100km';
    _tripKmController.text = tripKm != null ? tripKm.toString() : '';
    _consumptionController.text = consumption != null ? consumption.toStringAsFixed(2) : '';
    _fuelPriceController = TextEditingController(
      text: widget.defaultFuelPrice.toStringAsFixed(2),
    );
    // Si el consumo no fue reconocido, dejar elegir la unidad manualmente
    if (widget.extractedData['consumption'] == null) {
      _manualConsumptionUnit = 'L/100km';
    } else {
      _manualConsumptionUnit = consumptionUnit;
    }
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _consumptionController,
                        decoration: InputDecoration(
                          labelText: 'Consumo',
                          suffixText: _manualConsumptionUnit,
                          border: const OutlineInputBorder(),
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
                    ),
                    if (widget.extractedData['consumption'] == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButton<String>(
                          value: _manualConsumptionUnit,
                          items: const [
                            DropdownMenuItem(value: 'km/L', child: Text('km/L')),
                            DropdownMenuItem(value: 'L/100km', child: Text('L/100km')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _manualConsumptionUnit = value;
                              });
                            }
                          },
                        ),
                      ),
                  ],
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
          onPressed: _isSaving ? null : _saveTrip,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar Viaje'),
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
    String displayValue = isDetected ? value.toStringAsFixed(2) : 'No detectado';
    if (label == 'Consumo' && widget.extractedData['consumptionUnit'] == 'L/100km' && widget.extractedData['consumptionOriginal'] != null) {
      displayValue = '${widget.extractedData['consumptionOriginal']} L/100km';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${isDetected ? displayValue : 'No detectado'}',
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
    final isL100km = _manualConsumptionUnit == 'L/100km';
    double litersUsed = 0;
    double totalCost = 0;
    double litersPer100Km = 0;
    double kmPerLiter = 0;
    if (isL100km && consumption > 0) {
      litersUsed = (tripKm * consumption) / 100;
      totalCost = litersUsed * fuelPrice;
      litersPer100Km = consumption;
      kmPerLiter = consumption > 0 ? 100 / consumption : 0;
    } else if (consumption > 0) {
      litersUsed = tripKm / consumption;
      totalCost = litersUsed * fuelPrice;
      kmPerLiter = consumption;
      litersPer100Km = tripKm > 0 ? (litersUsed / tripKm) * 100 : 0;
    }

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
            isL100km
                ? 'Consumo: ${litersPer100Km.toStringAsFixed(2)} L/100km (${kmPerLiter.toStringAsFixed(2)} km/L)'
                : 'Consumo: ${kmPerLiter.toStringAsFixed(2)} km/L (${litersPer100Km.toStringAsFixed(2)} L/100km)',
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



  void _saveTrip() async {
    if (_isSaving) return;
    
    try {
      if (!_formKey.currentState!.validate()) return;
      
      if (!mounted) return;
      setState(() => _isSaving = true);
      
      final tripKm = double.parse(_tripKmController.text);
      final consumption = double.parse(_consumptionController.text);
      final fuelPrice = double.parse(_fuelPriceController.text);
      final isL100km = _manualConsumptionUnit == 'L/100km';
      
      double litersUsed = 0;
      double totalCost = 0;
      double litersPer100Km = 0;
      if (isL100km && consumption > 0) {
        litersUsed = (tripKm * consumption) / 100;
        totalCost = litersUsed * fuelPrice;
        litersPer100Km = consumption;
      } else if (consumption > 0) {
        litersUsed = tripKm / consumption;
        totalCost = litersUsed * fuelPrice;
        litersPer100Km = tripKm > 0 ? (litersUsed / tripKm) * 100 : 0;
      }

      final travelTime = widget.extractedData['travelTime'] as String?;
      final totalKm = widget.extractedData['totalKm'] as double?;

      String? imageUrl;
      String? imageFilename;

      // Intentar subir imagen si hay path y email configurado
      if (widget.imagePath != null && mounted) {
        try {
          
          final email = await PreferencesService.loadEmail();
          
          if (email != null && email.isNotEmpty && mounted) {
            // Mostrar indicador de carga de forma segura
            try {
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📸 Subiendo imagen...'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              // Ignore errors when showing snackbar
            }
            
            
            // Agregar timeout para evitar colgarse
            final uploadResult = await ImageUploadService.uploadTripImage(
              imagePath: widget.imagePath!,
              email: email,
            ).timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                return null;
              },
            );
            
            
            if (mounted && uploadResult != null && uploadResult['success'] == true) {
              imageUrl = uploadResult['url'];
              imageFilename = uploadResult['filename'];
              
              
              try {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Imagen guardada en la nube'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Ignore errors when showing snackbar
              }
            } else {
              try {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Viaje guardado, pero imagen no se pudo subir'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Ignore errors when showing snackbar
              }
            }
          } else {
          }
        } catch (e) {
          try {
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Error subiendo imagen: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e2) {
            // Ignore errors when showing snackbar
          }
        }
      } else {
      }

      if (!mounted) return;

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
        setState(() => _isSaving = false);
        widget.onSave(tripData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        try {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error guardando viaje: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } catch (e2) {
          // Ignore errors when showing snackbar
        }
      }
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
