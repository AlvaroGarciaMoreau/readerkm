
class TripData {
  final int? id;
  final double distance;
  final double consumption; // Valor tal cual, según la unidad
  final String consumptionUnit; // 'km/L' o 'L/100km'
  final double fuelPrice;
  final double totalCost;
  final double litersPer100Km;
  final String? travelTime;
  final double? totalKm;
  final DateTime date;

  TripData({
    this.id,
    required this.distance,
    required this.consumption,
    required this.consumptionUnit,
    required this.fuelPrice,
    required this.totalCost,
    required this.litersPer100Km,
    this.travelTime,
    this.totalKm,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distance': distance,
      'consumption': consumption,
      'consumptionUnit': consumptionUnit,
      'fuelPrice': fuelPrice,
      'totalCost': totalCost,
      'litersPer100Km': litersPer100Km,
      'travelTime': travelTime,
      'totalKm': totalKm,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory TripData.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) {
        // Epoch timestamp
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        // Intenta parsear como string tipo '2025-08-10 23:19:12'
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    return TripData(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      distance: json['distance'].toDouble(),
      consumption: json['consumption'].toDouble(),
      consumptionUnit: json['consumptionUnit'] ?? 'L/100km',
      fuelPrice: json['fuelPrice'].toDouble(),
      totalCost: json['totalCost'].toDouble(),
      litersPer100Km: json['litersPer100Km']?.toDouble() ?? 0.0,
      travelTime: json['travelTime'],
      totalKm: json['totalKm']?.toDouble(),
      date: parseDate(json['fecha'] ?? json['date']),
    );
  }
}
