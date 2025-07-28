import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TripData> trips = [];
  double _fuelPrice = 1.50; // Precio por defecto

  @override
  void initState() {
    super.initState();
    _loadFuelPrice();
    _loadTrips(); // Cargar viajes guardados
  }

  Future<void> _loadFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fuelPrice = prefs.getDouble('fuel_price') ?? 1.50;
    });
  }

  Future<void> _saveFuelPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fuel_price', price);
    setState(() {
      _fuelPrice = price;
    });
  }

  // Cargar viajes guardados desde SharedPreferences
  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList('saved_trips') ?? [];
    
    setState(() {
      trips = tripsJson.map((tripString) {
        final tripMap = jsonDecode(tripString) as Map<String, dynamic>;
        return TripData.fromJson(tripMap);
      }).toList();
    });
  }

  // Guardar viajes en SharedPreferences
  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = trips.map((trip) => jsonEncode(trip.toJson())).toList();
    await prefs.setStringList('saved_trips', tripsJson);
  }

  // Eliminar un viaje individual
  void _deleteTrip(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Viaje'),
          content: const Text('¿Estás seguro de que quieres eliminar este viaje?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  trips.removeAt(index);
                });
                
                // Guardar cambios en SharedPreferences
                _saveTrips();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Viaje eliminado'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReaderKM'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_gas_station),
            onPressed: _showFuelPriceDialog,
            tooltip: 'Configurar precio de gasolina',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Escanea el cuadro de instrumentos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Apunta la cámara a los datos de kilometraje y consumo de tu vehículo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Escanear Cuadro'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Precio: €${_fuelPrice.toStringAsFixed(2)}/L',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (trips.isNotEmpty) ...[
              const Text(
                'Historial de Viajes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final dateFormat = '${trip.date.day}/${trip.date.month}/${trip.date.year}';
                    final timeFormat = '${trip.date.hour.toString().padLeft(2, '0')}:${trip.date.minute.toString().padLeft(2, '0')}';
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${trip.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Consumo: ${trip.consumption.toStringAsFixed(2)} km/L\n'
                          'Precio: €${trip.fuelPrice.toStringAsFixed(2)}/L\n'
                          '$dateFormat a las $timeFormat',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '€${trip.totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteTrip(index),
                              tooltip: 'Eliminar viaje',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay viajes registrados.\nComienza escaneando el cuadro de tu vehículo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: trips.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showClearHistoryDialog,
              backgroundColor: Colors.red,
              tooltip: 'Limpiar historial',
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _startCamera() async {
    // Solicitar permisos de cámara
    final cameraPermission = await Permission.camera.request();
    
    if (cameraPermission.isGranted) {
      final result = await Navigator.push<TripData>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(defaultFuelPrice: _fuelPrice),
        ),
      );
      
      if (result != null) {
        setState(() {
          trips.add(result);
        });
        
        // Guardar viajes en SharedPreferences
        _saveTrips();
        
        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Viaje guardado: ${result.distance.toStringAsFixed(1)} km - €${result.totalCost.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Cámara'),
        content: const Text(
          'Esta aplicación necesita acceso a la cámara para escanear el cuadro de instrumentos de tu vehículo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Historial'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los viajes guardados? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                trips.clear();
              });
              
              // Guardar cambios (lista vacía) en SharedPreferences
              _saveTrips();
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historial limpiado'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }

  void _showFuelPriceDialog() {
    final TextEditingController controller = TextEditingController(
      text: _fuelPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Precio de Gasolina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Precio actual: €${_fuelPrice.toStringAsFixed(2)}/L',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Nuevo precio',
                suffixText: '€/L',
                border: OutlineInputBorder(),
                hintText: '1.50',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Este precio se usará por defecto en todos los cálculos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                _saveFuelPrice(newPrice);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Precio actualizado: €${newPrice.toStringAsFixed(2)}/L',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un precio válido'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class TripData {
  final double distance;
  final double consumption;
  final double fuelPrice;
  final double totalCost;
  final DateTime date;

  TripData({
    required this.distance,
    required this.consumption,
    required this.fuelPrice,
    required this.totalCost,
    required this.date,
  });

  // Convertir a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'consumption': consumption,
      'fuelPrice': fuelPrice,
      'totalCost': totalCost,
      'date': date.millisecondsSinceEpoch,
    };
  }

  // Crear desde JSON al cargar de SharedPreferences
  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      distance: json['distance'].toDouble(),
      consumption: json['consumption'].toDouble(),
      fuelPrice: json['fuelPrice'].toDouble(),
      totalCost: json['totalCost'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }
}
