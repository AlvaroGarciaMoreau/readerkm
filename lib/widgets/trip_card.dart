import 'package:flutter/material.dart';
import '../models/trip_data.dart';

class TripCard extends StatelessWidget {
  final TripData trip;
  final int index;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          'L/100km: ${trip.litersPer100Km.toStringAsFixed(2)}\n'
          '${trip.travelTime != null ? 'Tiempo: ${trip.travelTime}\n' : ''}'
          '${trip.totalKm != null ? 'Odómetro: ${trip.totalKm!.toStringAsFixed(0)} km\n' : ''}'
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
              onPressed: onDelete,
              tooltip: 'Eliminar viaje',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
