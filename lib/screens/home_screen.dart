import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _loadTrips() async {
    final loadedTrips = await PreferencesService.loadTrips();
    setState(() {
      trips = loadedTrips;
    });
  }

  Future<void> _saveTrips() async {
    await PreferencesService.saveTrips(trips);
  }

  void _deleteTrip(int index) {
    DialogUtils.showDeleteTripDialog(context, () {
      setState(() {
        trips.removeAt(index);
      });
      
      _saveTrips();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaje eliminado'),
          backgroundColor: Colors.orange,
        ),
      );
    });
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
    DialogUtils.showPermissionDialog(context);
  }

  void _showClearHistoryDialog() {
    DialogUtils.showClearHistoryDialog(context, () {
      setState(() {
        trips.clear();
      });
      
      _saveTrips();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historial limpiado'),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  void _showFuelPriceDialog() {
    DialogUtils.showFuelPriceDialog(context, _fuelPrice, _saveFuelPrice);
  }
}
