import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _fuelPriceKey = 'fuel_price';
  static const String _emailKey = 'user_email';
  static const String _localTripsKey = 'local_trips';

  // Precio de combustible
  static Future<double> loadFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fuelPriceKey) ?? 1.50; // Precio por defecto
  }

  static Future<void> saveFuelPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fuelPriceKey, price);
  }

  // Email del usuario
  static Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    return email?.isEmpty == true ? null : email;
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email.isEmpty) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, email);
    }
  }

  // Viajes locales
  static Future<List<String>> loadLocalTrips() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_localTripsKey) ?? [];
  }

  static Future<void> saveLocalTrips(List<String> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localTripsKey, trips);
  }

  // Limpiar todos los datos
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Verificar si es la primera vez que se abre la app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_fuelPriceKey);
  }
}