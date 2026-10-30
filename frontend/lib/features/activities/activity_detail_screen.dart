import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String fontFamily = 'Poppins';
    final activityAsync = ref.watch(activityDetailsProvider(activityId));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base colors based on theme
    final scaffoldBg = isDark ? const Color(0xFF121212) : theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : theme.cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final primaryGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: ApiResultBuilder<Map<String, dynamic>>(
        asyncValue: activityAsync,
        onRetry: () => ref.refresh(activityDetailsProvider(activityId)),
        onData: (activity) {
          final title = activity['title'] ?? 'Untitled Activity';
          final description =
              activity['description'] ?? 'No description provided.';
          final objective = activity['objectives'] ?? 'No objective provided.';
          final status = activity['status'] ?? 'DRAFT';

          // Map dynamic status colors for light and dark modes
          Color statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
          Color statusBgColor = isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC);
          
          if (status == 'DRAFT') {
            statusColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
            statusBgColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
          } else if (status == 'UNDER_REVIEW') {
            statusColor = isDark ? const Color(0xFFFDE047) : const Color(0xFFEAB308);
            statusBgColor = isDark ? const Color(0xFF713F12) : const Color(0xFFFEF08A);
          } else if (status == 'REJECTED') {
            statusColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
            statusBgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
          } else if (status == 'REVISION_REQUESTED') {
            statusColor = isDark ? const Color(0xFFFDBA74) : const Color(0xFFF97316);
            statusBgColor = isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5);
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
              final rawPath =
                  ev['storagePath'] ??
                  ev['url'] ??
                  ev['firebaseUrl'] ??
                  ev['downloadUrl'] ??
                  ev['storedName'] ??
                  ev['originalName'];
              if (rawPath != null) {
                imageUrl = rawPath as String?;
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
                        ImageUtils.getFullImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[300],
                            child: Center(
                              child: Icon(
                                PhosphorIconsRegular.image,
                                size: 48,
                                color: isDark ? const Color(0xFF6B7280) : Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[300],
                        child: Center(
                          child: Icon(
                            PhosphorIconsRegular.image,
                            size: 48,
                            color: isDark ? const Color(0xFF6B7280) : Colors.grey,
                          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        _buildTopIconBtn(
                          icon: PhosphorIconsRegular.caretLeft,
                          isDark: isDark,
                          onTap: () => Navigator.pop(context),
                        ),
                        // Center Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC))
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Activity Details',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF4ADE80) : Colors.black,
                            ),
                          ),
                        ),
                        // Edit Button (Only for specific statuses)
                        if (activity['status'] == 'DRAFT' ||
                            activity['status'] == 'REJECTED' ||
                            activity['status'] == 'REVISION_REQUESTED')
                          _buildTopIconBtn(
                            icon: PhosphorIconsRegular.pencilSimple,
                            isDark: isDark,
                            onTap: () => context.push(
                              '/field-session?id=${activity['id']}',
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Main Content Card (Bottom overlapping)
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.45 -
                    32, // Overlap by 32px
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.only(
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
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 32,
                        bottom: 100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Badges Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
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
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF111827),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Info Items
                          _buildInfoItem(
                            icon: PhosphorIconsRegular.mapPin,
                            title: 'Location',
                            subtitle:
                                (activity['locationName'] != null &&
                                    activity['locationName']
                                        .toString()
                                        .isNotEmpty)
                                ? '${activity['locationName']}${activity['county'] != null ? ', ${activity['county']}' : ''}'
                                : 'Lat: ${activity['latitude']?.toStringAsFixed(4) ?? '-'}, Lng: ${activity['longitude']?.toStringAsFixed(4) ?? '-'}',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                          _buildSupervisorItem(context, activity, isDark),
                          const SizedBox(height: 24),
                          _buildInfoItem(
                            icon: PhosphorIconsRegular.package,
                            title: 'Objective',
                            subtitle: objective,
                            isMultiLineSubtitle: true,
                            isDark: isDark,
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
                      final review = (reviews != null && reviews.isNotEmpty)
                          ? reviews.last as Map<String, dynamic>
                          : null;
                      if (review != null) {
                        _showFeedbackModal(context, review, isDark);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No feedback available yet.',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            ),
                            backgroundColor: isDark ? const Color(0xFF333333) : Colors.white,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
  Widget _buildTopIconBtn({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC)).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: isDark ? const Color(0xFF4ADE80) : Colors.black, 
          size: 20
        ),
      ),
    );
  }

  // Standard Info Item
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    bool isMultiLineSubtitle = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLineSubtitle
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: isDark ? const Color(0xFF4ADE80) : Colors.black, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
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
  Widget _buildSupervisorItem(
    BuildContext context,
    Map<String, dynamic> activity,
    bool isDark,
  ) {
    final review = activity['review'] as Map<String, dynamic>?;
    final status = review != null ? review['status'] : activity['status'];
    final reviewerName = review?['reviewerName'] ?? 'Pending Reviewer';
    final hasReview = review != null;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          PhosphorIconsRegular.userCircle,
          color: isDark ? const Color(0xFF4ADE80) : Colors.black,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supervisor',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: '$reviewerName, Status: '),
                    TextSpan(
                      text: status ?? 'Pending',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654)
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (hasReview)
                GestureDetector(
                  onTap: () => _showFeedbackModal(context, review, isDark),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Full Feedback ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                        ),
                      ),
                      Icon(
                        PhosphorIconsRegular.arrowRight,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                        size: 16,
                      ),
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
  void _showFeedbackModal(BuildContext context, Map<String, dynamic> review, bool isDark) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final reviewerName = reviewer?['name'] ?? 'Unknown Supervisor';
    final initial = reviewerName.isNotEmpty
        ? reviewerName.substring(0, 1).toUpperCase()
        : '?';
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
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: 32,
          ),
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
                      color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
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
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: isDark ? Colors.white70 : const Color(0xFF374151),
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
                      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: isDark ? const BorderSide(color: Color(0xFF333333)) : BorderSide.none,
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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