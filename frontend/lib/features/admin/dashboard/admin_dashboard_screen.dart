import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'providers/admin_dashboard_provider.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

// ==========================================
// LOCAL SCREEN MODELS (Flutter-specific types)
// ==========================================
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DashboardDepartmentStat {
  final String name;
  final int count;
  final double percentage; // 0.0 to 1.0
  final Color color;

  const DashboardDepartmentStat({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class DashboardSystemActivity {
  final String title;
  final String desc;
  final String time;
  final IconData icon;
  final Color color;

  const DashboardSystemActivity({
    required this.title,
    required this.desc,
    required this.time,
    required this.icon,
    required this.color,
  });
}

/// Wrapper widget that handles both mouse hover and touch events for charts
/// Provides consistent interaction on desktop, tablet, and mobile
class _TouchFriendlyHoverRegion extends StatefulWidget {
  final Widget child;
  final Function(Offset) onHover;
  final VoidCallback onExit;

  const _TouchFriendlyHoverRegion({
    required this.child,
    required this.onHover,
    required this.onExit,
  });

  @override
  State<_TouchFriendlyHoverRegion> createState() =>
      _TouchFriendlyHoverRegionState();
}

class _TouchFriendlyHoverRegionState extends State<_TouchFriendlyHoverRegion> {
  bool _isCurrentlyHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (!_isCurrentlyHovering) {
          _isCurrentlyHovering = true;
        }
        widget.onHover(event.localPosition);
      },
      onExit: (_) {
        _isCurrentlyHovering = false;
        widget.onExit();
      },
      child: Listener(
        onPointerMove: (event) {
          // Handle touch move events
          if (event.kind == PointerDeviceKind.touch) {
            widget.onHover(event.localPosition);
          }
        },
        onPointerUp: (_) {
          // Reset on touch end
          _isCurrentlyHovering = false;
          widget.onExit();
        },
        onPointerCancel: (_) {
          // Reset on touch cancel
          _isCurrentlyHovering = false;
          widget.onExit();
        },
        child: widget.child,
      ),
    );
  }
}

// Utility to parse hex color string to Color
Color _parseColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// Map icon string to Phosphor icon
IconData _mapIcon(String iconName) {
  switch (iconName) {
    case 'userPlus':
      return PhosphorIconsRegular.userPlus;
    case 'pencilCircle':
      return PhosphorIconsRegular.pencilCircle;
    case 'toggleLeft':
      return PhosphorIconsRegular.toggleLeft;
    case 'key':
      return PhosphorIconsRegular.key;
    case 'trash':
      return PhosphorIconsRegular.trash;
    case 'arrowsClockwise':
      return PhosphorIconsRegular.arrowsClockwise;
    case 'info':
    default:
      return PhosphorIconsRegular.info;
  }
}

