import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/features/supervisor/repositories/student_repository.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/core/network/api_result.dart';

final supervisorStudentGpsProvider = FutureProvider.family.autoDispose<List<GPSLocation>, String>((ref, studentId) async {
  final repo = StudentRepository();
  return await repo.fetchStudentGpsHistory(studentId);
});

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textBody = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const orange = Color(0xFFF97316);
  static const blue = Color(0xFF3B82F6);
  static const cardRadius = 32.0;
}

class SupervisorLocationScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String? activityId;
  
  const SupervisorLocationScreen({super.key, required this.studentId, this.activityId});

  @override
  ConsumerState<SupervisorLocationScreen> createState() => _SupervisorLocationScreenState();
}

class _SupervisorLocationScreenState extends ConsumerState<SupervisorLocationScreen> {
  // Add a MapController to manage map actions programmatically
  final MapController _mapController = MapController();
  
  // Default coordinates to center back on
  final LatLng _initialCenter = const LatLng(-3.6305, 39.8499);
  final double _initialZoom = 14.5;

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _recenterMap() {
    _mapController.move(_initialCenter, _initialZoom);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── TOP ROW: STATS & DETAILS ─────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Card: Main Statistics
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_C.cardRadius),
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final gpsAsync = ref.watch(supervisorStudentGpsProvider(widget.studentId));
                    List<GPSLocation> gpsHistory = gpsAsync.asData?.value ?? [];
                    
                    String fieldSession = '-';
                    String timeInField = '-';
                    String distanceStr = '0 km';
                    String accuracyStr = '-';
                    
                    if (widget.activityId != null) {
                      final activityAsync = ref.watch(activityDetailsProvider(widget.activityId!));
                      final activityResult = activityAsync.asData?.value;
                      final activity = activityResult is Success ? (activityResult as Success).data : null;
                      if (activity != null && activity['latitude'] != null && activity['longitude'] != null) {
                        final lat = (activity['latitude'] as num).toDouble();
                        final lng = (activity['longitude'] as num).toDouble();
                        final timestamp = activity['timestamp'] != null ? DateTime.parse(activity['timestamp']) : DateTime.now();
                        gpsHistory = [GPSLocation(latitude: lat, longitude: lng, altitude: 0.0, heading: 0.0, accuracy: (activity['gpsAccuracy'] as num?)?.toDouble() ?? 5.0, capturedAt: timestamp, speed: 0.0, address: '')];
                      } else {
                        gpsHistory = [];
                      }
                    }
                    
