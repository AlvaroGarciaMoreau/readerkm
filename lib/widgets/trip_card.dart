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
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y botón eliminar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$dateFormat a las $timeFormat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Eliminar viaje',
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información principal del viaje
            Row(
              children: [
                // Distancia
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.straighten,
                    title: 'Distancia',
                    value: '${trip.distance.toStringAsFixed(1)} km',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                // Consumo
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.local_gas_station,
                    title: 'Consumo',
                    value: _getConsumptionText(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                // Costo total
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.euro,
                    title: 'Total',
                    value: '${trip.totalCost.toStringAsFixed(2)} €',
                    color: Colors.green,
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
            
            // Información adicional (si existe)
            if (trip.travelTime != null || trip.totalKm != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (trip.travelTime != null) ...[
                    Expanded(
                      child: _buildAdditionalInfo(
                        icon: Icons.access_time,
                        label: 'Tiempo',
                        value: trip.travelTime!,
                      ),
                    ),
                  ],
                  if (trip.travelTime != null && trip.totalKm != null)
                    const SizedBox(width: 16),
                  if (trip.totalKm != null) ...[
                    Expanded(
                      child: _buildAdditionalInfo(
                        icon: Icons.speed,
                        label: 'Odómetro',
                        value: '${trip.totalKm!.toStringAsFixed(0)} km',
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Precio del combustible
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Precio combustible: ${trip.fuelPrice.toStringAsFixed(2)} €/L',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
    required String title,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? color.withValues(alpha: 0.3) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getConsumptionText() {
    if (trip.consumptionUnit == 'L/100km') {
      final kmPerLiter = trip.litersPer100Km > 0 ? (100 / trip.litersPer100Km) : 0;
      return '${trip.litersPer100Km.toStringAsFixed(1)} L/100km\n(${kmPerLiter.toStringAsFixed(1)} km/L)';
    } else {
      // Asume km/L
      final litersPer100Km = trip.consumption > 0 ? (100 / trip.consumption) : 0;
      return '${trip.consumption.toStringAsFixed(1)} km/L\n(${litersPer100Km.toStringAsFixed(1)} L/100km)';
    }
  }
}
