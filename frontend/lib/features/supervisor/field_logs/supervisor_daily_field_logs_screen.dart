import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/supervisor_top_header.dart';
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

class SupervisorDailyFieldLogsScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final bool embedded;
  const SupervisorDailyFieldLogsScreen({
    super.key,
    required this.studentId,
    this.studentName = 'Jane Akinyi',
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 40),

          Row(
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

                    // Timeline Items
                    _buildTimelineItem(
                      context,
                      time: '07:52 AM',
                      title: 'Checked In',
                      subtitle: 'Mnarani Creek, Kilifi County\nAccuracy: 4.2 m',
                      iconWidget: _buildSolidIcon(
                        PhosphorIconsBold.check,
                        _C.green,
                      ),
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      context,
                      time: '08:15 AM',
                      title: 'Activity Submitted',
                      subtitle: 'Mangrove Vegetation\nSurvey',
                      evidenceCount: 3,
                      imgUrl:
                          'https://images.unsplash.com/photo-1627914041132-720da5d7df53?auto=format&fit=crop&w=150&q=80',
                      isLast: false,
                      activityId: 'act-001',
                    ),
                    _buildTimelineItem(
                      context,
                      time: '10:35 AM',
                      title: 'Activity Submitted',
                      subtitle: 'Water Quality Sampling',
                      evidenceCount: 4,
                      imgUrl:
                          'https://images.unsplash.com/photo-1616423640778-28d1b53229bd?auto=format&fit=crop&w=150&q=80',
                      isLast: false,
                      activityId: 'act-002',
                    ),
                    _buildTimelineItem(
                      context,
                      time: '10:35 AM',
                      title: 'Activity Submitted',
                      subtitle: 'Sediment Analysis',
                      evidenceCount: 2,
                      imgUrl:
                          'https://images.unsplash.com/photo-1544257124-741165bc6f23?auto=format&fit=crop&w=150&q=80',
                      isLast: false,
                      activityId: 'act-003',
                    ),
                    _buildTimelineItem(
                      context,
                      time: '10:35 AM',
                      title: 'Checked Out',
                      subtitle:
                          'Mnarani Creek, Kilifi County\nTotal Time: 7h 20m',
                      iconWidget: _buildSolidIcon(
                        PhosphorIconsBold.check,
                        const Color(0xFF3B82F6),
                      ), // Blue check
                      isLast: true,
                    ),
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
                        Expanded(
                          child: _buildSummaryPill('Total Activities', '3'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryPill('Evidence Files', '9'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryPill('Time in Field', '7h 20m'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryPill(
                            'Distanced Travelled',
                            '12.6 km',
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
                            color: Colors.black.withOpacity(0.03),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1F2937), // Dark grey/black
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(_C.cardRadius),
                              ),
                            ),
                            child: const Text(
                              'Activities for 21 July 2026',
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
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(_C.cardRadius),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildActivityItem(
                                  context,
                                  title: 'Mangrove Vegetation Survey',
                                  time: '08:15 AM - 09:05 AM',
                                  statusLabel: 'Reviewed',
                                  statusColor: _C.green,
                                  statusBg: _C.greenLight,
                                  imgUrl:
                                      'https://images.unsplash.com/photo-1627914041132-720da5d7df53?auto=format&fit=crop&w=150&q=80',
                                  imagesCount: '3',
                                  filesCount: '1',
                                  activityId: 'act-001',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Divider(color: _C.border, height: 1),
                                ),
                                _buildActivityItem(
                                  context,
                                  title: 'Water Quality Sampling',
                                  time: '09:15 AM - 10:15 AM',
                                  statusLabel: 'Pending Review',
                                  statusColor: const Color(0xFFF97316),
                                  statusBg: const Color(0xFFFFEDD5),
                                  imgUrl:
                                      'https://images.unsplash.com/photo-1616423640778-28d1b53229bd?auto=format&fit=crop&w=150&q=80',
                                  imagesCount: '4',
                                  filesCount: '1',
                                  activityId: 'act-002',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Divider(color: _C.border, height: 1),
                                ),
                                _buildActivityItem(
                                  context,
                                  title: 'Sediment Analysis',
                                  time: '10:35 AM - 11:20 AM',
                                  statusLabel: 'Pending Review',
                                  statusColor: const Color(0xFFF97316),
                                  statusBg: const Color(0xFFFFEDD5),
                                  imgUrl:
                                      'https://images.unsplash.com/photo-1544257124-741165bc6f23?auto=format&fit=crop&w=150&q=80',
                                  imagesCount: '2',
                                  filesCount: '1',
                                  activityId: 'act-003',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 1. HEADER ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final exportBtn = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _C.textDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
          side: const BorderSide(color: _C.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: const Text(
        'Export Log',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

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
              studentName,
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
      trailingWidget: exportBtn,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image Square
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imgUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
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
