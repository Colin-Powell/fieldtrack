// lib/features/supervisor/dashboard/supervisor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show pi;
import 'dart:async';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fieldtrack/shared/models/student_data.dart';
import 'dashboard_state.dart';
import '../widgets/supervisor_top_header.dart';
import 'package:fieldtrack/core/utils/time_utils.dart';

// ── Design tokens ────────────────────────────────────────────────────────
class _C {
  static const bg = Color(
    0xFFF3F4F6,
  ); // Adjusted to match light grey background
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFC5E8D2);
  static const greenDark = Color(0xFF115E2E);
  static const blueLight = Color(0xFF90C2F9);
  static const teal = Color(0xFF42B3B0);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFDD3BF);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const cardRadius = 40.0; // Updated for bubbly look
  static const controlHeight = 52.0;
}

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  static const double _stackBreakpoint = 1000;

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate initial network fetch loading delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide =
                constraints.maxWidth >=
                SupervisorDashboardScreen._stackBreakpoint;

            final mainColumnBody = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<DashboardState>(
                  builder: (context, state, _) {
                    final supName = state.supervisor?['name'] ?? 'Supervisor';
                    final title = '${getGreeting()} $supName';
                    return SupervisorTopHeader(
                      title: title,
                      subtitle: "Here's what's happening today",
                      onSearchChanged: state.setSearchQuery,
                      trailingWidget: sideBySide
                          ? IconButton(
                              icon: const Icon(
                                PhosphorIconsRegular.arrowsClockwise,
                              ),
                              onPressed: () => context
                                  .read<DashboardState>()
                                  .loadDashboard(isPolling: false),
                              tooltip: 'Refresh Dashboard',
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 32),
                _StatCardsRow(isLoading: _isLoading),
                const SizedBox(height: 28),
                _MiddleSection(isLoading: _isLoading),
              ],
            );

            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mainColumnBody,
                        const SizedBox(height: 28),
                        Expanded(child: _BottomSection(isLoading: _isLoading)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: _RightSidebar(
                      scrollableInternally: true,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DashboardState>().loadDashboard(
                isPolling: false,
              ),
              color: _C.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    mainColumnBody,
                    const SizedBox(height: 24),
                    _BottomSectionStacked(isLoading: _isLoading),
                    const SizedBox(height: 24),
                    _RightSidebar(
                      scrollableInternally: false,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Skeleton Loader ───────────────────────────────────────────────────────
class _Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const _Skeleton({this.width, this.height, this.borderRadius = 8});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ── Stat cards ────────────────────────────────────────────────────────────
class _StatCardsRow extends StatelessWidget {
  final bool isLoading;
  const _StatCardsRow({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final studentsCheckedInToday = context.select<DashboardState, int>(
      (s) => s.studentsCheckedInToday,
    );
    final trend = context.select<DashboardState, Map<String, dynamic>?>(
      (s) => s.trend,
    );
    final studentsInField = context.select<DashboardState, int>(
      (s) => s.studentsInField,
    );
    final activitiesSubmitted = context.select<DashboardState, int>(
      (s) => s.activitiesSubmitted,
    );
    final cards = [
      _StatCard(
        title: 'Students Checked\nIn Today',
        value: '$studentsCheckedInToday',
        subtitle: '${trend?['checkIns'] ?? ''} from yesterday',
        isPositive: true,
        bgColor: _C.greenLight,
        iconColor: _C.green,
        icon: PhosphorIconsRegular.graduationCap,
        isLoading: isLoading,
      ),
      _StatCard(
        title: 'Students in\nField',
        value: '$studentsInField',
        subtitle: 'Live Now',
        isPositive: true,
        showArrow: false,
        bgColor: _C.greenLight,
        iconColor: _C.green,
        icon: PhosphorIconsRegular.graduationCap,
        isLoading: isLoading,
      ),
      _StatCard(
        title: 'Activities\nSubmitted',
        value: '$activitiesSubmitted',
        subtitle: '${trend?['activities'] ?? ''} from yesterday',
        isPositive: true,
        bgColor: const Color(0xFFD1F0E0),
        iconColor: Colors.black,
        icon: PhosphorIconsFill.fileText,
        isLoading: isLoading,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= 700) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 24),
              Expanded(child: cards[1]),
              const SizedBox(width: 24),
              Expanded(child: cards[2]),
            ],
          );
        } else if (w >= 450) {
          final cardWidth = (w - 24) / 2;
          return Wrap(
            spacing: 24,
            runSpacing: 24,
            children: cards
                .map((c) => SizedBox(width: cardWidth, child: c))
                .toList(),
          );
        }
        return Column(
          children: [
            cards[0],
            const SizedBox(height: 20),
            cards[1],
            const SizedBox(height: 20),
            cards[2],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool isPositive;
  final bool showArrow;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final bool isLoading;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isPositive,
    this.showArrow = true,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_C.cardRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const _Skeleton(width: 64, height: 48, borderRadius: 8)
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 12),
                if (isLoading)
                  const _Skeleton(width: 120, height: 18, borderRadius: 4)
                else
                  Row(
                    children: [
                      if (showArrow) ...[
                        Icon(
                          isPositive
                              ? PhosphorIconsBold.arrowUp
                              : PhosphorIconsBold.arrowDown,
                          color: iconColor == Colors.black
                              ? _C.green
                              : iconColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: iconColor == Colors.black
                                ? _C.green
                                : iconColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Middle section (Quick Actions + Pending) ──────────────────────────────
class _MiddleSection extends StatelessWidget {
  final bool isLoading;
  const _MiddleSection({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 650;

        final quickActionsBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _C.textDark,
              ),
            ),
            const SizedBox(height: 20),
            _QuickActionsRow(scrollable: !sideBySide),
          ],
        );

        if (sideBySide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: Center(child: quickActionsBlock)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _PendingReviews(isLoading: isLoading)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            quickActionsBlock,
            const SizedBox(height: 24),
            _PendingReviews(isLoading: isLoading),
          ],
        );
      },
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final bool scrollable;
  const _QuickActionsRow({required this.scrollable});

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Launching: $action',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        width: 280, // Size constrained neatly to text instead of entire width
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        PhosphorIconsFill.fileText,
        'Review Activities',
        onTap: () => _showAction(context, 'Review Activities'),
      ),
      _QuickAction(
        PhosphorIconsFill.fileArrowDown,
        'Generate Report',
        onTap: () => _showAction(context, 'Generate Report'),
      ),
      _QuickAction(
        PhosphorIconsFill.graduationCap,
        'View Students',
        onTap: () => context.go('/supervisor/students'),
      ),
      _QuickAction(
        PhosphorIconsFill.export,
        'Export Logs',
        onTap: () => _showAction(context, 'Export Logs'),
      ),
    ];

    if (!scrollable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions,
      );
    }

    final spaced = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 28));
      spaced.add(actions[i]);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: spaced),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(this.icon, this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingReviews extends StatelessWidget {
  final bool isLoading;
  const _PendingReviews({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<DashboardState, int>(
      (s) => s.pendingReviews,
    );
    final isEmpty = pending == 0;

    // Dynamic styles based on empty states
    final bgColor = isEmpty
        ? _C.greenLight.withOpacity(0.4)
        : _C.orangeLight.withOpacity(0.74);
    final iconColor = isEmpty ? _C.green : _C.orange;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pending\nReviews',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.25,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const _Skeleton(width: 50, height: 38, borderRadius: 8)
                else
                  Text(
                    '$pending',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 12),
                if (isLoading)
                  const _Skeleton(width: 80, height: 16, borderRadius: 4)
                else
                  Text(
                    isEmpty ? 'All caught up!' : 'Needs your\nattention',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: iconColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(
              isEmpty
                  ? PhosphorIconsBold.check
                  : PhosphorIconsBold.arrowUpRight,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map + Overview ────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  final bool isLoading;
  const _MapCard({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final students = context.select<DashboardState, List<StudentData>>(
      (s) => s.students,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 420;
                final icon = Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: _C.greenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsFill.mapPin,
                    color: _C.green,
                    size: 24,
                  ),
                );
                const title = Text(
                  'Live Students in the Field',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _C.textDark,
                  ),
                );
                final button = SizedBox(
                  height: _C.controlHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        context.go('/supervisor/map');
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _C.controlHeight / 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'View Live Map',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: 16),
                          const Expanded(child: title),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: button),
                    ],
                  );
                }

                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 16),
                    const Expanded(child: title),
                    button,
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(_C.cardRadius),
                bottomRight: Radius.circular(_C.cardRadius),
              ),
              child: isLoading
                  ? const _Skeleton(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    )
                  : FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(-3.6305, 39.8499),
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: students
                              .where(
                                (s) =>
                                    s.currentSession != null &&
                                    s.checkInStatus == 'Checked In',
                              )
                              .map((student) {
                                return Marker(
                                  point: LatLng(
                                    student.currentSession!.latitude,
                                    student.currentSession!.longitude,
                                  ),
                                  width: 56,
                                  height: 56,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: _C.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(
                                        width: 46,
                                        height: 46,
                                        child: AppAvatar(
                                          imagePath:
                                              student.avatarUrl.isNotEmpty
                                              ? student.avatarUrl
                                              : null,
                                          size: 46,
                                          shape: AvatarShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatefulWidget {
  final bool isLoading;
  const _OverviewCard({required this.isLoading});

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final checkIns = context.select<DashboardState, int>((s) => s.checkedIn);
    final inField = context.select<DashboardState, int>((s) => s.inField);
    final checkedOut = context.select<DashboardState, int>((s) => s.checkedOut);
    // Make width larger as requested
    const double chartSize = 300.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Today's Overview",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: _C.textDark,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: widget.isLoading
                  ? const _Skeleton(
                      width: chartSize,
                      height: chartSize,
                      borderRadius: chartSize / 2,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: chartSize,
                          height: chartSize,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: chartSize / 2.8,
                              sections: [
                                _buildPieSection(
                                  value: checkedOut.toDouble(),
                                  color: _C.greenDark,
                                  title: 'Checked Out\n$checkedOut',
                                  isTouched: _touchedIndex == 0,
                                ),
                                _buildPieSection(
                                  value: checkIns.toDouble(),
                                  color: _C.blueLight,
                                  title: 'Checked In\n$checkIns',
                                  isTouched: _touchedIndex == 1,
                                ),
                                _buildPieSection(
                                  value: inField.toDouble(),
                                  color: _C.teal,
                                  title: 'In Field\n$inField',
                                  isTouched: _touchedIndex == 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Inner text only shows when nothing is hovered
                        if (_touchedIndex == -1)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _InlineLegendRow(
                                '$checkedOut',
                                'Checked out',
                                _C.greenDark,
                              ),
                              const SizedBox(height: 8),
                              _InlineLegendRow(
                                '$checkIns',
                                'Checked in',
                                _C.blueLight,
                              ),
                              const SizedBox(height: 8),
                              _InlineLegendRow('$inField', 'In field', _C.teal),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection({
    required double value,
    required Color color,
    required String title,
    required bool isTouched,
  }) {
    final double radius = isTouched ? 35.0 : 25.0;
    return PieChartSectionData(
      color: color,
      value: value,
      title: title,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: isTouched ? 14.0 : 0.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
        fontFamily: 'Poppins',
      ),
      badgeWidget: isTouched
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      badgePositionPercentageOffset: 1.4,
    );
  }
}

class _InlineLegendRow extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _InlineLegendRow(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _C.textDark,
          ),
        ),
      ],
    );
  }
}

class _BottomSection extends StatelessWidget {
  final bool isLoading;
  const _BottomSection({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 760;
        final map = _MapCard(isLoading: isLoading);
        final overview = _OverviewCard(isLoading: isLoading);

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: map),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: SingleChildScrollView(child: overview)),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: map),
            const SizedBox(height: 24),
            SingleChildScrollView(child: overview),
          ],
        );
      },
    );
  }
}

