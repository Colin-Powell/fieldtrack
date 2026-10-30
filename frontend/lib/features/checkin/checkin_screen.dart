import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/core/providers/checkin_provider.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);
    final checkInState = ref.watch(checkInProvider);
    const String fontFamily = 'Poppins';

    final LatLng currentPosition =
        (locState.latitude != 0.0 && locState.longitude != 0.0)
        ? LatLng(locState.latitude, locState.longitude)
        : const LatLng(-3.6305, 39.8499);

    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Theme Colors
    final scaffoldBg = isDark ? const Color(0xFF121212) : theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : theme.cardColor;
    final pillBg = isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC).withValues(alpha: 0.6);
    final pillTextColor = isDark ? const Color(0xFF4ADE80) : Colors.black;
    final primaryGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pillBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsRegular.caretLeft,
                        color: pillTextColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Check In',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: pillTextColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Location Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.06,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locState.isLocating
                              ? 'Locating...'
                              : locState.locationName,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'GPS Accuracy',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locState.isLocating
                              ? '—'
                              : '±${locState.accuracy.toStringAsFixed(0)} m',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Map + Overlaid Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: currentPosition,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.fieldtrack',
                            // Optional dark mode filter for the map tiles
                            tileBuilder: isDark 
                                ? (context, tileWidget, tile) => ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      -1,  0,  0, 0, 255,
                                       0, -1,  0, 0, 255,
                                       0,  0, -1, 0, 255,
                                       0,  0,  0, 1,   0,
                                    ]),
                                    child: tileWidget,
                                  )
                                : null,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPosition,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 0),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: dividerColor),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.mapPin,
                                  color: subtextColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 13,
                                          color: subtextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        locState.locationName,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: dividerColor),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Check In Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: checkInState.isLoading || locState.isLocating
                      ? null
                      : () async {
                          final success = await ref
                              .read(checkInProvider.notifier)
                              .checkIn();
                          if (success && context.mounted) {
                            ToastService.showSuccess(
                              'Checked in successfully! Location captured.',
                            );
                            context.pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654),
                    foregroundColor: isDark ? const Color(0xFF4ADE80) : Colors.white,
                    disabledBackgroundColor: isDark 
                        ? const Color(0xFF14532D).withValues(alpha: 0.5) 
                        : const Color(0xFF9DC9B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: checkInState.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? const Color(0xFF4ADE80) : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          locState.isLocating
                              ? 'Waiting for GPS...'
                              : 'Check In',
                          style: const TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}