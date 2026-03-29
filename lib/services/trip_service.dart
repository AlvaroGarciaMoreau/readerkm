import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/trip_data.dart';
import 'preferences_service.dart';

class TripService {
  static const String _baseUrl = 'https://www.moreausoft.com/ReaderKM/fotos';
  static const Duration _timeout = Duration(seconds: 30);

  /// Carga los viajes de forma unificada (Backend o Local)
  static Future<List<TripData>> loadTrips(String? email) async {
    if (email != null && email.isNotEmpty) {
      return await _loadTripsFromBackend(email);
    } else {
      return await _loadTripsLocal();
    }
  }

  static Future<List<TripData>> _loadTripsLocal() async {
    final tripsJson = await PreferencesService.loadLocalTrips();
    return tripsJson.map((j) => TripData.fromJson(jsonDecode(j))).toList();
  }

  static Future<List<TripData>> _loadTripsFromBackend(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/listar_viajes_with_images.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        if (resp['success'] == true && resp['viajes'] != null) {
          List<TripData> loadedTrips = (resp['viajes'] as List)
              .map((json) => TripData.fromJson(json))
              .toList();
          loadedTrips.sort((a, b) => b.date.compareTo(a.date));
          return loadedTrips;
        } else {
          throw Exception(resp['error'] ?? 'Error desconocido del servidor');
        }
      } else {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error loading trips from backend: $e');
      rethrow;
    }
  }

  /// Guarda un viaje de forma unificada
  static Future<TripData> saveTrip(TripData trip, String? email) async {
    if (email != null && email.isNotEmpty) {
      return await _saveTripToBackend(trip, email);
    } else {
      return await _saveTripLocal(trip);
    }
  }

  static Future<TripData> _saveTripLocal(TripData trip) async {
    final tripsJson = await PreferencesService.loadLocalTrips();
    final updatedTrips = [jsonEncode(trip.toJson()), ...tripsJson];
    await PreferencesService.saveLocalTrips(updatedTrips);
    return trip;
  }

  static Future<TripData> _saveTripToBackend(TripData trip, String email) async {
    try {
      final url = Uri.parse('$_baseUrl/guardar_viaje_with_images.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          ...trip.toJson(),
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        if (resp['success'] == true) {
          if (resp['id'] != null) {
            return trip.copyWith(id: int.tryParse(resp['id'].toString()));
          }
          return trip;
        } else {
          throw Exception(resp['error'] ?? 'Error al guardar viaje');
        }
      } else {
        throw Exception('Error del servidor al guardar (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error saving trip to backend: $e');
      rethrow;
    }
  }

  /// Elimina un viaje de forma unificada
  static Future<void> deleteTrip(TripData trip, String? email, List<TripData> currentTrips) async {
    if (email != null && email.isNotEmpty) {
      await _deleteTripFromBackend(trip, email);
    } else {
      await _deleteTripLocal(trip, currentTrips);
    }
  }

  static Future<void> _deleteTripLocal(TripData trip, List<TripData> currentTrips) async {
    final updatedTrips = currentTrips.where((t) => t != trip).toList();
    final tripsJson = updatedTrips.map((t) => jsonEncode(t.toJson())).toList();
    await PreferencesService.saveLocalTrips(tripsJson);
  }

  static Future<void> _deleteTripFromBackend(TripData trip, String email) async {
    if (trip.id == null) {
      throw Exception('No se puede eliminar un viaje sin ID');
    }
    
    try {
      final url = Uri.parse('$_baseUrl/guardar_viaje_with_images.php'); // El script parece ser el mismo para eliminar segun home_screen.dart (curioso)
      // Nota: Revisando HomeScreen.dart linea 200: body: jsonEncode({'id': tripId, 'email': _email})
      // Sugiere que si solo envias ID y Email se elimina.
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': trip.id, 'email': email}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        if (resp['success'] != true) {
          throw Exception(resp['error'] ?? 'Error al eliminar viaje');
        }
      } else {
        throw Exception('Error del servidor al eliminar (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error deleting trip from backend: $e');
      rethrow;
    }
  }
}
