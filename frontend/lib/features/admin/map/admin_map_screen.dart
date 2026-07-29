import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Map Marker Model ──
class MapMarkerData {
  final String id;
  final String studentId;
  final String studentName;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String department;
  final String checkInTime;

  const MapMarkerData({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.department,
    required this.checkInTime,
  });

  factory MapMarkerData.fromJson(Map<String, dynamic> json) {
    return MapMarkerData(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? 'Unknown',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      department: json['department'] ?? 'Unknown',
      checkInTime: json['checkInTime'] ?? '',
    );
  }
}

// ── Provider ──
final mapMarkersProvider = FutureProvider<List<MapMarkerData>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/map');
  final List<dynamic> data = response.data['markers'];
  return data.map((e) => MapMarkerData.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Color helper ──
Color _colorForDepartment(String dept) {
  final colors = [
    Colors.blue,
    const Color(0xFF1BA654),
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];
  return colors[dept.hashCode.abs() % colors.length];
}

// ── Map Screen ──
class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  String _filter = 'All Students';

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(mapMarkersProvider);

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
                  _buildFilterChip('All Students', _filter == 'All Students',
                      () => setState(() => _filter = 'All Students')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active Now', _filter == 'Active Now',
                      () => setState(() => _filter = 'Active Now')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: markersAsync.when(
              data: (markers) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(-1.2921, 36.8219),
                            initialZoom: 6,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: markers
                                  .map((m) => Marker(
                                        point: LatLng(m.latitude, m.longitude),
                                        width: 80,
                                        height: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.15),
                                                      blurRadius: 4)
                                                ],
                                              ),
                                              child: Text(
                                                m.studentName
                                                    .split(' ')
                                                    .first,
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: _colorForDepartment(
                                                    m.department),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.2),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2))
                                                ],
                                              ),
                                              child: Icon(
                                                PhosphorIcons.user(
                                                    PhosphorIconsStyle.fill),
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        // Legend panel
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
                                    color:
                                        Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Students in Field',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                const SizedBox(height: 16),
                                Text('${markers.length} active marker(s)',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF4B5563))),
                                const SizedBox(height: 12),
                                if (markers.isEmpty)
                                  const Text(
                                      'No students currently in the field',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: Color(0xFF6B7280)))
                                else
                                  ...markers.take(5).map((m) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                    color: _colorForDepartment(
                                                        m.department),
                                                    shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                  '${m.studentName} (${m.department.split(' ').first})',
                                                  style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF4B5563)),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      )),
                                if (markers.length > 5)
                                  Text('+${markers.length - 5} more...',
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF1BA654))),
              ),
              error: (err, stack) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning(),
                          size: 48, color: const Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      const Text('Failed to load map data',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BA654).withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1BA654).withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1BA654)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

