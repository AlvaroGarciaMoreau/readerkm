class TripData {
  final double distance;
  final double consumption;
  final double fuelPrice;
  final double totalCost;
  final double litersPer100Km;
  final DateTime date;

  TripData({
    required this.distance,
    required this.consumption,
    required this.fuelPrice,
    required this.totalCost,
    required this.litersPer100Km,
    required this.date,
  });

  // Convertir a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'consumption': consumption,
      'fuelPrice': fuelPrice,
      'totalCost': totalCost,
      'litersPer100Km': litersPer100Km,
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
      litersPer100Km: json['litersPer100Km']?.toDouble() ?? 0.0, // Valor por defecto para compatibilidad
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }
}
