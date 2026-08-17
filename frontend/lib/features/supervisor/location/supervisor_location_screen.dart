import 'dart:ui' as ui;
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
import 'package:fieldtrack/core/services/location_naming_service.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/features/supervisor/widgets/supervisor_top_header.dart';
import 'package:fieldtrack/shared/widgets/timeline_skeleton_loader.dart';

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
  final MapController _mapController = MapController();
  final ScrollController _timelineScrollController = ScrollController();
  
  final LatLng _initialCenter = const LatLng(-3.6305, 39.8499);
  final double _initialZoom = 14.5;
  bool _hasCentered = false;
  
  String? _selectedActivityId;

  @override
  void initState() {
    super.initState();
    _selectedActivityId = widget.activityId;
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }


  void _selectActivity(String id, LatLng pt) {
    setState(() {
      _selectedActivityId = id;
    });
    _mapController.move(pt, 16.0);
  }

  // ── HELPERS ────────────────────────────────────────────────────────────

  /// Extracts the first image URL from an activity's evidence list.
  String? _extractThumbUrl(dynamic activity) {
    final evidenceList = activity['evidence'] as List<dynamic>? ?? [];
    for (final ev in evidenceList) {
      final mimeType = ev['mimeType'] as String? ?? '';
      if (mimeType.startsWith('image/')) {
        final path = ev['storagePath'] as String?;
        if (path != null && path.isNotEmpty) {
          return ImageUtils.getFullImageUrl(path);
        }
      }
    }
    return null;
  }

  Widget _buildMarkerTooltip(dynamic activity, String? thumbUrl, bool isSelected, LatLng pt) {
    if (!isSelected) {
      return GestureDetector(
        onTap: () => _selectActivity(activity['id'], pt),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.blue, width: 3),
            color: Colors.white,
          ),
        ),
      );
    }

    final title = activity['title'] as String? ?? 'Activity';
    final timestamp = activity['timestamp'] != null
        ? DateTime.parse(activity['timestamp']).toLocal()
        : null;
    final timeStr = timestamp != null ? DateFormat('hh:mm a').format(timestamp) : '';

    return GestureDetector(
      onTap: () => _selectActivity(activity['id'], pt),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tooltip Card ──────────────────────────────────────────────
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (thumbUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(
                      thumbUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        color: _C.blue.withValues(alpha: 0.08),
                        child: const Icon(PhosphorIconsRegular.image, color: _C.textFaint, size: 28),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _C.textBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Pointer triangle ─────────────────────────────────────────
          CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(color: Colors.white),
          ),
          // ── Pin icon ─────────────────────────────────────────────────
          const Icon(PhosphorIconsFill.mapPin, color: _C.blue, size: 28),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        
        Widget content;
        if (isMobile) {
          content = SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SupervisorTopHeader(
                  title: 'Live Location Tracking',
                  subtitle: 'View real-time student location and activity',
                ),
                const SizedBox(height: 24),
                _buildTopStatsRow(isMobile: isMobile),
                const SizedBox(height: 32),
                SizedBox(height: 400, child: _buildMapCard()),
                const SizedBox(height: 24),
                SizedBox(height: 400, child: _buildActivityTimeline()),
              ],
            ),
          );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SupervisorTopHeader(
                title: 'Live Location Tracking',
                subtitle: 'View real-time student location and activity',
                showBackButton: true,
              ),
              const SizedBox(height: 24),
              // ── TOP ROW: STATS & DETAILS ─────────────────────────────────────
              _buildTopStatsRow(isMobile: isMobile),
              
              const SizedBox(height: 32),
              
              // ── BOTTOM ROW: MAP & TIMELINE ───────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 70, child: _buildMapCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 30, child: _buildActivityTimeline()),
                  ],
                ),
              ),
            ],
          );
        }

        return Container(
          color: const Color(0xFFF3F4F6),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: content,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTopStatsRow({required bool isMobile}) {
    final leftCard = Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Consumer(
              builder: (context, ref, _) {
                final gpsAsync = ref.watch(supervisorStudentGpsProvider(widget.studentId));
                final activitiesAsync = ref.watch(studentActivitiesByStudentIdProvider((studentId: widget.studentId, page: null, limit: null, status: null, search: null)));
                List<GPSLocation> gpsHistory = gpsAsync.asData?.value ?? [];
                
                String fieldSession = '-';
                String timeInField = '-';
                String distanceStr = '0 km';
                String accuracyStr = '-';
                int activitiesCount = 0;
                
                if (activitiesAsync.hasValue && activitiesAsync.value is Success) {
                  activitiesCount = ((activitiesAsync.value as Success).data as List).length;
                }
                
                if (gpsHistory.isNotEmpty) {
                  final first = gpsHistory.first;
                  final last = gpsHistory.last;
                  
                  fieldSession = DateFormat('dd MMM yyyy').format(first.capturedAt);
                  
                  final duration = last.capturedAt.difference(first.capturedAt).abs();
                  final hours = duration.inHours;
                  final minutes = duration.inMinutes.remainder(60);
                  timeInField = '${hours}h ${minutes}m';
                  
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

                if (isMobile) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildStatCol('Field Session', fieldSession, ''),
                      _buildStatCol('Time in Field', timeInField, 'Total Duration'),
                      _buildStatCol('Distance Traveled', distanceStr, 'Total Distance'),
                      _buildStatCol('Avg. Accuracy', accuracyStr, 'GPS Accuracy'),
                      _buildStatCol('Activities', '$activitiesCount', 'Total Logged'),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Field Session', fieldSession, ''),
                    _buildStatCol('Time in Field', timeInField, 'Total Duration'),
                    _buildStatCol('Distance Traveled', distanceStr, 'Total Distance'),
                    _buildStatCol('Avg. Accuracy', accuracyStr, 'GPS Accuracy'),
                    _buildStatCol('Activities', '$activitiesCount', 'Total Logged'),
                  ],
                );
              }
            ),
          );

        final rightCard = Container(
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
          );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftCard,
          const SizedBox(height: 24),
          rightCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: leftCard),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: rightCard),
      ],
    );
  }
  
  Widget _buildMapCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_C.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                final activitiesAsync = ref.watch(studentActivitiesByStudentIdProvider((studentId: widget.studentId, page: null, limit: null, status: null, search: null)));

                List<GPSLocation> gpsHistory = gpsAsync.asData?.value ?? [];
                
                final markers = <Marker>[];
                final routePoints = <LatLng>[];
                
                // 1. Checked In Point (from GPS history first ping)
                if (gpsHistory.isNotEmpty) {
                  final startPt = LatLng(gpsHistory.first.latitude, gpsHistory.first.longitude);
                  routePoints.add(startPt);
                  markers.add(
                    Marker(
                      point: startPt,
                      width: 40, height: 40,
                      child: const Icon(PhosphorIconsFill.mapPin, color: _C.green, size: 32),
                    ),
                  );
                }
                
                // 2. Activity Locations
                if (activitiesAsync.hasValue && activitiesAsync.value is Success) {
                  final activities = (activitiesAsync.value as Success).data as List<dynamic>;
                  activities.sort((a, b) {
                    final timeA = a['timestamp'] != null ? DateTime.parse(a['timestamp']) : DateTime.fromMillisecondsSinceEpoch(0);
                    final timeB = b['timestamp'] != null ? DateTime.parse(b['timestamp']) : DateTime.fromMillisecondsSinceEpoch(0);
                    return timeA.compareTo(timeB);
                  });

                  for (final activity in activities) {
                    if (activity['latitude'] != null && activity['longitude'] != null) {
                      final pt = LatLng((activity['latitude'] as num).toDouble(), (activity['longitude'] as num).toDouble());
                      routePoints.add(pt);
                      final isSelected = _selectedActivityId == activity['id'];
                      final thumbUrl = _extractThumbUrl(activity);

                      // Tooltip card marker: 210w x 180h (card+arrow+pin), plain dot when not selected
                      markers.add(
                        Marker(
                          point: pt,
                          width: isSelected ? 210.0 : 28.0,
                          height: isSelected ? 185.0 : 28.0,
                          alignment: Alignment.bottomCenter,
                          child: _buildMarkerTooltip(activity, thumbUrl, isSelected, pt),
                        ),
                      );
                    }
                  }
                }
                
                // 3. Checked Out / Current GPS Point
                if (gpsHistory.length > 1) {
                  final endPt = LatLng(gpsHistory.last.latitude, gpsHistory.last.longitude);
                  routePoints.add(endPt);
                  markers.add(
                    Marker(
                      point: endPt,
                      width: 40, height: 40,
                      child: const Icon(PhosphorIconsFill.mapPin, color: _C.orange, size: 32),
                    ),
                  );
                }
                
                // Update center if we have route points and haven't centered yet
                if (routePoints.isNotEmpty && !_hasCentered) {
                  _hasCentered = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                     try { _mapController.move(routePoints.first, _initialZoom); } catch (_) {}
                  });
                }

                return FlutterMap(
                  mapController: _mapController,
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
                        Polyline<Object>(
                          points: routePoints,
                          strokeWidth: 4.0,
                          color: _C.blue,
                          pattern: StrokePattern.dashed(segments: const [10.0, 5.0]),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                );
              },
            ),
            
            // Zoom Controls
            Positioned(
              top: 24,
              right: 24,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        IconButton(icon: const Icon(PhosphorIconsRegular.plus, color: _C.textDark, size: 20), onPressed: _zoomIn),
                        Container(height: 1, width: 24, color: _C.border),
                        IconButton(icon: const Icon(PhosphorIconsRegular.minus, color: _C.textDark, size: 20), onPressed: _zoomOut),
                      ],
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
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(const Icon(PhosphorIconsFill.mapPin, color: _C.green, size: 18), 'Checked In'),
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
    );
  }
  
  Widget _buildActivityTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Timeline',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final activitiesAsync = ref.watch(studentActivitiesByStudentIdProvider((studentId: widget.studentId, page: null, limit: null, status: null, search: null)));
                
                if (activitiesAsync.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: TimelineSkeletonLoader(itemCount: 4),
                  );
                }
                
                if (!activitiesAsync.hasValue || activitiesAsync.value is! Success) {
                  return const Center(child: Text('No activities found.'));
                }
                
                final activities = (activitiesAsync.value as Success).data as List<dynamic>;
                if (activities.isEmpty) {
                  return const Center(child: Text('No activities logged yet.'));
                }
                
                activities.sort((a, b) {
                  final timeA = a['timestamp'] != null ? DateTime.parse(a['timestamp']) : DateTime.fromMillisecondsSinceEpoch(0);
                  final timeB = b['timestamp'] != null ? DateTime.parse(b['timestamp']) : DateTime.fromMillisecondsSinceEpoch(0);
                  return timeA.compareTo(timeB);
                });

                return ListView.builder(
                  controller: _timelineScrollController,
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final act = activities[index];
                    final isSelected = act['id'] == _selectedActivityId;
                    
                    final timestamp = act['timestamp'] != null ? DateTime.parse(act['timestamp']) : DateTime.now();
                    final timeStr = DateFormat('hh:mm a').format(timestamp.toLocal());
                    final title = act['title'] ?? 'Activity Logged';
                    final description = act['description'] ?? 'No description provided';
                    final thumbUrl = _extractThumbUrl(act);
                    
                    double lat = 0;
                    double lng = 0;
                    if (act['latitude'] != null && act['longitude'] != null) {
                      lat = (act['latitude'] as num).toDouble();
                      lng = (act['longitude'] as num).toDouble();
                    }

                    return GestureDetector(
                      onTap: () {
                        if (lat != 0 && lng != 0) {
                          _selectActivity(act['id'], LatLng(lat, lng));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? _C.blue.withValues(alpha: 0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? _C.blue : _C.border, width: isSelected ? 2.0 : 1.0),
                          boxShadow: isSelected
                              ? [BoxShadow(color: _C.blue.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Full-width thumbnail when selected ──────────
                            if (isSelected && thumbUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: Image.network(
                                  thumbUrl,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    color: _C.blue.withValues(alpha: 0.07),
                                    child: const Center(child: Icon(PhosphorIconsRegular.image, color: _C.textFaint, size: 28)),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Time chip ────────────────────────────
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? _C.blue : _C.greenLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : _C.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _C.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          description,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: _C.textBody,
                                          ),
                                          maxLines: isSelected ? 3 : 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (lat != 0 && lng != 0) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(PhosphorIconsRegular.mapPin, size: 11, color: _C.textFaint),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: FutureBuilder<String>(
                                                  future: LocationNamingService().getLocationName(lat, lng),
                                                  builder: (context, snapshot) {
                                                    return Text(
                                                      snapshot.data ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _C.textFaint),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // ── Compact thumb (only when NOT selected and image exists) ─
                                  if (!isSelected && thumbUrl != null) ...[
                                    const SizedBox(width: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        thumbUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56, height: 56,
                                          color: _C.border,
                                          child: const Icon(PhosphorIconsRegular.image, size: 20, color: _C.textFaint),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
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
        Container(width: 4, height: 3, margin: const EdgeInsets.only(right: 2), decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(2))),
        Container(width: 4, height: 3, margin: const EdgeInsets.only(right: 2), decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(2))),
        Container(width: 4, height: 3, decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}

// ── Tooltip triangle painter ───────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}
