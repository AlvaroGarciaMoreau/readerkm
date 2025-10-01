
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
  final String? imageUrl;        // URL directa de la imagen
  final String? imageFilename;   // Nombre del archivo (para referencia)

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
    this.imageUrl,        
    this.imageFilename,   
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
      'imageUrl': imageUrl,         
      'imageFilename': imageFilename, 
    };
  }

  factory TripData.fromJson(Map<String, dynamic> json) {
    // DEBUG: Imprimir los datos JSON recibidos
    
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
    
    final tripData = TripData(
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
      imageUrl: json['imageUrl'],         
      imageFilename: json['imageFilename'], 
    );
    
    // DEBUG: Imprimir el TripData creado
    
    return tripData;
  }

  TripData copyWith({
    int? id,
    double? distance,
    double? consumption,
    String? consumptionUnit,
    double? fuelPrice,
    double? totalCost,
    double? litersPer100Km,
    String? travelTime,
    double? totalKm,
    DateTime? date,
    String? imageUrl,
    String? imageFilename,
  }) {
    return TripData(
      id: id ?? this.id,
      distance: distance ?? this.distance,
      consumption: consumption ?? this.consumption,
      consumptionUnit: consumptionUnit ?? this.consumptionUnit,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      totalCost: totalCost ?? this.totalCost,
      litersPer100Km: litersPer100Km ?? this.litersPer100Km,
      travelTime: travelTime ?? this.travelTime,
      totalKm: totalKm ?? this.totalKm,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFilename: imageFilename ?? this.imageFilename,
    );
  }
}
