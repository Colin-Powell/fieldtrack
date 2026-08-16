// lib/features/supervisor/dashboard/supervisor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:intl/intl.dart';

import 'package:fieldtrack/shared/models/student_data.dart';
import 'dashboard_state.dart';
import 'package:fieldtrack/core/utils/time_utils.dart';
import 'package:fieldtrack/features/supervisor/widgets/supervisor_top_header.dart';

// ── Design tokens ────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F6F8);
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDDF5E6);
  static const greenDark = Color(0xFF115E2E);
  static const teal = Color(0xFF42B3B0);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFDE2D2);
  static const peach = Color(0xFFFBE4D7);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const cardRadius = 40.0; // Updated to 40px per request
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
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<DashboardState>();
      state.loadDashboard().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          context.read<DashboardState>().loadDashboard(isPolling: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 24.0;

          return Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: LayoutBuilder(
              builder: (context, inner) {
                final sideBySide =
                    inner.maxWidth >=
                    SupervisorDashboardScreen._stackBreakpoint;

                final headerSection = Consumer<DashboardState>(
                  builder: (context, state, _) {
                    final supName = state.supervisor?['name'] ?? 'Supervisor';
                    final title = '${getGreeting()}, $supName';
                    return SupervisorTopHeader(
                      title: title,
                      subtitle: "Here's what's happening today",
                      onSearchChanged: state.setSearchQuery,
                      trailingWidget: sideBySide
                          ? Container(
                              width: _C.controlHeight,
                              height: _C.controlHeight,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  PhosphorIconsRegular.arrowsClockwise,
                                  color: _C.textDark,
                                  size: 24,
                                ),
                                onPressed: () => context
                                    .read<DashboardState>()
                                    .loadDashboard(isPolling: false),
                                tooltip: 'Refresh Dashboard',
                              ),
                            )
                          : null,
                    );
                  },
                );

                final contentSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatCardsRow(isLoading: _isLoading),
                    const SizedBox(height: 32),
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
                            headerSection,
                            const SizedBox(height: 32),
                            contentSection,
                            const SizedBox(height: 24),
                            Expanded(
                              child: _BottomSection(isLoading: _isLoading),
                            ),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerSection,
                    const SizedBox(height: 32),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context
                            .read<DashboardState>()
                            .loadDashboard(isPolling: false),
                        color: _C.green,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              contentSection,
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
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
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
        subtitleHighlight: trend?['checkIns'] ?? '+12%',
        subtitleSuffix: ' from yesterday',
        isPositive: true,
        bgColor: const Color(0xFFDAF0E1),
        iconGradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF86EBA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        iconColor: Colors.white,
        icon: PhosphorIconsFill.graduationCap, // Filled Icon
        isLoading: isLoading,
      ),
      _StatCard(
        title: 'Students in\nField',
        value: '$studentsInField',
        subtitleHighlight: 'Live Now',
        subtitleSuffix: null,
        isPositive: true,
        showArrow: false,
        bgColor: const Color(0xFFE2F4E8),
        iconGradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF86EBA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        iconColor: Colors.white,
        icon: PhosphorIconsFill.graduationCap, // Filled Icon
        isLoading: isLoading,
      ),
      _StatCard(
        title: 'Activities\nSubmitted',
        value: '$activitiesSubmitted',
        subtitleHighlight: trend?['activities'] ?? '+18%',
        subtitleSuffix: ' from yesterday',
        isPositive: true,
        bgColor: const Color(0xFFE8ECE9),
        iconBgColor: Colors.black,
        iconColor: Colors.white,
        icon: PhosphorIconsFill.fileText, // Filled Icon
        isLoading: isLoading,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        if (w >= 900) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 20),
              Expanded(child: cards[1]),
              const SizedBox(width: 20),
              Expanded(child: cards[2]),
            ],
          );
        }

        if (w >= 560) {
          final cardWidth = (w - 20) / 2;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
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
  final String? subtitleHighlight;
  final String? subtitleSuffix;
  final bool isPositive;
  final bool showArrow;
  final Color bgColor;
  final Color? iconBgColor;
  final Gradient? iconGradient;
  final Color iconColor;
  final IconData icon;
  final bool isLoading;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitleHighlight,
    this.subtitleSuffix,
    required this.isPositive,
    this.showArrow = true,
    required this.bgColor,
    this.iconBgColor,
    this.iconGradient,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(_C.cardRadius)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    gradient: iconGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _C.textDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const _Skeleton(width: 64, height: 48, borderRadius: 8)
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: _C.textDark,
                      height: 1.0,
                    ),
                  ),
                const SizedBox(height: 16),
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
                          color: isPositive ? _C.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (subtitleHighlight != null)
                        Text(
                          subtitleHighlight!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: isPositive ? _C.green : Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      if (subtitleSuffix != null)
                        Expanded(
                          child: Text(
                            subtitleSuffix!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: _C.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        final sideBySide = constraints.maxWidth >= 760;

        final quickActionsBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 6, child: quickActionsBlock),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _PendingReviews(isLoading: isLoading)),
            ],
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
        width: 280,
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
        onTap: () => context.go('/supervisor/students'),
      ),
      _QuickAction(
        PhosphorIconsFill.fileArrowDown,
        'Generate Report',
        onTap: () => context.go('/supervisor/reports'),
      ),
      _QuickAction(
        PhosphorIconsFill.graduationCap,
        'View Students',
        onTap: () => context.go('/supervisor/students'),
      ),
      _QuickAction(
        PhosphorIconsFill.export,
        'Export Logs',
        onTap: () => context.go('/supervisor/reports'),
      ),
    ];

    if (!scrollable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: spaced,
      ),
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
            child: Icon(icon, color: _C.textDark, size: 28),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
                height: 1.2,
              ),
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

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: pending == 0 ? _C.greenLight : _C.peach,
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
                    fontSize: 18,
                    height: 1.25,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const _Skeleton(width: 50, height: 38, borderRadius: 8)
                else
                  Text(
                    '$pending',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 56,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: _C.textDark,
                    ),
                  ),
                const SizedBox(height: 16),
                if (isLoading)
                  const _Skeleton(width: 80, height: 16, borderRadius: 4)
                else
                  Text(
                    pending == 0 ? 'All caught up!' : 'Needs your\nattention',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: pending == 0 ? _C.green : _C.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: pending == 0 ? _C.green : _C.orange,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              alignment: Alignment.center,
              child: Icon(
                pending == 0
                    ? PhosphorIconsBold.check
                    : PhosphorIconsBold.arrowUpRight,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map + Overview ────────────────────────────────────────────────────────
class _MapCard extends StatefulWidget {
  final bool isLoading;
  const _MapCard({required this.isLoading});

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  final MapController _mapController = MapController();
  String? _lastPannedStudentId;
  bool _isMapReady = false;

  List<StudentData> _getAllStudents(List<StudentData> students) {
    return students
        .where(
          (s) => s.currentSession != null && s.checkInStatus == 'Checked In',
        )
        .toList();
  }

  void _panToLatestStudent(List<StudentData> students) {
    if (students.isEmpty) return;

    final latest = students.reduce((current, next) {
      final currentTime = current.currentSession!.checkInTime;
      final nextTime = next.currentSession!.checkInTime;
      return nextTime.isAfter(currentTime) ? next : current;
    });

    if (_lastPannedStudentId == latest.id) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_isMapReady) return; // Wait until map is ready
      try {
        _mapController.move(
          LatLng(
            latest.currentSession!.latitude,
            latest.currentSession!.longitude,
          ),
          13.5,
        );
        _lastPannedStudentId = latest.id; // Only mark as panned if successful
      } catch (_) {
        // Ignored if map still not attached somehow
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final students = context.select<DashboardState, List<StudentData>>(
      (s) => s.students,
    );
    final allStudents = _getAllStudents(students);

    if (!widget.isLoading && allStudents.isNotEmpty) {
      _panToLatestStudent(allStudents);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 420;
                final icon = Container(
                  width: 48,
                  height: 48,
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
                    fontSize: 16,
                    color: _C.textDark,
                  ),
                );
                final button = SizedBox(
                  height: 48,
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
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'View Live Map',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14,
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
              child: widget.isLoading
                  ? const _Skeleton(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(-3.6305, 39.8499),
                        initialZoom: 13.0,
                        onMapReady: () {
                          if (mounted) {
                            setState(() {
                              _isMapReady = true;
                            });
                          }
                        },
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
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: _C.greenLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: _C.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: AppAvatar(
                                        imagePath: student.avatarUrl.isNotEmpty
                                            ? student.avatarUrl
                                            : null,
                                        size: 40,
                                        shape: AvatarShape.circle,
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

class _DonutMetric {
  final String title;
  final int value;
  final Color color;
  final Color? textColor;

  const _DonutMetric({
    required this.title,
    required this.value,
    required this.color,
    this.textColor,
  });
}

class _SegmentedDonutPainter extends CustomPainter {
  final List<_DonutMetric> metrics;
  final double total;

  _SegmentedDonutPainter(this.metrics, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 36.0;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    if (total == 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _C.greenLight.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    final capAngle = (strokeWidth / 2) / radius;
    const visualGap = 0.08;
    final activeSegments = metrics.where((m) => m.value > 0).length;

    double totalReserved = activeSegments * (visualGap + 2 * capAngle);
    if (totalReserved > 2 * math.pi) {
      totalReserved = activeSegments * (0.02 + 2 * capAngle);
    }

    final availableSweep = math.max(0.0, 2 * math.pi - totalReserved);
    double startAngle = -math.pi / 2;

    for (var metric in metrics) {
      if (metric.value == 0) continue;

      final proportion = metric.value / total;
      final sweep = proportion * availableSweep;
      final drawStart = startAngle + capAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        drawStart,
        sweep,
        false,
        Paint()
          ..color = metric.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth,
      );

      startAngle += sweep + 2 * capAngle + visualGap;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedDonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.metrics != metrics;
  }
}

class _OverviewCard extends StatelessWidget {
  final bool isLoading;
  const _OverviewCard({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final int approved = context.select<DashboardState, int>(
      (s) => s.approvedReviews,
    );
    final int pending = context.select<DashboardState, int>(
      (s) => s.pendingReviews,
    );
    final int revision = context.select<DashboardState, int>(
      (s) => s.needsRevision,
    );
    final int total = approved + pending + revision;

    final int reviewedPercent = total > 0
        ? ((approved + revision) / total * 100).round()
        : 0;

    final metrics = [
      _DonutMetric(title: 'Approved', value: approved, color: _C.greenDark),
      _DonutMetric(
        title: 'Pending',
        value: pending,
        color: const Color(0xFFF59E0B), // Orange-ish for pending
        textColor: const Color(0xFFD97706),
      ),
      _DonutMetric(
        title: 'Needs revision',
        value: revision,
        color: const Color(0xFFEF4444), // Red-ish for revision
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Review & Activity Health",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 28),
          if (isLoading)
            const SizedBox(
              height: 240,
              child: Center(
                child: _Skeleton(width: 200, height: 200, borderRadius: 100),
              ),
            )
          else
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SegmentedDonutPainter(
                        metrics,
                        total.toDouble(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$reviewedPercent%',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark,
                        ),
                      ),
                      const Text(
                        'Reviewed',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(height: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: metrics.map((m) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _C.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${m.value}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: m.textColor ?? _C.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                // Navigate to review queue
              },
              child: const Row(
                children: [
                  Text(
                    'View review queue',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.textDark,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    PhosphorIconsRegular.arrowRight,
                    size: 16,
                    color: _C.textDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
              Expanded(flex: 4, child: overview),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: map),
            const SizedBox(height: 24),
            SizedBox(height: 380, child: overview),
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
        final overview = SizedBox(
          height: 380,
          child: _OverviewCard(isLoading: isLoading),
        );

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
    final paginatedActivities = context
        .select<DashboardState, List<RecentActivity>>(
          (s) => s.paginatedActivities,
        );
    final allActivitiesForEmpty = context
        .select<DashboardState, List<RecentActivity>>(
          (s) => s.filteredActivities,
        );
    final feedItems = context.select<DashboardState, List<FeedItem>>(
      (s) => s.feedItems,
    );
    final dashState = context.watch<DashboardState>();

    // Setup Activities List
    Widget recentActivitiesList;
    if (widget.isLoading) {
      recentActivitiesList = ListView.builder(
        shrinkWrap: !widget.scrollableInternally,
        physics: widget.scrollableInternally
            ? null
            : const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: _Skeleton(
            width: double.infinity,
            height: 64,
            borderRadius: 32,
          ),
        ),
      );
    } else if (allActivitiesForEmpty.isEmpty) {
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
                  color: _C.green,
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
        itemCount: paginatedActivities.length,
        itemBuilder: (context, index) {
          final activity = paginatedActivities[index];
          return _RecentActivityItem(
            title: activity.title,
            subtitle: activity.location,
            time: activity.time,
            imgUrl: activity.imageUrl,
            activityImageUrl: activity.activityImageUrl,
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
          padding: EdgeInsets.only(bottom: 24.0),
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

    // Pagination controls
    final totalPages = dashState.totalActivityPages;
    final currentPage = dashState.activityPage;
    final startIndex = currentPage * dashState.activitiesPerPage + 1;
    final endIndex = (currentPage + 1) * dashState.activitiesPerPage;
    final actualEndIndex = endIndex.clamp(0, allActivitiesForEmpty.length);
    final totalActivities = allActivitiesForEmpty.length;

    final paginationControls =
        allActivitiesForEmpty.isNotEmpty && totalPages > 1
        ? Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing $startIndex-$actualEndIndex of $totalActivities',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: _C.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    'Page ${currentPage + 1}/$totalPages',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentPage > 0
                          ? () => dashState.previousActivityPage()
                          : null,
                      icon: const Icon(
                        PhosphorIconsRegular.caretLeft,
                        size: 18,
                      ),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: currentPage > 0 ? _C.green : _C.textFaint,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: dashState.hasMoreActivities
                          ? () => dashState.nextActivityPage()
                          : null,
                      icon: const Icon(
                        PhosphorIconsRegular.caretRight,
                        size: 18,
                      ),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dashState.hasMoreActivities
                            ? _C.green
                            : _C.textFaint,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : const SizedBox.shrink();

    final viewAllButton = SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => context.go('/supervisor/students'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _C.green, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
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
        const SizedBox(height: 20),
        widget.scrollableInternally
            ? Expanded(flex: 5, child: recentActivitiesList)
            : recentActivitiesList,
        if (allActivitiesForEmpty.isNotEmpty && !widget.isLoading)
          paginationControls,
        const SizedBox(height: 16),
        if (allActivitiesForEmpty.isNotEmpty && !widget.isLoading)
          viewAllButton,
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
            ? Expanded(flex: 4, child: feedList)
            : feedList,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.all(32),
      child: innerContent,
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String imgUrl;
  final String? activityImageUrl;
  final String? studentId;
  final String? activityId;
  final String? studentName;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.imgUrl,
    this.activityImageUrl,
    this.studentId,
    this.activityId,
    this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivityImage =
        activityImageUrl != null && activityImageUrl!.isNotEmpty;
    final displayImageUrl = hasActivityImage
        ? ImageUtils.getFullImageUrl(activityImageUrl)
        : (imgUrl.isNotEmpty ? ImageUtils.getFullImageUrl(imgUrl) : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: displayImageUrl != null
                    ? Image.network(
                        displayImageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                      )
                    : _buildFallbackIcon(),
              ),
              const SizedBox(width: 16),
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
                        fontSize: 13,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle\n$time',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textFaint,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: _C.textMuted,
                size: 20,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: _C.greenLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(PhosphorIconsFill.image, color: _C.green, size: 20),
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
      padding: const EdgeInsets.only(bottom: 24.0),
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
          const SizedBox(width: 12),
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
