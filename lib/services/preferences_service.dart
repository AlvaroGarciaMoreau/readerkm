import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_data.dart';

class PreferencesService {
  static const String _emailKey = 'user_email';
  // Guardar correo
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  // Cargar correo
  static Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }
  static const String _fuelPriceKey = 'fuel_price';
  static const String _savedTripsKey = 'saved_trips';
  static const double _defaultFuelPrice = 1.50;

  // Cargar precio de combustible
  static Future<double> loadFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fuelPriceKey) ?? _defaultFuelPrice;
  }

  // Guardar precio de combustible
  static Future<void> saveFuelPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fuelPriceKey, price);
  }

  // Cargar viajes guardados
  static Future<List<TripData>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_savedTripsKey) ?? [];
    
    return tripsJson.map((tripString) {
      final tripMap = jsonDecode(tripString) as Map<String, dynamic>;
      return TripData.fromJson(tripMap);
    }).toList();
  }

  // Guardar viajes
  static Future<void> saveTrips(List<TripData> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = trips.map((trip) => jsonEncode(trip.toJson())).toList();
    await prefs.setStringList(_savedTripsKey, tripsJson);
  }
}
