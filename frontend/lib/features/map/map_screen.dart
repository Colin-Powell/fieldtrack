import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/features/map/providers/student_map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  // Fallback centre if GPS hasn't locked yet (Kilifi/Pwani University area)
  static const LatLng _fallbackLocation = LatLng(-1.2921, 36.8219); // Default Nairobi fallback

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final mapState = ref.watch(studentMapProvider);
    
    final LatLng userLocation = (!locState.isLocating && locState.error == null)
        ? LatLng(locState.latitude, locState.longitude)
        : _fallbackLocation;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 1. Full Screen Map (OpenStreetMap via flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fieldtrack.app',
              ),
              // Route Layer
              if (mapState.visitedRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.visitedRoute,
                      strokeWidth: 4.0,
                      color: const Color(0xFF1BA654),
                    ),
                  ],
                ),
              // Dynamic Markers Layer
              MarkerLayer(
                markers: [
                  // Visited locations (small dots)
                  ...mapState.visitedRoute.map((point) => Marker(
                    point: point,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1BA654).withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )),
                  // Activity locations
                  ...mapState.activityLocations.map((markerData) {
                    final user = ref.read(authProvider).user;
                    final avatar = markerData.avatarUrl ?? user?.avatarUrl;
                    
                    return Marker(
                      point: markerData.position,
                      width: 48,
                      height: 48,
                      child: Tooltip(
                        message: '${markerData.title}\n${markerData.description}',
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF97316), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            backgroundImage: avatar != null && avatar.isNotEmpty
                                ? NetworkImage(ImageUtils.getFullImageUrl(avatar)) 
                                : null,
                            child: avatar == null 
                                ? const Icon(PhosphorIconsFill.userCircle, color: Color(0xFF9CA3AF), size: 24)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Supervisor Location
                  if (mapState.supervisorLocation != null)
                    Marker(
                      point: mapState.supervisorLocation!,
                      width: 32,
                      height: 32,
                      child: const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 32),
                    ),
                  // Current User location marker
                  if (!locState.isLocating && locState.error == null)
                    Marker(
                      point: userLocation,
                      width: 40,
                      height: 40,
                      child: _buildUserLocationDot(),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top "Map" Pill
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BA654),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Map',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 3. Map Legend (Bottom Left)
          Positioned(
            bottom: 112, // Positioned above the bottom nav bar
            left: 24,
            child: _buildLegend(),
          ),

          // 4. Locate Me FAB (Bottom Right)
          Positioned(
            bottom: 112,
            right: 24,
            child: _buildLocateFab(locState),
          ),

        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  /// Animated blue dot with accuracy ripple for user's live position.
  Widget _buildUserLocationDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer accuracy circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6).withOpacity(0.15),
          ),
        ),
        // Inner solid dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.35),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(
            icon: Icons.gps_fixed,
            color: const Color(0xFF3B82F6), // Blue
            label: 'My Location',
          ),
          const SizedBox(height: 16),
          _buildLegendItem(
            icon: Icons.location_on,
            color: const Color(0xFF1BA654), // Green
            label: 'Visited Locations',
          ),
          const SizedBox(height: 16),
          _buildLegendItem(
            icon: Icons.location_on,
            color: const Color(0xFFF97316), // Orange
            label: 'Activity Locations',
          ),
          const SizedBox(height: 16),
          _buildLegendItem(
            icon: Icons.location_on,
            color: const Color(0xFF3B82F6), // Blue
            label: 'Supervisors',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLocateFab(LocationState locState) {
    return InkWell(
      onTap: () {
        if (!locState.isLocating && locState.error == null) {
          _mapController.move(
            LatLng(locState.latitude, locState.longitude),
            _mapController.camera.zoom,
          );
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: locState.isLocating
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF3B82F6),
                ),
              )
            : const Icon(
                PhosphorIconsRegular.crosshair,
                color: Colors.black,
                size: 28,
              ),
      ),
    );
  }
}
