import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/shared/widgets/skeleton_loader.dart';
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
  static const cardRadius = 32.0;
}

class SupervisorActivityDetailsScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String activityId;
  final String studentName;
  final String activityTitle;
  final bool embedded;
  const SupervisorActivityDetailsScreen({
    super.key,
    required this.studentId,
    required this.activityId,
    this.studentName = '',
    this.activityTitle = 'Activity Details',
    this.embedded = false,
  });

  @override
  ConsumerState<SupervisorActivityDetailsScreen> createState() =>
      _SupervisorActivityDetailsScreenState();
}

class _SupervisorActivityDetailsScreenState
    extends ConsumerState<SupervisorActivityDetailsScreen>
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
    return Container(
      color: _C.bg,
      child: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        return Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 32),
              _buildCustomTabs(),
              SizedBox(height: isMobile ? 16 : 32),

              // Tab Views (Expanded to take remaining fixed height)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // Keeps it fixed
                  children: [
                    _buildOverviewTab(isMobile: isMobile),
                    SupervisorEvidenceScreen(
                      studentId: widget.studentId,
                      activityId: widget.activityId,
                    ),
                    SupervisorLocationScreen(studentId: widget.studentId, activityId: widget.activityId),
                    SupervisorReviewScreen(
                      studentId: widget.studentId,
                      activityId: widget.activityId,
                      studentName: widget.studentName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 1. HEADER (Title, Breadcrumbs & Reviewed Badge) ───────────────────
  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
    final activityAsync = ref.watch(activityDetailsProvider(widget.activityId));
    final activityResult = activityAsync.asData?.value;
    final activity = activityResult is Success ? (activityResult as Success).data : null;
    final resolvedStudentName = widget.studentName.isNotEmpty
        ? widget.studentName
        : (activity?['user']?['name'] as String? ?? 'Student');
    final resolvedTitle = widget.activityTitle.isNotEmpty && widget.activityTitle != 'Activity Details'
        ? widget.activityTitle
        : (activity?['title'] as String? ?? 'Activity Details');

    final headerTextAndBreadcrumbs = Column(
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildBreadcrumb(
              'Students',
              onTap: () => context.go('/supervisor/students'),
            ),
            _buildBreadcrumbCaret(),
            _buildBreadcrumb(
              resolvedStudentName,
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
              resolvedTitle,
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
    );

    Widget buildBadge(BuildContext context) {
      return Builder(
        builder: (context) {
          final status = activity?['status'] as String? ?? 'DRAFT';
          final isReviewed = status == 'APPROVED' || status == 'REJECTED' || status == 'REVISION';
          final isPending = status == 'SUBMITTED' || status == 'UNDER_REVIEW';

          Color badgeColor;
          Color textColor;
          String badgeText;

          if (isReviewed) {
            badgeColor = _C.greenLight;
            textColor = _C.green;
            badgeText = 'Reviewed';
          } else if (isPending) {
            badgeColor = const Color(0xFFFFF7ED);
            textColor = const Color(0xFFC2410C);
            badgeText = 'Pending Review';
          } else {
            badgeColor = const Color(0xFFF3F4F6);
            textColor = const Color(0xFF4B5563);
            badgeText = 'Draft';
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          );
        },
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerTextAndBreadcrumbs,
          const SizedBox(height: 16),
          buildBadge(context),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerTextAndBreadcrumbs,
        buildBadge(context),
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
    final activityAsync = ref.watch(activityDetailsProvider(widget.activityId));
    
    return ApiResultBuilder<Map<String, dynamic>>(
      asyncValue: activityAsync,
      onRetry: () => ref.refresh(activityDetailsProvider(widget.activityId)),
      customLoading: const SkeletonLoader(width: double.infinity, height: 40),
      onData: (activity) {
        final review = activity['review'] as Map<String, dynamic>?;
        final hasReview = review != null;
        final status = activity['status'] ?? 'DRAFT';
        final isReviewed = status == 'APPROVED' || status == 'REJECTED' || status == 'REVISION' || hasReview;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildTabPill('Overview', 0, isCompleted: true),
              const SizedBox(width: 8),
              _buildTabPill('Evidence', 1, isCompleted: isReviewed),
              const SizedBox(width: 8),
              _buildTabPill('Location', 2, isCompleted: isReviewed),
              const SizedBox(width: 8),
              _buildTabPill('Review', 3, isCompleted: isReviewed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabPill(String title, int index, {required bool isCompleted}) {
    final bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            if (isCompleted) ...[
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsFill.checkCircle,
                size: 18,
                color: isActive ? Colors.white : _C.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. OVERVIEW TAB CONTENT ───────────────────────────────────────────
  Widget _buildOverviewTab({required bool isMobile}) {
    final activityAsync = ref.watch(activityDetailsProvider(widget.activityId));

    return ApiResultBuilder<Map<String, dynamic>>(
      asyncValue: activityAsync,
      onRetry: () => ref.refresh(activityDetailsProvider(widget.activityId)),
      customLoading: const ListSkeletonLoader(itemCount: 2),
      onData: (activity) {
        final title = activity['title'] ?? 'Untitled Activity';
        final description = activity['description'] ?? 'No description provided';
        final methodology = activity['methodology'] ?? 'No methodology provided';
        final status = activity['status'] ?? 'DRAFT';
        
        String timeStr = 'Not submitted';
        if (activity['timestamp'] != null) {
          final dt = DateTime.parse(activity['timestamp']).toLocal();
          timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }

        final locName = activity['locationName'] as String?;
        final fallbackLoc = "Lat: ${activity['latitude']?.toStringAsFixed(4) ?? '-'}, Lng: ${activity['longitude']?.toStringAsFixed(4) ?? '-'}";
        final locationStr = (locName != null && locName.isNotEmpty) 
            ? '$locName${activity['county'] != null ? ', ${activity['county']}' : ''}' 
            : fallbackLoc;
        final accuracyStr = "${activity['gpsAccuracy']?.toStringAsFixed(1) ?? '-'} m";

        final leftColumn = Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_C.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoRow('Activity Type', title),
              _buildInfoRow('Time', timeStr),
              _buildInfoRow('Location', 'Field Location', subValue: locationStr),
              _buildInfoRow('Accuracy', accuracyStr),
              _buildInfoRow('Methodology', methodology),
            ],
          ),
        );

        final rightColumn = Column(
          children: [
            _buildRightCard(
              title: 'Description',
              content: description,
            ),
            const SizedBox(height: 24),
            _buildSupervisorReviewCard(status),
          ],
        );

        if (isMobile) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftColumn,
                const SizedBox(height: 24),
                rightColumn,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Details
            Expanded(
              flex: 5,
              child: SingleChildScrollView(child: leftColumn),
            ),
            const SizedBox(width: 32),
            // Right Column: Descriptions, Findings & Review
            Expanded(
              flex: 9,
              child: SingleChildScrollView(child: rightColumn),
            ),
          ],
        );
      },
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
  Widget _buildSupervisorReviewCard(String status) {
    bool isReviewed = status == 'APPROVED' || status == 'REJECTED' || status == 'REVISION';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.greenLight, width: 2),
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
          Text(
            isReviewed ? 'This activity has been reviewed.' : 'This activity requires your review.',
            style: const TextStyle(
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
              child: Text(
                isReviewed ? 'View Review' : 'Add a Review',
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
