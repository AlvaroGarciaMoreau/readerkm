import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_data.dart';
import '../services/preferences_service.dart';
import '../widgets/camera_scan_section.dart';
import '../widgets/trip_card.dart';
import '../utils/dialog_utils.dart';
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
    _loadTrips();
  }

  Future<void> _loadFuelPrice() async {
    final price = await PreferencesService.loadFuelPrice();
    setState(() {
      _fuelPrice = price;
    });
  }

  Future<void> _saveFuelPrice(double price) async {
    await PreferencesService.saveFuelPrice(price);
    setState(() {
      _fuelPrice = price;
    });
  }

  Future<String?> _getUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('user_uuid');
    if (uuid == null || uuid.isEmpty) {
      // Generar y guardar un nuevo uuid
      uuid = UniqueKey().toString();
      await prefs.setString('user_uuid', uuid);
    }
    return uuid;
  }

  Future<void> _loadTrips() async {
    try {
      final url = Uri.parse('https://www.moreausoft.com/ReaderKM/listar_viajes.php');
      final userUuid = await _getUserUuid();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_uuid': userUuid}),
      );
      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        if (resp['success'] == true && resp['viajes'] != null) {
          setState(() {
            trips = (resp['viajes'] as List).map((json) => TripData.fromJson(json)).toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar viajes: ${resp['error'] ?? response.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar viajes: \n${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red al cargar viajes: $e')),
      );
    }
  }

  Future<void> _deleteTrip(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar viaje?'),
        content: const Text('¿Estás seguro de que deseas eliminar este viaje? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final trip = trips[index];
    final url = Uri.parse('https://www.moreausoft.com/ReaderKM/borrar_viaje.php');
    try {
      final userUuid = await _getUserUuid();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': trip.id, 'user_uuid': userUuid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Viaje eliminado'),
              backgroundColor: Colors.orange,
            ),
          );
          await _loadTrips(); // Recargar la lista desde el backend
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al borrar: \n${data['error'] ?? response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de red al borrar: \n${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de red al borrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            CameraScanSection(
              fuelPrice: _fuelPrice,
              onScanPressed: _startCamera,
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
                    return TripCard(
                      trip: trips[index],
                      index: index,
                      onDelete: () => _deleteTrip(index),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    '¡Aún no has registrado ningún viaje!\nPulsa el botón de la cámara para guardar tu primer viaje y verás aquí tu historial. 🚗',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
  // Botón flotante de borrar historial eliminado por requerimiento
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

      if (!mounted) return;
      
      if (result != null) {
        setState(() {
          trips.add(result);
        });
        
        // Guardar viajes en SharedPreferences
        // _saveTrips(); // No es necesario guardar aquí, ya que los datos son remotos
        
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
    DialogUtils.showPermissionDialog(context);
  }

  // _showClearHistoryDialog eliminado porque ya no se usa

  void _showFuelPriceDialog() {
    DialogUtils.showFuelPriceDialog(context, _fuelPrice, _saveFuelPrice);
  }
}
