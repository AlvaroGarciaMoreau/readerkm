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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(trip.date);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y botón eliminar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Eliminar viaje',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información principal en tarjetas
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.speed,
                    label: 'Distancia',
                    value: '${trip.distance.toStringAsFixed(1)} km',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.local_gas_station,
                    label: 'Consumo',
                    value: trip.consumptionUnit == 'L/100km' 
                        ? '${trip.consumption.toStringAsFixed(1)} L/100km'
                        : '${trip.consumption.toStringAsFixed(1)} km/L',
                    subtitle: trip.consumptionUnit == 'L/100km'
                        ? '(${(100/trip.consumption).toStringAsFixed(1)} km/L)'
                        : '(${trip.litersPer100Km.toStringAsFixed(1)} L/100km)',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.euro,
                    label: 'Total',
                    value: '${trip.totalCost.toStringAsFixed(2)} €',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            // Información adicional si está disponible
            if (trip.travelTime != null || trip.totalKm != null) 
              ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (trip.travelTime != null) 
                    ...[
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Tiempo: ${trip.travelTime}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (trip.travelTime != null && trip.totalKm != null)
                    const SizedBox(width: 16),
                  if (trip.totalKm != null) 
                    ...[
                    const Icon(Icons.speed, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Odómetro: ${trip.totalKm!.toStringAsFixed(0)} km',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
            
            // Información del precio de combustible
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Precio combustible: ${trip.fuelPrice.toStringAsFixed(2)} €/L',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}