class _BottomSectionStacked extends StatelessWidget {
  final bool isLoading;
  const _BottomSectionStacked({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 760;
        final mapHeight = (MediaQuery.of(context).size.height * 0.45).clamp(
          280.0,
          460.0,
        );
        final map = SizedBox(
          height: mapHeight,
          child: _MapCard(isLoading: isLoading),
        );
        final overview = _OverviewCard(isLoading: isLoading);

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: map),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: overview),
            ],
          );
        }

        return Column(children: [map, const SizedBox(height: 24), overview]);
      },
    );
  }
}

// ── Right sidebar (Live Data + States) ────────────────────────────────────
class _LocalFeedItem {
  final String time;
  final String content;
  _LocalFeedItem(this.time, this.content);
}

class _RightSidebar extends StatefulWidget {
  final bool scrollableInternally;
  final bool isLoading;
  const _RightSidebar({
    required this.scrollableInternally,
    required this.isLoading,
  });

  @override
  State<_RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<_RightSidebar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    final filteredActivities = context
        .select<DashboardState, List<RecentActivity>>(
          (s) => s.filteredActivities,
        );
    final feedItems = context.select<DashboardState, List<FeedItem>>(
      (s) => s.feedItems,
    );

    // Setup Activities List (Empty State, Skeleton, or Live Data)
    Widget recentActivitiesList;
    if (widget.isLoading) {
      recentActivitiesList = ListView.builder(
        shrinkWrap: !widget.scrollableInternally,
        physics: widget.scrollableInternally
            ? null
            : const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: _Skeleton(
            width: double.infinity,
            height: 64,
            borderRadius: 32,
          ),
        ),
      );
    } else if (filteredActivities.isEmpty) {
      recentActivitiesList = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _C.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.clipboardText,
                  size: 32,
                  color: _C.greenDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No recent activities',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Students haven\'t submitted anything yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/supervisor/students'),
                icon: const Icon(
                  PhosphorIconsBold.plus,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Assign Activity',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      recentActivitiesList = ListView.builder(
        shrinkWrap: !widget.scrollableInternally,
        physics: widget.scrollableInternally
            ? null
            : const NeverScrollableScrollPhysics(),
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = filteredActivities[index];
          return _RecentActivityItem(
            title: activity.title,
            subtitle: activity.location,
            time: activity.time,
            imgUrl: activity.imageUrl,
            studentId: activity.studentId ?? '1',
            activityId: activity.activityId,
            studentName: activity.studentName ?? 'Student',
          );
        },
      );
    }

    // Setup Feed Items
    final combinedFeeds = feedItems
        .map((item) => _LocalFeedItem(item.time, item.content))
        .toList();

    Widget feedList;
    if (widget.isLoading) {
      feedList = ListView.builder(
        shrinkWrap: !widget.scrollableInternally,
        physics: widget.scrollableInternally
            ? null
            : const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 20.0),
          child: Row(
            children: [
              _Skeleton(width: 44, height: 16),
              SizedBox(width: 16),
              Expanded(child: _Skeleton(height: 16)),
            ],
          ),
        ),
      );
    } else if (combinedFeeds.isEmpty) {
      feedList = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No activity feed yet.',
            style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
          ),
        ),
      );
    } else {
      feedList = ListView.builder(
        shrinkWrap: !widget.scrollableInternally,
        physics: widget.scrollableInternally
            ? null
            : const NeverScrollableScrollPhysics(),
        itemCount: combinedFeeds.length,
        itemBuilder: (context, index) {
          final item = combinedFeeds[index];
          return _FeedItem(time: item.time, content: item.content);
        },
      );
    }

    final viewAllButton = SizedBox(
      width: double.infinity,
      height: _C.controlHeight,
      child: OutlinedButton(
        onPressed: () => context.go('/supervisor/students'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _C.green.withOpacity(0.74), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_C.controlHeight / 2),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          'View all Activities',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: _C.green,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );

    final innerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.scrollableInternally
          ? MainAxisSize.max
          : MainAxisSize.min,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 24),
        widget.scrollableInternally
            ? Expanded(flex: 4, child: recentActivitiesList)
            : recentActivitiesList,
        const SizedBox(height: 16),
        if (filteredActivities.isNotEmpty && !widget.isLoading) viewAllButton,
        const SizedBox(height: 40),
        const Text(
          "Today's Activity Feed",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 24),
        widget.scrollableInternally
            ? Expanded(flex: 3, child: feedList)
            : feedList,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: innerContent,
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String imgUrl;
  final String? studentId;
  final String? activityId;
  final String? studentName;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.imgUrl,
    this.studentId,
    this.activityId,
    this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          if (studentId != null && activityId != null) {
            context.go(
              '/supervisor/student/$studentId/activity/$activityId',
              extra: <String, String>{
                'studentName': studentName ?? 'Student',
                'activityTitle': title,
              },
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: AppAvatar(
                  imagePath: imgUrl.isNotEmpty ? imgUrl : null,
                  size: 36,
                  shape: AvatarShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$subtitle · $time',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: _C.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final String time;
  final String content;
  const _FeedItem({required this.time, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Removed CustomPainter Donut chart in favor of fl_chart ──