// ==========================================
// MAIN SCREEN
// ==========================================
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _timeFilter = 'This Week';
  final List<String> _timeFilterOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  int? _hoveredBarIndex;
  int? _hoveredLineIndex;
  int? _hoveredDonutIndex;
  Offset? _donutHoverPos;

  void _updateBarHover(
    Offset pos,
    double containerWidth,
    List<TrendDataPoint> data,
  ) {
    if (data.isEmpty) return;
    const leftPadding = 36.0;
    final chartWidth = containerWidth - leftPadding;
    if (chartWidth <= 0) return;

    final barWidth = min(48.0, (chartWidth / data.length) * 0.6);
    final spacing =
        (chartWidth - (barWidth * data.length)) / max(1, data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final xStart = leftPadding + i * (barWidth + spacing);
      final xEnd = xStart + barWidth;

      if (pos.dx >= xStart - (spacing / 2) && pos.dx <= xEnd + (spacing / 2)) {
        if (_hoveredBarIndex != i) setState(() => _hoveredBarIndex = i);
        return;
      }
    }
  }

  void _updateLineHover(
    Offset pos,
    double containerWidth,
    List<TrendDataPoint> data,
  ) {
    if (data.isEmpty) return;
    const leftPadding = 36.0;
    final chartWidth = containerWidth - leftPadding;
    if (chartWidth <= 0) return;

    final stepX = chartWidth / max(1, data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final xPos = leftPadding + (i * stepX);
      if ((pos.dx - xPos).abs() < (stepX / 2)) {
        if (_hoveredLineIndex != i) setState(() => _hoveredLineIndex = i);
        return;
      }
    }
  }

  void _updateDonutHover(Offset pos, Size size, List<DonutSegment> data) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final radius = min(size.width / 2, size.height / 2) - 20;
    final innerRadius = radius - 24;
    final outerRadius = radius + 24;

    if (distance < innerRadius || distance > outerRadius) {
      if (_hoveredDonutIndex != null) {
        setState(() {
          _hoveredDonutIndex = null;
          _donutHoverPos = null;
        });
      }
      return;
    }

    double angle = atan2(dy, dx);
    angle += pi / 2;
    if (angle < 0) angle += 2 * pi;

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    double currentAngle = 0;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * pi;
      if (angle >= currentAngle && angle <= currentAngle + sweepAngle) {
        if (_hoveredDonutIndex != i) {
          setState(() {
            _hoveredDonutIndex = i;
            _donutHoverPos = pos;
          });
        }
        return;
      }
      currentAngle += sweepAngle;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.chartBar,
            size: 48,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final padding = isCompact ? 16.0 : 32.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'System Overview',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
                    ),
                  ),
                  _buildDropdownActionPill(
                    label: _timeFilter,
                    options: _timeFilterOptions,
                    onSelected: (v) => setState(() {
                      _timeFilter = v;
                      _hoveredBarIndex = null;
                      _hoveredLineIndex = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ref
                  .watch(adminDashboardProvider(_timeFilter))
                  .when(
                    data: (stats) {
                      final trendUp = '↑';
                      final trendDown = '↓';
                      final studentTrend = stats.totalStudents > 0
                          ? '$trendUp ${(stats.totalStudents * 0.12).round()}'
                          : '0';
                      final supervisorTrend = stats.activeSupervisors > 0
                          ? '$trendUp ${(stats.activeSupervisors * 0.05).round()}'
                          : '0';

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isOneColumn = width < 560;
                          final isTwoColumns = width >= 560 && width < 1100;

                          final cardWidth = isOneColumn
                              ? width
                              : isTwoColumns
                              ? (width - 24) / 2
                              : (width - 48) / 3;

                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Total Students',
                                  value: formatNumber(stats.totalStudents),
                                  trend: studentTrend,
                                  icon: PhosphorIconsRegular.student,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Active Supervisors',
                                  value: stats.activeSupervisors.toString(),
                                  trend: supervisorTrend,
                                  icon: PhosphorIconsRegular.chalkboardTeacher,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Students in Field',
                                  value: stats.studentsInField.toString(),
                                  trend: stats.studentsInField > 0
                                      ? 'Live'
                                      : 'None',
                                  icon: PhosphorIconsRegular.mapPin,
                                  isAccent: true,
                                  accentColor: const Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Submitted Today',
                                  value: stats.submittedToday.toString(),
                                  trend: stats.submittedToday > 0
                                      ? '$trendUp ${stats.submittedToday}'
                                      : '0',
                                  icon: PhosphorIconsRegular.fileArrowUp,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Pending Reviews',
                                  value: stats.pendingReviews.toString(),
                                  trend: stats.pendingReviews > 0
                                      ? '$trendDown ${stats.pendingReviews}'
                                      : '0',
                                  icon: PhosphorIconsRegular.clockCountdown,
                                  isAccent: true,
                                  accentColor: const Color(0xFFFF7A00),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildStatCard(
                                  title: 'Research Projects',
                                  value: stats.activeProjects.toString(),
                                  trend: stats.activeProjects > 0
                                      ? '+$trendUp'
                                      : '0',
                                  icon: PhosphorIconsRegular.folders,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          ErrorHandler.getFriendlyErrorMessage(err),
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 32),
              ref
                  .watch(adminDashboardProvider(_timeFilter))
                  .when(
                    data: (stats) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 900;

                          final List<DonutSegment> donutSegments = stats
                              .submissionStatus
                              .map(
                                (s) => DonutSegment(
                                  label: s.label,
                                  value: s.value,
                                  color: _parseColor(s.color),
                                ),
                              )
                              .toList();

                          final List<DashboardDepartmentStat> deptStats = stats
                              .departmentStats
                              .map(
                                (d) => DashboardDepartmentStat(
                                  name: d.name,
                                  count: d.count,
                                  percentage: d.percentage,
                                  color: _parseColor(d.color),
                                ),
                              )
                              .toList();

                          final List<DashboardSystemActivity> sysActivities =
                              stats.systemActivities
                                  .map(
                                    (a) => DashboardSystemActivity(
                                      title: a.title,
                                      desc: a.desc,
                                      time: a.time,
                                      icon: _mapIcon(a.icon),
                                      color: _parseColor(a.color),
                                    ),
                                  )
                                  .toList();

                          final chartsContent = Column(
                            children: [
                              _buildChartCard(
                                title: 'Student Activity Trend',
                                height: 380,
                                child: stats.activityTrend.isEmpty
                                    ? _buildEmptyState(
                                        'No activity data available yet',
                                      )
                                    : _TouchFriendlyHoverRegion(
                                        onHover: (pos) => _updateBarHover(
                                          pos,
                                          isNarrow
                                              ? constraints.maxWidth
                                              : (constraints.maxWidth - 32) *
                                                        0.7 -
                                                    64,
                                          stats.activityTrend,
                                        ),
                                        onExit: () => setState(
                                          () => _hoveredBarIndex = null,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: CustomPaint(
                                            painter: _BarChartPainter(
                                              dataPoints: stats.activityTrend,
                                              activeIndex: _hoveredBarIndex,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildChartCard(
                                      title: 'Field Attendance Trend (%)',
                                      height: 320,
                                      child: stats.attendanceTrend.isEmpty
                                          ? _buildEmptyState(
                                              'No attendance data available yet',
                                            )
                                          : _TouchFriendlyHoverRegion(
                                              onHover: (pos) => _updateLineHover(
                                                pos,
                                                isNarrow
                                                    ? (constraints.maxWidth -
                                                              24) /
                                                          2
                                                    : ((constraints.maxWidth -
                                                                          32) *
                                                                      0.7 -
                                                                  24) *
                                                              0.6 -
                                                          64,
                                                stats.attendanceTrend,
                                              ),
                                              onExit: () => setState(
                                                () => _hoveredLineIndex = null,
                                              ),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: CustomPaint(
                                                  painter:
                                                      _SmoothLineChartPainter(
                                                        dataPoints: stats
                                                            .attendanceTrend,
                                                        activeIndex:
                                                            _hoveredLineIndex,
                                                      ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 4,
                                    child: _buildChartCard(
                                      title: 'Submission Status',
                                      height: 320,
                                      child:
                                          stats.submissionStatus.isEmpty ||
                                              stats.submissionStatus.every(
                                                (s) => s.value == 0,
                                              )
                                          ? _buildEmptyState(
                                              'No submissions yet',
                                            )
                                          : _TouchFriendlyHoverRegion(
                                              onHover: (pos) => _updateDonutHover(
                                                pos,
                                                Size(
                                                  (isNarrow
                                                              ? constraints
                                                                    .maxWidth
                                                              : (constraints.maxWidth -
                                                                            32) *
                                                                        0.7 -
                                                                    24) *
                                                          0.4 -
                                                      48,
                                                  320 - 96,
                                                ),
                                                donutSegments,
                                              ),
                                              onExit: () => setState(() {
                                                _hoveredDonutIndex = null;
                                                _donutHoverPos = null;
                                              }),
                                              child: LayoutBuilder(
                                                builder:
                                                    (
                                                      context,
                                                      donutConstraints,
                                                    ) => SizedBox(
                                                      width: double.infinity,
                                                      child: CustomPaint(
                                                        painter: _DonutChartPainter(
                                                          segments:
                                                              donutSegments,
                                                          activeIndex:
                                                              _hoveredDonutIndex,
                                                          hoverPos:
                                                              _donutHoverPos,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildChartCard(
                                title: 'Students per Department',
                                height: deptStats.isEmpty ? 160 : 320,
                                child: deptStats.isEmpty
                                    ? _buildEmptyState(
                                        'No department data available',
                                      )
                                    : _buildDepartmentList(deptStats),
                              ),
                            ],
                          );

                          final sidePanel = Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Registrations',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (stats.recentUsers.isEmpty)
                                  _buildEmptyState('No recent registrations')
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: stats.recentUsers.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                          height: 32,
                                          color: Color(0xFFF3F4F6),
                                        ),
                                    itemBuilder: (context, i) {
                                      final u = stats.recentUsers[i];
                                      return Row(
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: AppAvatar(
                                              imagePath: u.avatarUrl,
                                              size: 44,
                                              shape: AvatarShape.circle,
                                              initials: u.name.isNotEmpty
                                                  ? u.name
                                                        .split(' ')
                                                        .map(
                                                          (s) => s.isNotEmpty
                                                              ? s[0]
                                                              : '',
                                                        )
                                                        .take(2)
                                                        .join()
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  u.name,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Color(0xFF171717),
                                                  ),
                                                ),
                                                Text(
                                                  u.role,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            u.time,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                const SizedBox(height: 48),
                                const Text(
                                  'System Activity',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (sysActivities.isEmpty)
                                  _buildEmptyState(
                                    'No system activities recorded',
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: sysActivities.length,
                                    itemBuilder: (context, i) {
                                      final a = sysActivities[i];
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: a.color.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  a.icon,
                                                  color: a.color,
                                                  size: 18,
                                                ),
                                              ),
                                              if (i != sysActivities.length - 1)
                                                Container(
                                                  width: 2,
                                                  height: 40,
                                                  color: const Color(
                                                    0xFFF3F4F6,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 24,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.title,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: Color(0xFF171717),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    a.desc,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    a.time,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                chartsContent,
                                const SizedBox(height: 32),
                                sidePanel,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: chartsContent),
                              const SizedBox(width: 32),
                              Expanded(flex: 3, child: sidePanel),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          ErrorHandler.getFriendlyErrorMessage(err),
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  String formatNumber(int num) {
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    }
    return num.toString();
  }

  Widget _buildDropdownActionPill({
    required String label,
    required List<String> options,
    required void Function(String) onSelected,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: '',
        onSelected: onSelected,
        itemBuilder: (ctx) => options
            .map(
              (o) => PopupMenuItem(
                value: o,
                child: Text(
                  o,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF5E7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF169B45),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsBold.caretDown,
                  color: Color(0xFF169B45),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    bool isAccent = false,
    Color? accentColor,
  }) {
    final bgColor = isAccent
        ? accentColor!.withValues(alpha: 0.1)
        : Colors.white;
    final iconBgColor = isAccent ? accentColor! : const Color(0xFF169B45);
    final iconColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isAccent
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAccent
                        ? iconBgColor.withValues(alpha: 0.8)
                        : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isAccent ? iconBgColor : const Color(0xFF171717),
                  height: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trend.startsWith('-') || trend == 'None'
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : const Color(0xFF169B45).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: trend.startsWith('-') || trend == 'None'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF169B45),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required double height,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDepartmentList(List<DashboardDepartmentStat> deptStats) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deptStats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final d = deptStats[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                Text(
                  d.count.toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: d.percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: d.color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// CUSTOM PAINTERS
// ==========================================

// 1. Bar Chart Painter
class _BarChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;
  final int? activeIndex;

  _BarChartPainter({required this.dataPoints, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final rawMax = dataPoints.map((d) => d.value).reduce(max);
    int stepSize = (rawMax / 4).ceil();
    if (stepSize > 5) stepSize = ((stepSize / 5).ceil()) * 5;
    if (stepSize == 0) stepSize = 1;
    final maxY = (stepSize * 4).toDouble();

    final gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const leftPadding = 36.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    for (int i = 0; i <= 4; i++) {
      final yValue = stepSize * i;
      final yPos = chartHeight - (yValue / maxY) * chartHeight;
      textPainter.text = TextSpan(
        text: yValue.toString(),
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 8));
      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    final barWidth = min(48.0, (chartWidth / dataPoints.length) * 0.6);
    final spacing =
        (chartWidth - (barWidth * dataPoints.length)) /
        max(1, dataPoints.length - 1);
    final bgPaint = Paint()..color = const Color(0xFFF9FAFB);

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final xPos = leftPadding + i * (barWidth + spacing);
      final barHeight = (point.value / maxY) * chartHeight;
      final yPos = chartHeight - barHeight;
      final isActive = activeIndex == i;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xPos, 0, barWidth, chartHeight),
          const Radius.circular(12),
        ),
        bgPaint,
      );

      final barPaint = Paint()
        ..shader = isActive
            ? ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFF4ADE80), const Color(0xFF169B45)],
              )
            : ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFFDFF5E7), const Color(0xFFDFF5E7)],
              );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xPos, yPos, barWidth, barHeight),
          const Radius.circular(12),
        ),
        barPaint,
      );

      textPainter.text = TextSpan(
        text: point.label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos + (barWidth - textPainter.width) / 2, chartHeight + 12),
      );

      if (isActive) {
        // Tooltip
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(xPos - 30, yPos - 54, 110, 44),
          const Radius.circular(12),
        );
        canvas.drawRRect(
          tooltipRect.shift(const Offset(0, 4)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.05)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);

        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: '${point.dateLabel}\n',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontFamily: 'Inter',
              ),
            ),
            const TextSpan(
              text: '● ',
              style: TextStyle(color: Color(0xFF169B45), fontSize: 12),
            ),
            TextSpan(
              text: point.value.toInt().toString(),
              style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xPos - 16, yPos - 48));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.dataPoints != dataPoints;
}

// 2. Smooth Line Area Chart Painter
class _SmoothLineChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;
  final int? activeIndex;

  _SmoothLineChartPainter({
    required this.dataPoints,
    required this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final maxY = 100.0; // Hardcoded for percentage
    const leftPadding = 36.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i <= 4; i++) {
      final yValue = 25 * i;
      final yPos = chartHeight - (yValue / maxY) * chartHeight;
      textPainter.text = TextSpan(
        text: yValue.toString(),
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 8));
      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    final stepX = chartWidth / max(1, dataPoints.length - 1);
    List<Offset> points = [];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = leftPadding + (i * stepX);
      final y = chartHeight - (dataPoints[i].value / maxY) * chartHeight;
      points.add(Offset(x, y));

      // X Labels
      textPainter.text = TextSpan(
        text: dataPoints[i].label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 12),
      );
    }

    // Smooth Curve Path
    Path linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      double cpX = (points[i].dx + points[i + 1].dx) / 2;
      linePath.cubicTo(
        cpX,
        points[i].dy,
        cpX,
        points[i + 1].dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    // Area Fill
    Path fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, chartHeight), [
        const Color(0xFF10B981).withValues(alpha: 0.3),
        const Color(0xFF10B981).withValues(alpha: 0.0),
      ]);
    canvas.drawPath(fillPath, fillPaint);

    // Line Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, strokePaint);

    // Hover State
    if (activeIndex != null && activeIndex! < points.length) {
      final pt = points[activeIndex!];
      final dp = dataPoints[activeIndex!];

      // Vertical line indicator
      canvas.drawLine(
        Offset(pt.dx, pt.dy),
        Offset(pt.dx, chartHeight),
        Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // Dot
      canvas.drawCircle(pt, 6, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 4, Paint()..color = const Color(0xFF10B981));

      // Tooltip
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pt.dx - 30, pt.dy - 54, 80, 40),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        tooltipRect.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);

      textPainter.text = TextSpan(
        children: [
          TextSpan(
            text: '${dp.dateLabel}\n',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
          TextSpan(
            text: '${dp.value.toInt()}%',
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - 18, pt.dy - 46));
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLineChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.dataPoints != dataPoints;
}

// 3. Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final int? activeIndex;
  final Offset? hoverPos;

  _DonutChartPainter({required this.segments, this.activeIndex, this.hoverPos});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = segments.fold(0.0, (sum, item) => sum + item.value);
    double currentAngle = -pi / 2; // Start top

    // Total count text in center
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: total.toInt().toString(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: Color(0xFF171717),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 8,
      ),
    );

    textPainter.text = const TextSpan(
      text: 'Total Submissions',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: Color(0xFF6B7280),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 8),
    );

    // Draw Arcs
    for (int i = 0; i < segments.length; i++) {
      var s = segments[i];
      final sweepAngle = (s.value / total) * 2 * pi;

      final isHovered = activeIndex == i;
      final strokeWidth = isHovered ? 28.0 : 24.0;

      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Add a tiny gap (subtract slightly from sweep)
      canvas.drawArc(rect, currentAngle, sweepAngle - 0.08, false, paint);
      currentAngle += sweepAngle;
    }

    // Hover Tooltip
    if (activeIndex != null &&
        hoverPos != null &&
        activeIndex! < segments.length) {
      final s = segments[activeIndex!];

      // Tooltip background
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(hoverPos!.dx - 40, hoverPos!.dy - 54, 80, 40),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        tooltipRect.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);

      // Tooltip text
      textPainter.text = TextSpan(
        children: [
          TextSpan(
            text: '${s.label}\n',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
          TextSpan(
            text: s.value.toInt().toString(),
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(hoverPos!.dx - textPainter.width / 2, hoverPos!.dy - 46),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.hoverPos != hoverPos;
}
