import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_data.dart';
import '../services/preferences_service.dart';
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
  bool localMode = false;
  List<TripData> trips = [];
  bool _showEmailWarning = true;

  bool get isEmailMode => _email != null && _email!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadFuelPrice();
    _loadEmailAndTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('email_dialog_shown') ?? false;
      if (!shown) {
        if (mounted) _showEmailDialog();
        await prefs.setBool('email_dialog_shown', true);
      }
    });
  }

  Future<void> _loadFuelPrice() async {
    final price = await PreferencesService.loadFuelPrice();
    if (!mounted) return;
    setState(() {
      _fuelPrice = price;
    });
  }

  Future<void> _loadEmailAndTrips() async {
    _email = await PreferencesService.loadEmail();
    if (isEmailMode) {
      await _loadTripsFromBackend();
      // Si hay email configurado, ocultar la advertencia
      if (mounted) {
        setState(() {
          _showEmailWarning = false;
        });
      }
    } else {
      localMode = true;
      await _loadTripsLocal();
      // Si no hay email, programar ocultar la advertencia después de 5 segundos
      if (mounted) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showEmailWarning = false;
            });
          }
        });
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadTripsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList('local_trips') ?? [];
    trips = tripsJson.map((j) => TripData.fromJson(jsonDecode(j))).toList();
  }

  Future<void> _saveTripsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = trips.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('local_trips', tripsJson);
  }

  Future<void> _loadTripsFromBackend() async {
    try {
      final url = Uri.parse('https://www.moreausoft.com/ReaderKM/listar_viajes.php');
            final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email}),
      ).timeout(const Duration(seconds: 30));
        if (!mounted) return;
      if (response.statusCode == 200) {
        try {
          final resp = jsonDecode(response.body);
          if (resp['success'] == true && resp['viajes'] != null) {
            List<TripData> loadedTrips = (resp['viajes'] as List).map((json) => TripData.fromJson(json)).toList();
            loadedTrips.sort((a, b) => b.date.compareTo(a.date));
            trips = loadedTrips;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al cargar viajes: ${resp['error'] ?? 'Error desconocido'}')),
              );
            }
          }
        } catch (jsonError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error en la respuesta del servidor: Formato inválido'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          debugPrint('Error parsing JSON response: ${response.body}');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error del servidor (${response.statusCode}): ${response.body}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
          } catch (e) {
        if (mounted) {
          String errorMessage = 'Error de red al cargar viajes';
          if (e.toString().contains('TimeoutException')) {
            errorMessage = 'Tiempo de espera agotado al cargar viajes';
          } else if (e.toString().contains('SocketException')) {
            errorMessage = 'Error de conexión al cargar viajes';
          } else {
            errorMessage = 'Error de red al cargar viajes: $e';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
  }

  Future<void> _saveFuelPrice(double price) async {
    await PreferencesService.saveFuelPrice(price);
    if (!mounted) return;
    setState(() {
      _fuelPrice = price;
    });
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
         if (confirm == true) {
       if (isEmailMode) {
         final tripId = trips[index].id;
         if (tripId == null) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('No se puede eliminar un viaje que aún no se ha guardado en el servidor'),
                 duration: Duration(seconds: 3),
               ),
             );
           }
           return;
         }
         try {
           final url = Uri.parse('https://www.moreausoft.com/ReaderKM/borrar_viaje.php');
           final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': tripId, 'email': _email}),
          ).timeout(const Duration(seconds: 30));
            if (!mounted) return;
          if (response.statusCode == 200) {
            try {
              final resp = jsonDecode(response.body);
              if (resp['success'] == true) {
                setState(() {
                  trips.removeAt(index);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viaje eliminado correctamente')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar viaje: ${resp['error'] ?? 'Error desconocido'}')),
                  );
                }
              }
            } catch (jsonError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error en la respuesta del servidor: Formato inválido'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              debugPrint('Error parsing JSON response: ${response.body}');
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error del servidor (${response.statusCode}): ${response.body}'),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            String errorMessage = 'Error de red al eliminar viaje';
            if (e.toString().contains('TimeoutException')) {
              errorMessage = 'Tiempo de espera agotado al eliminar viaje';
            } else if (e.toString().contains('SocketException')) {
              errorMessage = 'Error de conexión al eliminar viaje';
            } else {
              errorMessage = 'Error de red al eliminar viaje: $e';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        setState(() {
          trips.removeAt(index);
        });
        await _saveTripsLocal();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaje eliminado correctamente')),
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
        title: const Text('Precio de gasolina'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Euros/litro'),
          onChanged: (value) {
            final price = double.tryParse(value);
            if (price != null) {
              setState(() {
                _fuelPrice = price;
              });
              PreferencesService.saveFuelPrice(price);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price != null) {
                await _saveFuelPrice(price);
              }
              if (mounted) {
                Navigator.pop(context);
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
              'Ingresa tu correo electrónico para sincronizar tus viajes entre dispositivos:',
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
            const SizedBox(height: 8),
            const Text(
              'Deja vacío para usar solo almacenamiento local',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final email = controller.text.trim();
              await PreferencesService.saveEmail(email);
              _email = email.isNotEmpty ? email : null;
              if (mounted) {
                Navigator.pop(context);
                // Ocultar la advertencia si se configuró un email
                if (email.isNotEmpty) {
                  setState(() {
                    _showEmailWarning = false;
                  });
                }
              }
              await _loadEmailAndTrips();
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
        setState(() {
          trips.insert(0, result);
        });
        if (isEmailMode) {
          // Save to backend
          try {
            final url = Uri.parse('https://www.moreausoft.com/ReaderKM/guardar_viaje.php');
                        final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': _email,
                ...result.toJson(),
              }),
            ).timeout(const Duration(seconds: 30));
              if (!mounted) return;
            if (response.statusCode == 200) {
                             try {
                 final resp = jsonDecode(response.body);
                 if (resp['success'] == true) {
                   // Actualizar el ID del viaje con el ID devuelto por el servidor
                   if (resp['id'] != null) {
                     setState(() {
                       trips[0] = TripData(
                         id: int.tryParse(resp['id'].toString()),
                         distance: trips[0].distance,
                         consumption: trips[0].consumption,
                         consumptionUnit: trips[0].consumptionUnit,
                         fuelPrice: trips[0].fuelPrice,
                         totalCost: trips[0].totalCost,
                         litersPer100Km: trips[0].litersPer100Km,
                         travelTime: trips[0].travelTime,
                         totalKm: trips[0].totalKm,
                         date: trips[0].date,
                       );
                     });
                   }
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Viaje guardado correctamente')),
                     );
                   }
                 } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar viaje: ${resp['error'] ?? 'Error desconocido'}')),
                    );
                  }
                }
              } catch (jsonError) {
                // Si la respuesta no es JSON válido, mostrar el error de formato
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error en la respuesta del servidor: Formato inválido'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
                debugPrint('Error parsing JSON response: ${response.body}');
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error del servidor (${response.statusCode}): ${response.body}'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              String errorMessage = 'Error de red al guardar viaje';
              if (e.toString().contains('TimeoutException')) {
                errorMessage = 'Tiempo de espera agotado al guardar viaje';
              } else if (e.toString().contains('SocketException')) {
                errorMessage = 'Error de conexión al guardar viaje';
              } else {
                errorMessage = 'Error de red al guardar viaje: $e';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          // Save locally
          await _saveTripsLocal();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReaderKM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showEmailDialog,
            tooltip: 'Configuración',
          ),
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
            if (!isEmailMode && _showEmailWarning)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No has ingresado correo electrónico. Tus viajes se guardarán solo localmente y no se podrán recuperar en otro dispositivo.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            CameraScanSection(
              fuelPrice: _fuelPrice,
              onScanPressed: _startCamera,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: trips.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                      ],
                    )
                  : Center(
                      child: Text(
                        '¡Aún no has registrado ningún viaje!\nPulsa el botón de la cámara para guardar tu primer viaje y verás aquí tu historial.',
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
    );
  }
}