                    if (gpsHistory.isNotEmpty) {
                      final first = gpsHistory.first;
                      final last = gpsHistory.last;
                      
                      fieldSession = DateFormat('dd MMM yyyy').format(first.capturedAt);
                      
                      final duration = last.capturedAt.difference(first.capturedAt);
                      final hours = duration.inHours;
                      final minutes = duration.inMinutes.remainder(60);
                      timeInField = '${hours}h ${minutes}m';
                      
                      // basic distance using route points
                      double totalDist = 0;
                      final distance = const Distance();
                      for (int i = 0; i < gpsHistory.length - 1; i++) {
                        totalDist += distance.as(
                          LengthUnit.Kilometer, 
                          LatLng(gpsHistory[i].latitude, gpsHistory[i].longitude), 
                          LatLng(gpsHistory[i+1].latitude, gpsHistory[i+1].longitude)
                        );
                      }
                      distanceStr = '${totalDist.toStringAsFixed(1)} km';
                      
                      double totalAcc = 0;
                      for (var loc in gpsHistory) { totalAcc += loc.accuracy; }
                      accuracyStr = '${(totalAcc / gpsHistory.length).toStringAsFixed(1)} m';
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCol('Field Session', fieldSession, ''),
                        _buildStatCol('Time in Field', timeInField, 'Total Duration'),
                        _buildStatCol('Distance Traveled', distanceStr, 'Total Distance'),
                        _buildStatCol('Avg. Accuracy', accuracyStr, 'GPS Accuracy'),
                        _buildStatCol('GPS Points', '${gpsHistory.length}', 'Total Points'),
                      ],
                    );
                  }
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // Right Card: Location Details
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_C.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Details',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _C.textDark),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, _) {
                        final gpsAsync = ref.watch(supervisorStudentGpsProvider(widget.studentId));
                        final gpsHistory = gpsAsync.asData?.value ?? [];
                        String startStr = '-';
                        String endStr = '-';
                        if (gpsHistory.isNotEmpty) {
                          startStr = DateFormat('dd Jul yyyy, hh:mm a').format(gpsHistory.first.capturedAt.toLocal());
                          endStr = DateFormat('dd Jul yyyy, hh:mm a').format(gpsHistory.last.capturedAt.toLocal());
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLocationDetailRow(PhosphorIconsRegular.mapPin, 'Start point (Check In)', startStr),
                            const SizedBox(height: 12),
                            _buildLocationDetailRow(PhosphorIconsRegular.flag, 'End point (Check Out)', endStr),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // ── BOTTOM ROW: MAP AREA ─────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_C.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_C.cardRadius),
              child: Stack(
                children: [
                  // Flutter Map Component
                  Consumer(
                    builder: (context, ref, _) {
                      final gpsAsync = ref.watch(supervisorStudentGpsProvider(widget.studentId));
                      final activitiesAsync = ref.watch(studentActivitiesByStudentIdProvider(widget.studentId));

                      List<GPSLocation> gpsHistory = gpsAsync.asData?.value ?? [];
                      
                      if (widget.activityId != null) {
                        final activityAsyncDetail = ref.watch(activityDetailsProvider(widget.activityId!));
                        final activityResultDetail = activityAsyncDetail.asData?.value;
                        final activity = activityResultDetail is Success ? (activityResultDetail as Success).data : null;
                        if (activity != null && activity['latitude'] != null && activity['longitude'] != null) {
                          final lat = (activity['latitude'] as num).toDouble();
                          final lng = (activity['longitude'] as num).toDouble();
                          final timestamp = activity['timestamp'] != null ? DateTime.parse(activity['timestamp']) : DateTime.now();
                          gpsHistory = [GPSLocation(latitude: lat, longitude: lng, altitude: 0.0, heading: 0.0, speed: 0.0, address: 'Unknown', accuracy: (activity['gpsAccuracy'] as num?)?.toDouble() ?? 5.0, capturedAt: timestamp)];
                        } else {
                          gpsHistory = [];
                        }
                      }
                      
                      final routePoints = gpsHistory.map((l) => LatLng(l.latitude, l.longitude)).toList();
                      
                      final activityMarkers = <Marker>[];
                      if (activitiesAsync.hasValue) {
                        final activitiesResult = activitiesAsync.value!;
                        if (activitiesResult is Success) {
                          final activities = (activitiesResult as Success).data as List<dynamic>;
                          for (final activity in activities) {
                            if (activity['latitude'] != null && activity['longitude'] != null) {
                              activityMarkers.add(
                                Marker(
                                  point: LatLng((activity['latitude'] as num).toDouble(), (activity['longitude'] as num).toDouble()),
                                  child: const Icon(PhosphorIconsFill.mapPin, color: _C.green, size: 32),
                                )
                              );
                            }
                          }
                        }
                      }
                      
                      // Update center if we have route points and haven't centered yet
                      if (routePoints.isNotEmpty && _mapController.camera.center.latitude == _initialCenter.latitude) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           try { _mapController.move(routePoints.first, _initialZoom); } catch (_) {}
                        });
                      }

                      return FlutterMap(
                        mapController: _mapController, // Attach controller
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: _initialZoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.fieldtrack.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4.0,
                                color: _C.blue,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: activityMarkers,
                          ),
                        ],
                      );
                    },
                  ),
                  
                  // Floating Map Style Button (Top Right)
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: const [
                          Icon(PhosphorIconsRegular.stack, color: _C.textBody, size: 18),
                          SizedBox(width: 8),
                          Text('Map Style', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _C.textBody)),
                          SizedBox(width: 8),
                          Icon(PhosphorIconsRegular.caretDown, color: _C.textBody, size: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Floating Zoom Controls (Middle Right)
                  Positioned(
                    top: 80,
                    right: 24,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(PhosphorIconsRegular.plus, color: _C.textDark, size: 20),
                                onPressed: _zoomIn, // Trigger Zoom In
                              ),
                              Container(height: 1, width: 24, color: _C.border),
                              IconButton(
                                icon: const Icon(PhosphorIconsRegular.minus, color: _C.textDark, size: 20),
                                onPressed: _zoomOut, // Trigger Zoom Out
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: IconButton(
                            icon: const Icon(PhosphorIconsRegular.crosshair, color: _C.textDark, size: 20),
                            onPressed: _recenterMap, // Trigger Recenter
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Floating Legend Pill (Bottom Center)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendItem(const Icon(PhosphorIconsFill.mapPin, color: _C.green, size: 18), 'Checked In'),
                            const SizedBox(width: 24),
                            _buildLegendItem(const Icon(PhosphorIconsFill.circle, color: _C.green, size: 14), 'GPS Point'),
                            const SizedBox(width: 24),
                            _buildLegendItem(_buildDashedLine(), 'Route'),
                            const SizedBox(width: 24),
                            _buildLegendItem(const Icon(PhosphorIconsFill.mapPin, color: _C.orange, size: 18), 'Check Out'),
                            const SizedBox(width: 24),
                            _buildLegendItem(const Icon(PhosphorIconsRegular.circle, color: _C.blue, size: 18), 'Activity Location'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── WIDGET BUILDERS ────────────────────────────────────────────────────

  Widget _buildStatCol(String title, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _C.textBody, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, color: _C.textDark, fontWeight: FontWeight.w700)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _C.textFaint)),
        ]
      ],
    );
  }

  Widget _buildLocationDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.textFaint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _C.textBody)),
        ),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _C.textDark)),
      ],
    );
  }

  Widget _buildLegendItem(Widget icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: _C.textBody)),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 3, 
          margin: const EdgeInsets.only(right: 2), 
          decoration: BoxDecoration(
            color: _C.green, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 4, 
          height: 3, 
          margin: const EdgeInsets.only(right: 2), 
          decoration: BoxDecoration(
            color: _C.green, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 4, 
          height: 3, 
          decoration: BoxDecoration(
            color: _C.green, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
