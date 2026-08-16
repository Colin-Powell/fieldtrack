import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/shared/widgets/skeleton_loader.dart';
import 'package:fieldtrack/shared/widgets/empty_state_widget.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import '../widgets/supervisor_top_header.dart';
import '../repositories/student_repository.dart';
import 'package:fieldtrack/shared/models/student_data.dart';

final _studentDailyLogProvider = FutureProvider.family.autoDispose<DailyFieldLog?, String>((ref, studentId) async {
  final repo = StudentRepository(); // Create or get from provider
  try {
    final logs = await repo.fetchStudentDailyLogs(studentId);
    if (logs.isEmpty) return null;
    return logs.first; // Returning latest daily log for now
  } catch (_) {
    return null;
  }
});

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF3F4F6); // Light grey background
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 32.0;
}

class SupervisorDailyFieldLogsScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final bool embedded;
  const SupervisorDailyFieldLogsScreen({
    super.key,
    required this.studentId,
    this.studentName = '',
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildBody(context, ref);
    if (embedded) {
      return body;
    }
    return Container(
      color: _C.bg,
      child: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(studentActivitiesByStudentIdProvider({'studentId': studentId}));

    return ApiResultBuilder<List<dynamic>>(
      asyncValue: activitiesAsync,
      onRetry: () => ref.refresh(studentActivitiesByStudentIdProvider({'studentId': studentId})),
      customLoading: const Padding(
        padding: EdgeInsets.all(24.0),
        child: ListSkeletonLoader(itemCount: 4, itemHeight: 120),
      ),
      onData: (activities) {
        // Resolve student name: prefer passed prop, fallback to first activity's user name
        final resolvedName = studentName.isNotEmpty
            ? studentName
            : (activities.isNotEmpty
                ? (activities.first['user']?['name'] as String? ?? 'Student')
                : 'Student');

        if (activities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No field logs found.', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
            ),
          );
        }

        // Generate timeline items
        final List<Widget> timelineItems = [];
        final List<Widget> activityItems = [];
        
        timelineItems.add(
          _buildTimelineItem(
            context,
            time: '08:00 AM', // Mock checkin time
            title: 'Checked In',
            subtitle: 'Field Location',
            iconWidget: _buildSolidIcon(PhosphorIconsBold.check, _C.green),
            isLast: false,
          )
        );

        int evidenceCount = 0;
        for (int i = 0; i < activities.length; i++) {
          final activity = activities[i];
          final title = activity['title'] ?? 'Untitled Activity';
          final status = activity['status'] ?? 'DRAFT';
          
          String timeStr = '';
          if (activity['timestamp'] != null) {
            final dt = DateTime.parse(activity['timestamp']).toLocal();
            timeStr = DateFormat('hh:mm a').format(dt);
          }
          
          String? imageUrl;
          final evidenceList = activity['evidence'] as List<dynamic>? ?? [];
          evidenceCount += evidenceList.length;
          
          for (final ev in evidenceList) {
            final mimeType = ev['mimeType'] as String? ?? '';
            if (mimeType.startsWith('image/')) {
              final path = ev['storagePath'];
              if (path != null) {
                imageUrl = path;
                break;
              }
            }
          }

          timelineItems.add(
            _buildTimelineItem(
              context,
              time: timeStr,
              title: 'Activity Submitted',
              subtitle: title,
              evidenceCount: evidenceList.length,
              imgUrl: imageUrl != null ? ImageUtils.getFullImageUrl(imageUrl) : 'https://images.unsplash.com/photo-1627914041132-720da5d7df53?auto=format&fit=crop&w=150&q=80',
              isLast: false,
              activityId: activity['id'] ?? '',
            )
          );

          activityItems.add(
            _buildActivityItem(
              context,
              title: title,
              time: timeStr,
              statusLabel: status == 'APPROVED' ? 'Reviewed' : (status == 'DRAFT' ? 'In Progress' : 'Submitted'),
              statusColor: status == 'APPROVED' ? _C.green : _C.textDark,
              statusBg: status == 'APPROVED' ? _C.greenLight : _C.bg,
              imgUrl: imageUrl != null ? ImageUtils.getFullImageUrl(imageUrl) : 'https://images.unsplash.com/photo-1627914041132-720da5d7df53?auto=format&fit=crop&w=150&q=80',
              imagesCount: '${evidenceList.where((e) => (e['mimeType'] as String? ?? '').startsWith('image/')).length}',
              filesCount: '${evidenceList.where((e) => !(e['mimeType'] as String? ?? '').startsWith('image/')).length}',
              activityId: activity['id'] ?? '',
            )
          );
        }

        timelineItems.add(
          _buildTimelineItem(
            context,
            time: '05:00 PM', // Mock checkout time
            title: 'Checked Out',
            subtitle: 'Field Location',
            iconWidget: _buildSolidIcon(PhosphorIconsBold.check, const Color(0xFF3B82F6)),
            isLast: true,
          )
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, resolvedName),
              const SizedBox(height: 40),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary & Activities on top for mobile
                        const Text(
                          'Daily Summary',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Green Summary Pills
                        LayoutBuilder(builder: (context, pillConstraints) {
                          final isTiny = pillConstraints.maxWidth < 400;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildSummaryPill('Total Activities', '${activities.length}')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildSummaryPill('Evidence Files', '$evidenceCount')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final logAsync = ref.watch(_studentDailyLogProvider(studentId));
                                        return logAsync.when(
                                          data: (log) {
                                            final duration = log?.duration;
                                            final timeStr = duration != null
                                                ? '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m'
                                                : '0h 00m';
                                            return _buildSummaryPill('Time in Field', timeStr);
                                          },
                                          loading: () => _buildSummaryPill('Time in Field', '...'),
                                          error: (_, __) => _buildSummaryPill('Time in Field', '-'),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final logAsync = ref.watch(_studentDailyLogProvider(studentId));
                                        return logAsync.when(
                                          data: (log) {
                                            final distance = log?.distanceTravelled;
                                            final distStr = distance != null
                                                ? '${distance.toStringAsFixed(1)} km'
                                                : '0.0 km';
                                            return _buildSummaryPill('Distance Travelled', distStr);
                                          },
                                          loading: () => _buildSummaryPill('Distance Travelled', '...'),
                                          error: (_, __) => _buildSummaryPill('Distance Travelled', '-'),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                        // Activities Card
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1F2937),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: const Text(
                                  'Activities for Today',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                                ),
                                child: Column(
                                  children: activityItems,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Field Session Timeline
                        const Text(
                          'Field Session Timeline',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...timelineItems,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Field Session Timeline
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Field Session Timeline',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _C.textDark,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...timelineItems,
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),

                      // Right Column: Summary & Activities
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Daily Summary Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daily Summary',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.greenLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _C.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Green Summary Pills
                            Row(
                              children: [
                                Expanded(child: _buildSummaryPill('Total Activities', '${activities.length}')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSummaryPill('Evidence Files', '$evidenceCount')),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, _) {
                                      final logAsync = ref.watch(_studentDailyLogProvider(studentId));
                                      return logAsync.when(
                                        data: (log) {
                                          final duration = log?.duration;
                                          final timeStr = duration != null
                                              ? '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m'
                                              : '0h 00m';
                                          return _buildSummaryPill('Time in Field', timeStr);
                                        },
                                        loading: () => _buildSummaryPill('Time in Field', '...'),
                                        error: (_, __) => _buildSummaryPill('Time in Field', '-'),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, _) {
                                      final logAsync = ref.watch(_studentDailyLogProvider(studentId));
                                      return logAsync.when(
                                        data: (log) {
                                          final distance = log?.distanceTravelled;
                                          final distStr = distance != null
                                              ? '${distance.toStringAsFixed(1)} km'
                                              : '0.0 km';
                                          return _buildSummaryPill('Distance Travelled', distStr);
                                        },
                                        loading: () => _buildSummaryPill('Distance Travelled', '...'),
                                        error: (_, __) => _buildSummaryPill('Distance Travelled', '-'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // Activities Card
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Dark Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1F2937),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(_C.cardRadius)),
                                    ),
                                    child: const Text(
                                      'Activities for Today',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // White Body
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(_C.cardRadius)),
                                    ),
                                    child: Column(
                                      children: activityItems,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 1. HEADER ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String resolvedName) {
    return SupervisorTopHeader(
      title: 'Daily Field Logs',
      subtitleWidget: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/supervisor/students'),
            child: const Text(
              'Students',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _C.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              PhosphorIconsRegular.caretRight,
              size: 14,
              color: _C.textMuted,
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/supervisor/student/$studentId'),
            child: Text(
              resolvedName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _C.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              PhosphorIconsRegular.caretRight,
              size: 14,
              color: _C.textMuted,
            ),
          ),
          const Text(
            'Field Logs',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: _C.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. SUMMARY PILL ───────────────────────────────────────────────────
  Widget _buildSummaryPill(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.green,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. SOLID ICON BUILDER ─────────────────────────────────────────────
  Widget _buildSolidIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ── 4. TIMELINE ITEM ──────────────────────────────────────────────────
  Widget _buildTimelineItem(
    BuildContext context, {
    required String time,
    required String title,
    required String subtitle,
    Widget? iconWidget,
    String? imgUrl,
    int? evidenceCount,
    required bool isLast,
    String? activityId,
  }) {
    final bool isActivity = activityId != null;
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic Column (Icon/Image + Line)
          Column(
            children: [
              if (iconWidget != null)
                iconWidget
              else if (imgUrl != null)
                ClipOval(
                  child: Image.network(
                    imgUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: _C.border,
                      child: const Icon(
                        PhosphorIconsRegular.image,
                        color: _C.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    painter: _DottedLinePainter(),
                    size: const Size(1, double.infinity),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 40.0,
              ), // Spacing to next item
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _C.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time & Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.textDark,
                        ),
                      ),
                      if (evidenceCount != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _C.greenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$evidenceCount Evidence',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _C.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isActivity) {
      return GestureDetector(
        onTap: () {
          context.go(
            '/supervisor/student/$studentId/activity/$activityId',
            extra: <String, String>{
              'studentName': studentName,
              'activityTitle': title,
            },
          );
        },
        child: content,
      );
    }

    return content;
  }

  // ── 5. ACTIVITY CARD ITEM ─────────────────────────────────────────────
  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String time,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required String imgUrl,
    required String imagesCount,
    required String filesCount,
    String? activityId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Square
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ImageUtils.getFullImageUrl(imgUrl),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: _C.border,
                child: const Icon(
                  PhosphorIconsRegular.image,
                  color: _C.textMuted,
                ),
              ),
            ),
          ),
        const SizedBox(width: 24),

        // Titles & Status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: _C.textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Evidence Icons
        Row(
          children: [
            const Icon(
              PhosphorIconsRegular.image,
              size: 20,
              color: _C.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              imagesCount,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
              ),
            ),
            const SizedBox(width: 24),
            const Icon(
              PhosphorIconsRegular.fileText,
              size: 20,
              color: _C.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              filesCount,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
              ),
            ),
          ],
        ),

        const SizedBox(width: 40),

        // View Button
        ElevatedButton(
          onPressed: () {
            if (activityId != null) {
              context.go(
                '/supervisor/student/$studentId/activity/$activityId',
                extra: <String, String>{
                  'studentName': studentName,
                  'activityTitle': title,
                },
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.greenLight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text(
            'View',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.green,
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ==========================================
// DOTTED LINE PAINTER FOR TIMELINE
// ==========================================
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.textFaint
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 8; // Margin from the top icon

    while (startY < size.height - 8) {
      // Margin from bottom icon
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

