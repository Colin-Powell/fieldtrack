import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../evidence/supervisor_evidence_screen.dart';
import '../review/supervisor_review_screen.dart';
import '../location/supervisor_location_screen.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF0F2F5); // Light grey background matching Figma
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF9CA3AF);
  static const textBody = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const red = Color(0xFFEF4444);
  static const cardRadius = 32.0;
}

class SupervisorActivityDetailsScreen extends StatefulWidget {
  final String studentId;
  final String activityId;
  final String studentName;
  final String activityTitle;
  final bool embedded;
  const SupervisorActivityDetailsScreen({
    super.key,
    required this.studentId,
    required this.activityId,
    this.studentName = 'Jane Akinyi',
    this.activityTitle = 'Mangrove Vegetation Survey',
    this.embedded = false,
  });

  @override
  State<SupervisorActivityDetailsScreen> createState() =>
      _SupervisorActivityDetailsScreenState();
}

class _SupervisorActivityDetailsScreenState
    extends State<SupervisorActivityDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildCustomTabs(),
          const SizedBox(height: 32),

          // Tab Views (Expanded to take remaining fixed height)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Keeps it fixed
              children: [
                _buildOverviewTab(),
                SupervisorEvidenceScreen(
                  studentId: widget.studentId,
                  activityId: widget.activityId,
                ),
                SupervisorLocationScreen(studentId: widget.studentId),
                SupervisorReviewScreen(
                  studentId: widget.studentId,
                  activityId: widget.activityId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. HEADER (Title, Breadcrumbs & Reviewed Badge) ───────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Details & Review',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBreadcrumb(
                  'Students',
                  onTap: () => context.go('/supervisor/students'),
                ),
                _buildBreadcrumbCaret(),
                _buildBreadcrumb(
                  widget.studentName,
                  onTap: () =>
                      context.go('/supervisor/student/${widget.studentId}'),
                ),
                _buildBreadcrumbCaret(),
                _buildBreadcrumb(
                  'Field Logs',
                  onTap: () => context.go(
                    '/supervisor/student/${widget.studentId}/logs',
                  ),
                ),
                _buildBreadcrumbCaret(),
                Text(
                  widget.activityTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _C.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        // "Reviewed" Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _C.greenLight,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Text(
            'Reviewed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: _C.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBreadcrumbCaret() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(
        PhosphorIconsRegular.caretRight,
        size: 12,
        color: _C.textMuted,
      ),
    );
  }

  // ── 2. CUSTOM PILL TABS ───────────────────────────────────────────────
  Widget _buildCustomTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTabPill('Overview', 0, hasWarning: false),
        _buildTabPill('Evidence(7)', 1, hasWarning: true),
        _buildTabPill('Location', 2, hasWarning: true),
        _buildTabPill('Review (2)', 3, hasWarning: true),
      ],
    );
  }

  Widget _buildTabPill(String title, int index, {required bool hasWarning}) {
    final bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? _C.green : Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _C.textBody,
              ),
            ),
            if (hasWarning) ...[
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsRegular.xCircle,
                size: 18,
                color: isActive ? Colors.white : _C.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. OVERVIEW TAB CONTENT ───────────────────────────────────────────
  Widget _buildOverviewTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Activity Information
        Expanded(
          flex: 11,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_C.cardRadius),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Information',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildInfoRow('Tittle', widget.activityTitle),
                  _buildInfoRow('Category', 'Vegetation Survey'),
                  _buildInfoRow(
                    'Date & Time',
                    '21 July 2026, 09:15AM - 09:05AM',
                  ),
                  _buildInfoRow(
                    'Location',
                    'Mnarani Creek, Kilifi County',
                    subValue: '-3.9572, 39.667',
                  ),
                  _buildInfoRow('Accuracy', '4.2 m'),
                  _buildInfoRow('Method Used', 'Transact and Quadrant Method'),
                  _buildInfoRow(
                    'Objective',
                    'Assess the species competition, density\nand health of mangrove vegetation',
                  ),
                  _buildInfoRow(
                    'Remarks',
                    'Vegetation density high near\ntransacts',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),

        // Right Column: Descriptions, Findings & Review (Connected by dotted line)
        Expanded(
          flex: 9,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // The Cards
              Column(
                children: [
                  _buildRightCard(
                    title: 'Description',
                    content:
                        'Assessed the species composition, density and health of mangrove, Vegetation along the Mnarani Creek transects',
                  ),
                  const SizedBox(height: 24),
                  _buildRightCard(
                    title: 'Findings',
                    content:
                        'A Dominant species observed: Rhizophora muncronata, Avicennia Marina and Ceriops tagal.Moderate density with some areas showing signs of stress',
                  ),
                  const SizedBox(height: 24),
                  _buildSupervisorReviewCard(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Left column row builder
  Widget _buildInfoRow(String label, String value, {String? subValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: _C.textDark,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    subValue,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: _C.textDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Right column standard card
  Widget _buildRightCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.textBody,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Right column Supervisor Review Card (with green button)
  Widget _buildSupervisorReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supervisor Review',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Prof, Okeyo Benards\nWell documented activity, GPS accuracy acceptable, please include more photographs of sampling points',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.textBody,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(3); // Switch to Review Tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: const Text(
                'Add a Review',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DOTTED LINE PAINTER
// ==========================================
class _VerticalDottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.textMuted.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 5;
    const double dashSpace = 5;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
