import 'package:flutter/material.dart';
import '../models/trip_data.dart';
import '../services/image_upload_service.dart';

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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _getSecureImageUrl() async {
    if (trip.imageFilename == null || trip.imageFilename!.isEmpty) {
      return null;
    }
    return await ImageUploadService.getSecureImageUrl(trip.imageFilename!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formattedTime = _formatTime(trip.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 20), // Aumentado para separación
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bordes más suaves
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Solo hora y botón borrar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        formattedTime,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade200, size: 20),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Eliminar viaje',
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main technical data Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          icon: Icons.route_outlined,
                          label: 'DISTANCIA',
                          value: trip.distance.toStringAsFixed(1),
                          unit: 'km',
                          color: const Color(0xFF2D62ED),
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade100),
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          icon: Icons.local_gas_station_outlined,
                          label: 'CONSUMO',
                          value: trip.consumption.toStringAsFixed(1),
                          unit: trip.consumptionUnit,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Cost highlight (Large for visibility)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COSTE ESTIMADO',
                            style: textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.2,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${trip.totalCost.toStringAsFixed(2)} €',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade700,
                              fontSize: 28, // Muy grande para vista cansada
                            ),
                          ),
                        ],
                      ),
                      
                      // Extra details pill
                      if (trip.totalKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.speed, size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.totalKm!.toStringAsFixed(0)} km totales',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // Secondary details row
                  if (trip.travelTime != null || trip.imageFilename != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (trip.travelTime != null)
                          _buildDetailChip(Icons.timer_outlined, trip.travelTime!),
                        if (trip.travelTime != null && trip.imageFilename != null)
                          const SizedBox(width: 8),
                        if (trip.imageFilename != null)
                          GestureDetector(
                            onTap: () => _showImageDialog(context),
                            child: _buildDetailChip(Icons.photo_outlined, 'Ver Foto', isAction: true),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, {bool isAction = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAction ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAction ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isAction ? Colors.blue.shade700 : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAction ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context) async {
    final imageUrl = await _getSecureImageUrl();
    if (imageUrl == null || imageUrl.isEmpty) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}