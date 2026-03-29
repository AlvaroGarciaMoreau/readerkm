import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/trip_data.dart';
import '../services/preferences_service.dart';
import '../services/trip_service.dart';
import '../widgets/camera_scan_section.dart';
import '../widgets/trip_card.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _fuelPrice = 1.50;
  String? _email;
  List<TripData> trips = [];
  bool _isLoading = true;
  bool _showEmailWarning = true;

  bool get isEmailMode => _email != null && _email!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    await _loadSettings();
    await _loadTrips();
    
    final prefs = await PreferencesService.isFirstTime();
    if (prefs && mounted) {
      _showEmailDialog();
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSettings() async {
    _fuelPrice = await PreferencesService.loadFuelPrice();
    _email = await PreferencesService.loadEmail();
    if (!isEmailMode) {
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showEmailWarning = false;
          });
        }
      });
    } else {
      _showEmailWarning = false;
    }
  }

  Future<void> _loadTrips() async {
    try {
      final loadedTrips = await TripService.loadTrips(_email);
      if (mounted) {
        setState(() {
          trips = loadedTrips;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar viajes: $e')),
        );
      }
    }
  }

  Future<void> _deleteTrip(int index) async {
    final trip = trips[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar viaje?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TripService.deleteTrip(trip, _email, trips);
        setState(() {
          trips.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaje eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _showFuelPriceDialog() {
    final controller = TextEditingController(text: _fuelPrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precio de Gasolina'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Ej: 1.59',
            suffixText: '€/L',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text.replaceAll(',', '.'));
              if (price != null) {
                await PreferencesService.saveFuelPrice(price);
                if (mounted) {
                  setState(() => _fuelPrice = price);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog() {
    final controller = TextEditingController(text: _email ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu correo para sincronizar tus viajes entre dispositivos:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'tu@email.com',
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              await PreferencesService.saveEmail(email);
              if (mounted) {
                setState(() {
                  _email = email.isNotEmpty ? email : null;
                  if (email.isNotEmpty) _showEmailWarning = false;
                });
                Navigator.pop(context);
                _loadTrips();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _startCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(defaultFuelPrice: _fuelPrice),
        ),
      );
      
      if (result != null && result is TripData) {
        try {
          final savedTrip = await TripService.saveTrip(result, _email);
          setState(() {
            trips.insert(0, savedTrip);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Viaje registrado correctamente')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al guardar: $e')),
            );
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de cámara para escanear')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ReaderKM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showEmailDialog,
            tooltip: 'Configuración',
          ),
          IconButton(
            icon: const Icon(Icons.local_gas_station_outlined),
            onPressed: _showFuelPriceDialog,
            tooltip: 'Precio gasolina',
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: _showCalculatorDialog,
            tooltip: 'Calculadora',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : CustomScrollView(
              slivers: [
                if (!isEmailMode && _showEmailWarning)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Modo local: Configura tu email para no perder tus datos.',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CameraScanSection(
                      fuelPrice: _fuelPrice,
                      onScanPressed: _startCamera,
                    ),
                  ),
                ),

                if (trips.isNotEmpty)
                  ..._buildGroupedTripList(colorScheme)
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              '¡Aún no hay viajes!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pulsa el botón de arriba para registrar tu primer desplazamiento.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
      ),
    );
  }

  void _showCalculatorDialog() {
    final distanceController = TextEditingController();
    final consumptionController = TextEditingController();
    final fuelPriceController = TextEditingController(text: _fuelPrice.toString());
    String unit = 'L/100km';
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Calculadora de Viaje'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Distancia (km)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: consumptionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Consumo', border: OutlineInputBorder()),
                  onChanged: (value) {
                    if (value.contains(',')) {
                      String newValue = value.replaceAll(',', '.');
                      consumptionController.value = consumptionController.value.copyWith(
                        text: newValue,
                        selection: TextSelection.collapsed(offset: newValue.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                  items: ['km/L', 'L/100km'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => unit = newValue!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fuelPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio gasolina (€/L)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    double distance = double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 0;
                    double consumption = double.tryParse(consumptionController.text.replaceAll(',', '.')) ?? 0;
                    double fuelPrice = double.tryParse(fuelPriceController.text.replaceAll(',', '.')) ?? _fuelPrice;

                    double litersPer100Km = unit == 'km/L' ? 100 / consumption : consumption;
                    double litersUsed = (distance / 100) * litersPer100Km;
                    double totalCost = litersUsed * fuelPrice;

                    setState(() {
                      result = {
                        'litersPer100Km': litersPer100Km,
                        'litersUsed': litersUsed,
                        'totalCost': totalCost,
                      };
                    });
                  },
                  child: const Text('CALCULAR'),
                ),
                if (result != null) ...[
                  const SizedBox(height: 20),
                  _buildCalcResult('Litros/100km', '${result!['litersPer100Km'].toStringAsFixed(2)} L'),
                  _buildCalcResult('Litros usados', '${result!['litersUsed'].toStringAsFixed(2)} L'),
                  _buildCalcResult('COSTE TOTAL', '${result!['totalCost'].toStringAsFixed(2)} €', isBold: true),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CERRAR'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTripList(ColorScheme colorScheme) {
    final List<Widget> slivers = [];
    
    // Agrupar por fecha (solo el día)
    Map<String, List<TripData>> groupedTrips = {};
    for (var trip in trips) {
      final dateKey = '${trip.date.year}-${trip.date.month}-${trip.date.day}';
      if (!groupedTrips.containsKey(dateKey)) {
        groupedTrips[dateKey] = [];
      }
      groupedTrips[dateKey]!.add(trip);
    }

    // Ordenar las fechas de más reciente a más antigua
    var sortedKeys = groupedTrips.keys.toList()..sort((a, b) => b.compareTo(a));

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            'Historial de Viajes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );

    for (var dateKey in sortedKeys) {
      final dateTrips = groupedTrips[dateKey]!;
      final firstTripDate = dateTrips.first.date;
      
      // Header de día
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDayHeader(firstTripDate).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(color: colorScheme.primary.withValues(alpha: 0.1), thickness: 1.5)),
              ],
            ),
          ),
        ),
      );

      // Lista de viajes para ese día
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final trip = dateTrips[index];
                // Buscamos el índice original para el borrado
                final originalIndex = trips.indexOf(trip);
                return TripCard(
                  trip: trip,
                  index: originalIndex,
                  onDelete: () => _deleteTrip(originalIndex),
                );
              },
              childCount: dateTrips.length,
            ),
          ),
        ),
      );
    }
    
    return slivers;
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDate = DateTime(date.year, date.month, date.day);

    if (tripDate == today) return 'Hoy';
    if (tripDate == yesterday) return 'Ayer';
    
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final days = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    return '${days[date.weekday]}, ${date.day} de ${months[date.month - 1]}';
  }

  Widget _buildCalcResult(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
              color: isBold ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
