import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminMapScreen extends StatelessWidget {
  const AdminMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live System Map',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('All Students', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Supervisor Regions', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Heatmap', false),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: const LatLng(-1.2921, 36.8219), // Nairobi
                        initialZoom: 6,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: const LatLng(-1.2921, 36.8219),
                              width: 40,
                              height: 40,
                              child: _buildMarkerIcon(Colors.blue),
                            ),
                            Marker(
                              point: const LatLng(-4.0435, 39.6682), // Mombasa
                              width: 40,
                              height: 40,
                              child: _buildMarkerIcon(const Color(0xFF1BA654)),
                            ),
                            Marker(
                              point: const LatLng(-0.0917, 34.7680), // Kisumu
                              width: 40,
                              height: 40,
                              child: _buildMarkerIcon(Colors.orange),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Map Legend / Filters panel
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Map Filters',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLegendItem(Colors.blue, 'Computer Science Students'),
                            const SizedBox(height: 12),
                            _buildLegendItem(const Color(0xFF1BA654), 'Environmental Sci.'),
                            const SizedBox(height: 12),
                            _buildLegendItem(Colors.orange, 'Civil Engineering'),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 16),
                            _buildMapToggle('Show Supervisor Zones', true),
                            const SizedBox(height: 12),
                            _buildMapToggle('Show Live Traffic', false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1BA654).withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF1BA654).withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF1BA654) : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildMarkerIcon(Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill), color: Colors.white, size: 14),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }

  Widget _buildMapToggle(String label, bool isToggled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4B5563)),
        ),
        Switch(
          value: isToggled,
          onChanged: (val) {},
          activeColor: const Color(0xFF1BA654),
        ),
      ],
    );
  }
}
