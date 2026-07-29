import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String fontFamily = 'Roboto';
    const Color primaryGreen = Color(0xFF1BA654);
    const Color lightGreenBadge = Color(0xFFC3DFCC);
    const Color textDark = Color(0xFF111827);
    const Color textGrey = Color(0xFF6B7280);

    final activityAsync = ref.watch(activityDetailsProvider(activityId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: ApiResultBuilder<Map<String, dynamic>>(
        asyncValue: activityAsync,
        onRetry: () => ref.refresh(activityDetailsProvider(activityId)),
        onData: (activity) {
          final title = activity['title'] ?? 'Untitled Activity';
          final description = activity['description'] ?? 'No description provided.';
          final objective = activity['objectives'] ?? 'No objective provided.';
          final status = activity['status'] ?? 'DRAFT';
          
          // Map status to colors
          Color statusColor = const Color(0xFF1BA654);
          Color statusBgColor = const Color(0xFFC3DFCC);
          if (status == 'DRAFT') {
            statusColor = const Color(0xFF3B82F6);
            statusBgColor = const Color(0xFFDBEAFE);
          } else if (status == 'UNDER_REVIEW') {
            statusColor = const Color(0xFFEAB308);
            statusBgColor = const Color(0xFFFEF08A);
          } else if (status == 'REJECTED') {
            statusColor = const Color(0xFFEF4444);
            statusBgColor = const Color(0xFFFEE2E2);
          }

          // Format time
          String timeStr = 'N/A';
          if (activity['timestamp'] != null) {
            final dt = DateTime.parse(activity['timestamp']).toLocal();
            timeStr = DateFormat('dd MMM yyyy').format(dt);
          }

          // Extract image URL
          String? imageUrl;
          final evidenceList = activity['evidence'] as List<dynamic>? ?? [];
          for (final ev in evidenceList) {
            final mimeType = ev['mimeType'] as String? ?? '';
            if (mimeType.startsWith('image/')) {
              final path = ev['storagePath'];
              if (path != null) {
                imageUrl = '${AppConstants.apiUrl}/$path';
                break;
              }
            }
          }

          return Stack(
            children: [
              // 1. Background Image (Top Half)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(PhosphorIconsRegular.image, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(PhosphorIconsRegular.image, size: 48, color: Colors.grey),
                        ),
                      ),
              ),

              // 2. Custom App Bar / Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        _buildTopIconBtn(
                          icon: PhosphorIconsRegular.caretLeft,
                          onTap: () => Navigator.pop(context),
                        ),
                        // Center Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: lightGreenBadge.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Activity Details',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Menu Button
                        _buildTopIconBtn(
                          icon: PhosphorIconsRegular.dotsThreeVertical,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Main Content Card (Bottom overlapping)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.45 - 32, // Overlap by 32px
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Badges Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              Text(
                                'Date: $timeStr',
                                style: const TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Info Items
                          _buildInfoItem(
                            icon: PhosphorIconsRegular.mapPin,
                            title: 'Location',
                            subtitle: 'Lat: ${activity['latitude']?.toStringAsFixed(4) ?? '-'}, Lng: ${activity['longitude']?.toStringAsFixed(4) ?? '-'}',
                          ),
                          const SizedBox(height: 24),
                          _buildSupervisorItem(context, activity),
                          const SizedBox(height: 24),
                          _buildInfoItem(
                            icon: PhosphorIconsRegular.package,
                            title: 'Objective',
                            subtitle: objective,
                            isMultiLineSubtitle: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Fixed Bottom Button
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final reviews = activity['reviews'] as List<dynamic>?;
                      final review = (reviews != null && reviews.isNotEmpty) ? reviews.last as Map<String, dynamic> : null;
                      if (review != null) {
                        _showFeedbackModal(context, review);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No feedback available yet.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'View Feedback',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper for Top Buttons (Back, Menu)
  Widget _buildTopIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFC3DFCC).withOpacity(0.9), // Light green
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  // Standard Info Item
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isMultiLineSubtitle = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLineSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.black, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Special Supervisor Item with Feedback Link
  Widget _buildSupervisorItem(BuildContext context, Map<String, dynamic> activity) {
    final review = activity['review'] as Map<String, dynamic>?;
    final status = review != null ? review['status'] : activity['status'];
    final reviewerName = review?['reviewerName'] ?? 'Pending Reviewer';
    final hasReview = review != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(PhosphorIconsRegular.userCircle, color: Colors.black, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supervisor',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: '$reviewerName, Status: '),
                    TextSpan(
                      text: status ?? 'Pending',
                      style: const TextStyle(color: Color(0xFF1BA654)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (hasReview)
                GestureDetector(
                  onTap: () => _showFeedbackModal(context, review!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View Full Feedback ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1BA654),
                        ),
                      ),
                      Icon(PhosphorIconsRegular.arrowRight, color: Color(0xFF1BA654), size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom Sheet Modal for Feedback
  void _showFeedbackModal(BuildContext context, Map<String, dynamic> review) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final reviewerName = reviewer?['name'] ?? 'Unknown Supervisor';
    final initial = reviewerName.isNotEmpty ? reviewerName.substring(0, 1).toUpperCase() : '?';
    final comments = review['comments'] ?? 'No additional comments provided.';
    
    // Attempt to format date
    String dateStr = '';
    if (review['createdAt'] != null) {
      try {
        final dt = DateTime.parse(review['createdAt']);
        dateStr = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {}
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFC3DFCC),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1BA654),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  comments,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

