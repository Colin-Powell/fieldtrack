import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/supervisor_top_header.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF3F4F6);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const red = Color(0xFFEF4444);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 40.0;
}

// ==========================================
// DATA MODELS
// ==========================================
class StudentActivity {
  final String id;
  final String name;
  final String avatarUrl;
  final String reg;
  final String programme;
  final String topic;
  final int activitiesCount;
  final String checkInStatus;
  final String lastActivity;

  const StudentActivity({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.reg,
    required this.programme,
    required this.topic,
    required this.activitiesCount,
    required this.checkInStatus,
    required this.lastActivity,
  });
}

class TrendDataPoint {
  final String label;
  final double value;
  final String dateLabel;

  const TrendDataPoint({
    required this.label,
    required this.value,
    required this.dateLabel,
  });
}

class StatCardModel {
  final String title;
  final String value;
  final String percentage;
  final bool isUp;
  final IconData icon;
  final Color iconColor;
  final List<Color> circleGradientColors;
  final bool isCardGradient;

  const StatCardModel({
    required this.title,
    required this.value,
    required this.percentage,
    required this.isUp,
    required this.icon,
    required this.iconColor,
    required this.circleGradientColors,
    this.isCardGradient = false,
  });
}

class DashboardData {
  final List<StatCardModel> stats;
  final List<TrendDataPoint> trend;
  final double gaugePercentage;
  final List<StudentActivity> students;

  const DashboardData({
    required this.stats,
    required this.trend,
    required this.gaugePercentage,
    required this.students,
  });
}

// ==========================================
// MAIN SCREEN
// ==========================================
class SupervisorReportsScreen extends StatefulWidget {
  final Future<DashboardData> Function(String timeFilter, String category)?
  fetchDashboardData;
  final Stream<List<TrendDataPoint>>? liveTrendStream;
  final void Function(String action, StudentActivity student)? onStudentAction;
  final Future<void> Function(List<StudentActivity> visibleRows)? onExport;

  const SupervisorReportsScreen({
    super.key,
    this.fetchDashboardData,
    this.liveTrendStream,
    this.onStudentAction,
    this.onExport,
  });

  @override
  State<SupervisorReportsScreen> createState() =>
      _SupervisorReportsScreenState();
}

class _SupervisorReportsScreenState extends State<SupervisorReportsScreen> {
  // ── Filters & UI state ──────────────────────────────────────────────
  String _globalSearch = '';
  String _tableSearch = '';
  String _timeFilter = 'This Month';
  String _categoryFilter = 'Field Survey';
  String _statusFilter = 'All';
  String _programmeFilter = 'All';
  int? _hoveredBarIndex = 2;
  bool _isExporting = false;

  final _timeFilterOptions = const [
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];
  final _categoryOptions = const [
    'Field Survey',
    'Lab Work',
    'Interviews',
    'Site Visits',
  ];

  // ── Data ────────────────────────────────────────────────────────────
  bool _isLoading = true;
  List<StatCardModel> _stats = [];
  List<TrendDataPoint> _trendData = [];
  List<StudentActivity> _students = [];
  List<dynamic> _logSummary = [];
  double _gaugePercentage = 0.98;

  StreamSubscription<List<TrendDataPoint>>? _liveSub;

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    if (widget.liveTrendStream != null) {
      _liveSub = widget.liveTrendStream!.listen((data) {
        if (mounted) setState(() => _trendData = data);
      });
    }
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  void _showPillSnackbar(String message, {Color color = _C.textDark}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        width: 400,
        backgroundColor: color,
        elevation: 6,
      ),
    );
  }

  // ── Export: generates a CSV file of the visible report data ────────
  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      if (widget.onExport != null) {
        await widget.onExport!(_filteredStudents);
      } else {
        await _saveCsvReport();
      }
      if (!mounted) return;
      _showPillSnackbar('Report exported successfully', color: _C.green);
    } catch (e) {
      if (!mounted) return;
      _showPillSnackbar('Export failed: $e', color: _C.red);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveCsvReport() async {
    final buffer = StringBuffer();
    buffer.writeln('FieldTrack Supervisor Report');
    buffer.writeln('Period: $_timeFilter');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln(
      'Student Name,Registration,Programme,Topic,Activities,Status,Last Activity',
    );
    for (final s in _filteredStudents) {
      final name = s.name.replaceAll(',', ' ');
      final reg = s.reg.replaceAll(',', ' ');
      final prog = s.programme.replaceAll(',', ' ');
      final topic = s.topic.replaceAll(',', ' ');
      buffer.writeln(
        '$name,$reg,$prog,$topic,${s.activitiesCount},${s.checkInStatus},${s.lastActivity}',
      );
    }

    final csv = buffer.toString();
    try {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '${dir.path}/supervisor_report_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        await file.writeAsString(csv);
      } else {
        // Web fallback: trigger a download via blob
        final bytes = utf8.encode(csv);
        final blob = base64Encode(bytes);
        // ignore: avoid_print
        print('CSV_READY:$blob');
      }
    } catch (e) {
      // ignore: avoid_print
      print('CSV export fallback: $e');
    }
  }

  // ── Print: opens a printable dialog with report summary ────────────
  Future<void> _handlePrint() async {
    await showDialog(
      context: context,
      builder: (ctx) => _PrintPreviewDialog(
        timeFilter: _timeFilter,
        stats: _stats,
        trendData: _trendData,
        students: _filteredStudents,
      ),
    );
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(
        '/reports/supervisor',
        queryParameters: {'period': _timeFilter},
      );
      final rawData = response.data;

      final statsData = (rawData['stats'] as Map<String, dynamic>?) ?? {};
      final parsedStats = [
        StatCardModel(
          title: 'Total Activities',
          value: '${statsData['totalActivities'] ?? 0}',
          percentage: '',
          isUp: true,
          icon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
          iconColor: _C.green,
          circleGradientColors: const [Colors.white, Colors.white],
          isCardGradient: true,
        ),
        StatCardModel(
          title: 'Report Submitted',
          value: '${statsData['reportsSubmitted'] ?? 0}',
          percentage: '',
          isUp: true,
          icon: PhosphorIconsFill.fileText,
          iconColor: Colors.white,
          circleGradientColors: const [_C.green, _C.green],
        ),
        StatCardModel(
          title: 'Pending Review',
          value: '${statsData['pendingReviews'] ?? 0}',
          percentage: '',
          isUp: true,
          icon: PhosphorIconsFill.clock,
          iconColor: Colors.white,
          circleGradientColors: const [_C.green, _C.green],
        ),
        StatCardModel(
          title: 'Approved Logs',
          value: '${statsData['approvedLogs'] ?? 0}',
          percentage: '',
          isUp: true,
          icon: PhosphorIconsFill.checkCircle,
          iconColor: Colors.white,
          circleGradientColors: const [Color(0xFF374151), Color(0xFF374151)],
        ),
      ];

      final rawGauge = (rawData['gaugeMap'] as Map<String, dynamic>?) ?? {};
      final parsedGauge = rawGauge.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

      final rawTrend = (rawData['trendData'] as List<dynamic>?) ?? [];
      final parsedTrend = rawTrend
          .map(
            (t) => TrendDataPoint(
              label: t['label'] ?? '',
              value: (t['value'] as num).toDouble(),
              dateLabel: t['dateLabel'] ?? '',
            ),
          )
          .toList();

      final rawActivities =
          (rawData['recentActivities'] as List<dynamic>?) ?? [];
      final parsedActivities = rawActivities
          .map(
            (a) => StudentActivity(
              id: a['id'] ?? '',
              name: a['studentName'] ?? 'Unknown',
              avatarUrl: a['avatarUrl'] ?? '',
              reg: '',
              programme: '',
              topic: a['activityTitle'] ?? '',
              activitiesCount: 1,
              checkInStatus: a['status'] ?? '',
              lastActivity: a['time'] ?? '',
            ),
          )
          .toList();

      final rawLogSummary = (rawData['logSummary'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _stats = parsedStats;
        _trendData = parsedTrend;
        _students = parsedActivities;
        _logSummary = rawLogSummary;
        _gaugePercentage = parsedGauge.isNotEmpty
            ? parsedGauge.values.first
            : 0.0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showPillSnackbar('Failed to load reports', color: _C.red);
    }
  }

  List<String> get _programmeOptions => [
    'All',
    ..._students.map((s) => s.programme).toSet(),
  ];

  List<StudentActivity> get _filteredStudents {
    final q = _tableSearch.toLowerCase();
    final gq = _globalSearch.toLowerCase();
    return _students.where((s) {
      final matchesTableSearch =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.reg.toLowerCase().contains(q);
      final matchesGlobalSearch =
          gq.isEmpty ||
          s.name.toLowerCase().contains(gq) ||
          s.programme.toLowerCase().contains(gq) ||
          s.topic.toLowerCase().contains(gq);
      final matchesStatus =
          _statusFilter == 'All' || s.checkInStatus == _statusFilter;
      final matchesProgramme =
          _programmeFilter == 'All' || s.programme == _programmeFilter;
      return matchesTableSearch &&
          matchesGlobalSearch &&
          matchesStatus &&
          matchesProgramme;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: RefreshIndicator(
            color: _C.green,
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(),
                  const SizedBox(height: 32),
                  _buildActionFilters(),
                  const SizedBox(height: 24),
                  _buildStatCards(),
                  const SizedBox(height: 24),
                  _buildChartsRow(),
                  const SizedBox(height: 24),
                  _buildTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ─────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return SupervisorTopHeader(
      title: 'Reports',
      subtitle: 'Overview of field activities and student performance',
      searchHint: 'Search Student...',
      onSearchChanged: (v) => setState(() => _globalSearch = v),
    );
  }

  // ── 2. Action Pill Filters ────────────────────────────────────────────
  Widget _buildActionFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildDropdownActionPill(
          label: _timeFilter,
          options: _timeFilterOptions,
          onSelected: (v) {
            setState(() => _timeFilter = v);
            _loadDashboard();
          },
          bg: _C.greenLight,
          textColor: _C.green,
          circleBg: Colors.white,
          iconColor: _C.green,
        ),
        const SizedBox(width: 16),
        _buildPrintPill(),
        const SizedBox(width: 16),
        _buildExportPill(),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _openFiltersSheet,
          child: _buildActionPill(
            'Filters',
            PhosphorIcons.faders(PhosphorIconsStyle.bold),
            _C.green,
            Colors.white,
            Colors.white,
            _C.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPrintPill() {
    return GestureDetector(
      onTap: _handlePrint,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: _C.greenLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Print',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: _C.green,
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
              child: Icon(
                PhosphorIcons.printer(PhosphorIconsStyle.bold),
                color: _C.green,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    Color circleBg,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownActionPill({
    required String label,
    required List<String> options,
    required void Function(String) onSelected,
    required Color bg,
    required Color textColor,
    required Color circleBg,
    required Color iconColor,
  }) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(popupMenuTheme: const PopupMenuThemeData(color: Colors.white)),
      child: PopupMenuButton<String>(
        tooltip: '',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: onSelected,
        itemBuilder: (ctx) => options
            .map(
              (o) => PopupMenuItem(
                value: o,
                child: Text(o, style: const TextStyle(fontFamily: 'Poppins')),
              ),
            )
            .toList(),
        child: _buildActionPill(
          label,
          PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
          bg,
          textColor,
          circleBg,
          iconColor,
        ),
      ),
    );
  }

  Widget _buildExportPill() {
    return GestureDetector(
      onTap: _isExporting ? null : _handleExport,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: _C.greenLight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: _C.green,
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
              child: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _C.green,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.uploadSimple(PhosphorIconsStyle.bold),
                      color: _C.green,
                      size: 14,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFiltersSheet() {
    String tempStatus = _statusFilter;
    String tempProgramme = _programmeFilter;
    final programmeOptions = _programmeOptions;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: StatefulBuilder(
                builder: (ctx, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Students',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: _C.textDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: _C.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Online', 'Offline'].map((s) {
                          final selected = tempStatus == s;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempStatus = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? _C.greenLight : _C.bg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? _C.green : _C.textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Programme',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: _C.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: const PopupMenuThemeData(
                              color: Colors.white,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            tooltip: '',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (v) =>
                                setModalState(() => tempProgramme = v),
                            itemBuilder: (ctx) => programmeOptions
                                .map(
                                  (p) => PopupMenuItem(
                                    value: p,
                                    child: Text(
                                      p,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    programmeOptions.contains(tempProgramme)
                                        ? tempProgramme
                                        : 'All',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: _C.textDark,
                                    ),
                                  ),
                                  Icon(
                                    PhosphorIcons.caretDown(
                                      PhosphorIconsStyle.bold,
                                    ),
                                    size: 16,
                                    color: _C.textFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: const BorderSide(color: _C.border),
                              ),
                              onPressed: () => setModalState(() {
                                tempStatus = 'All';
                                tempProgramme = 'All';
                              }),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: _C.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _statusFilter = tempStatus;
                                  _programmeFilter = tempProgramme;
                                });
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 3. Stat Cards ─────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final count = _isLoading ? 4 : _stats.length;
        List<Widget> children = [];

        for (int i = 0; i < count; i++) {
          final card = _isLoading ? _statCardSkeleton() : _statCard(_stats[i]);

          if (isNarrow) {
            children.add(
              SizedBox(width: (constraints.maxWidth - 24) / 2, child: card),
            );
          } else {
            children.add(
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == count - 1 ? 0 : 24.0),
                  child: card,
                ),
              ),
            );
          }
        }

        return isNarrow
            ? Wrap(spacing: 24, runSpacing: 24, children: children)
            : Row(children: children);
      },
    );
  }

  Widget _statCard(StatCardModel stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        gradient: stat.isCardGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFD1FAE5), Colors.white],
                stops: const [0.0, 0.80],
              )
            : null,
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: stat.circleGradientColors,
                  ),
                ),
                child: Icon(stat.icon, color: stat.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stat.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            stat.value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                stat.isUp
                    ? PhosphorIcons.arrowUp(PhosphorIconsStyle.bold)
                    : PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                color: stat.isUp ? _C.green : _C.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${stat.percentage} ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: stat.isUp ? _C.green : _C.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Text(
                'from April',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.all(28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(height: 24),
          _ShimmerBox(width: 80, height: 30),
          SizedBox(height: 12),
          _ShimmerBox(width: 120, height: 14),
        ],
      ),
    );
  }

  // ── 4. Charts ─────────────────────────────────────────────────────────
  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        final trendChart = Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_C.cardRadius),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity Trend',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _C.textDark,
                    ),
                  ),
                  _buildDropdownActionPill(
                    label: _timeFilter,
                    options: _timeFilterOptions,
                    onSelected: (v) {
                      setState(() {
                        _timeFilter = v;
                        _hoveredBarIndex = null;
                      });
                      _loadDashboard();
                    },
                    bg: _C.greenLight,
                    textColor: _C.green,
                    circleBg: Colors.white,
                    iconColor: _C.green,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const _ShimmerBox(height: 240, borderRadius: 24)
              else
                MouseRegion(
                  onHover: (e) => _updateHoverIndex(
                    e.localPosition,
                    constraints.maxWidth > 950
                        ? (constraints.maxWidth - 24) * 0.65
                        : constraints.maxWidth,
                  ),
                  onExit: (_) => setState(() => _hoveredBarIndex = null),
                  child: GestureDetector(
                    onTapDown: (e) => _updateHoverIndex(
                      e.localPosition,
                      constraints.maxWidth > 950
                          ? (constraints.maxWidth - 24) * 0.65
                          : constraints.maxWidth,
                    ),
                    onPanUpdate: (e) => _updateHoverIndex(
                      e.localPosition,
                      constraints.maxWidth > 950
                          ? (constraints.maxWidth - 24) * 0.65
                          : constraints.maxWidth,
                    ),
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BarChartPainter(
                          dataPoints: _trendData,
                          activeIndex: _hoveredBarIndex,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        final gaugeChart = Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_C.cardRadius),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activities by\nCategory',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _C.textDark,
                      height: 1.2,
                    ),
                  ),
                  _buildDropdownActionPill(
                    label: _categoryFilter,
                    options: _categoryOptions,
                    onSelected: (v) {
                      setState(() => _categoryFilter = v);
                      _loadDashboard();
                    },
                    bg: _C.greenLight,
                    textColor: _C.green,
                    circleBg: Colors.white,
                    iconColor: _C.green,
                  ),
                ],
              ),
              const Spacer(),
              if (_isLoading)
                const _ShimmerBox(width: 180, height: 180, borderRadius: 90)
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(end: _gaugePercentage),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) {
                    return SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _GaugeChartPainter(percentage: value),
                      ),
                    );
                  },
                ),
              const Spacer(),
              const Text(
                'Submitted Field Survey',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _C.textDark,
                ),
              ),
            ],
          ),
        );

        if (isNarrow)
          return Column(
            children: [
              trendChart,
              const SizedBox(height: 24),
              SizedBox(height: 400, child: gaugeChart),
            ],
          );
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 65, child: trendChart),
              const SizedBox(width: 24),
              Expanded(flex: 35, child: gaugeChart),
            ],
          ),
        );
      },
    );
  }

  void _updateHoverIndex(Offset pos, double containerWidth) {
    if (_trendData.isEmpty) return;
    const leftPadding = 30.0;
    final chartWidth = containerWidth - 64 - leftPadding;
    if (chartWidth <= 0) return;

    final barWidth = min(54.0, (chartWidth / _trendData.length) * 0.6);
    final spacing =
        (chartWidth - (barWidth * _trendData.length)) /
        max(1, _trendData.length - 1);

    for (int i = 0; i < _trendData.length; i++) {
      final xStart = leftPadding + i * (barWidth + spacing);
      final xEnd = xStart + barWidth;

      if (pos.dx >= xStart - (spacing / 2) && pos.dx <= xEnd + (spacing / 2)) {
        if (_hoveredBarIndex != i) setState(() => _hoveredBarIndex = i);
        return;
      }
    }
  }

  // ── 5. Data Table ─────────────────────────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = max(constraints.maxWidth, 1000.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Active Students',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _C.textDark,
                      ),
                    ),
                    Container(
                      width: 240,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.magnifyingGlass(),
                            color: _C.textFaint,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _tableSearch = v),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search Student...',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: _C.textFaint,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                filled: false,
                                hoverColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Column(children: List.generate(3, (_) => _tableRowSkeleton()))
              else if (_filteredStudents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No students found.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: tableWidth,
                      maxWidth: tableWidth,
                    ),
                    child: Column(
                      children: _filteredStudents
                          .map((s) => _buildStudentRow(s))
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _tableRowSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: const [
          _ShimmerBox(width: 44, height: 44, borderRadius: 22),
          SizedBox(width: 16),
          _ShimmerBox(width: 140, height: 14),
          Spacer(),
          _ShimmerBox(width: 90, height: 14),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentActivity student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipOval(
                  child: student.avatarUrl.isNotEmpty
                      ? Image.network(
                          ImageUtils.getFullImageUrl(student.avatarUrl),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: _C.bg,
                            child: const Icon(
                              Icons.person,
                              color: _C.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: _C.bg,
                          child: const Icon(Icons.person, color: _C.textMuted),
                        ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.reg,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.programme,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.topic,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${student.activitiesCount} Activities',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  student.checkInStatus,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.lastActivity,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(width: 40, child: _buildRowActions(student)),
        ],
      ),
    );
  }

  Widget _buildRowActions(StudentActivity student) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(popupMenuTheme: const PopupMenuThemeData(color: Colors.white)),
      child: PopupMenuButton<String>(
        tooltip: '',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (ctx) => const [
          PopupMenuItem(
            value: 'view',
            child: Text(
              'View Profile',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          PopupMenuItem(
            value: 'message',
            child: Text(
              'Send Message',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          PopupMenuItem(
            value: 'flag',
            child: Text(
              'Flag for Review',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Text(
              'Remove Student',
              style: TextStyle(fontFamily: 'Poppins', color: _C.red),
            ),
          ),
        ],
        onSelected: (action) {
          widget.onStudentAction?.call(action, student);
          if (action == 'view') {
            final studentData = StudentData(
              id: student.id,
              name: student.name,
              avatarUrl: student.avatarUrl,
              reg: student.reg,
              programme: student.programme,
              topic: student.topic,
              status: student.checkInStatus == 'Online'
                  ? 'In Field'
                  : 'Offline',
              checkInStatus: student.checkInStatus,
              lastActivity: student.lastActivity,
            );
            context.go(
              '/supervisor/student/${student.id}',
              extra: studentData.toMap(),
            );
          } else {
            _showPillSnackbar('${_actionLabel(action)}: ${student.name}');
          }
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.border),
          ),
          child: Icon(
            PhosphorIcons.dotsThreeVertical(),
            color: _C.textFaint,
            size: 20,
          ),
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'view':
        return 'Viewing profile';
      case 'message':
        return 'Opening chat with';
      case 'flag':
        return 'Flagged for review';
      case 'remove':
        return 'Removed';
      default:
        return action;
    }
  }
}

// ==========================================
// PRINT PREVIEW DIALOG
// ==========================================
class _PrintPreviewDialog extends StatelessWidget {
  final String timeFilter;
  final List<StatCardModel> stats;
  final List<TrendDataPoint> trendData;
  final List<StudentActivity> students;

  const _PrintPreviewDialog({
    required this.timeFilter,
    required this.stats,
    required this.trendData,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Print Report',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: _C.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Period: $timeFilter',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: stats
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.greenLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: _C.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.value,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        color: _C.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Activity Trend',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...trendData.map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  t.label,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _C.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: trendData.isEmpty
                                        ? 0
                                        : (t.value /
                                              (trendData
                                                  .map((x) => x.value)
                                                  .reduce(max)
                                                  .clamp(1, double.infinity))),
                                    minHeight: 8,
                                    backgroundColor: _C.border,
                                    valueColor: const AlwaysStoppedAnimation(
                                      _C.green,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${t.value.toInt()}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _C.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Top Active Students',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...students
                          .take(10)
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: _C.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.topic,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: _C.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.lastActivity,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: _C.textFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: _C.border),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // For web, trigger the browser print dialog.
                      // ignore: avoid_print
                      print('PRINT_REPORT:$timeFilter');
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.print,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Print',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SKELETON / SHIMMER
// ==========================================
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  const _ShimmerBox({this.width, required this.height, this.borderRadius = 12});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.5 + (_controller.value * 0.3);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _C.border.withOpacity(opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ==========================================
// CUSTOM PAINTERS (Interactive & Dynamic)
// ==========================================
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
      ..color = _C.border
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
          color: _C.textFaint,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 8));

      double x = leftPadding;
      while (x < size.width) {
        canvas.drawLine(Offset(x, yPos), Offset(x + 5, yPos), gridPaint);
        x += 10;
      }
    }

    final barWidth = min(54.0, (chartWidth / dataPoints.length) * 0.6);
    final spacing =
        (chartWidth - (barWidth * dataPoints.length)) /
        max(1, dataPoints.length - 1);
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB).withOpacity(0.4);

    final labelFontSize = dataPoints.length > 7 ? 10.0 : 12.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final xPos = leftPadding + i * (barWidth + spacing);
      final barHeight = (point.value / maxY) * chartHeight;
      final yPos = chartHeight - barHeight;
      final isActive = activeIndex == i;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xPos, 0, barWidth, chartHeight),
        const Radius.circular(32),
      );
      canvas.drawRRect(bgRect, bgPaint);

      final barPaint = Paint()
        ..shader = isActive
            ? ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFF4ADE80), _C.green],
              )
            : ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFFD1FAE5), const Color(0xFFD1FAE5)],
              );

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xPos, yPos, barWidth, barHeight),
        const Radius.circular(32),
      );
      canvas.drawRRect(barRect, barPaint);

      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(
          color: _C.textMuted,
          fontSize: labelFontSize,
          fontFamily: 'Poppins',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos + (barWidth - textPainter.width) / 2, chartHeight + 12),
      );

      if (isActive) {
        canvas.drawCircle(
          Offset(xPos + barWidth / 2, yPos),
          6,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(xPos + barWidth / 2, yPos),
          4,
          Paint()..color = _C.green,
        );

        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: '${point.dateLabel}\n',
              style: const TextStyle(
                color: _C.textFaint,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
            const TextSpan(
              text: '● ',
              style: TextStyle(color: _C.green, fontSize: 12),
            ),
            TextSpan(
              text: 'Activities: ${point.value.toInt()}',
              style: const TextStyle(
                color: _C.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        );
        textPainter.layout();

        final tooltipWidth = max(114.0, textPainter.width + 24);
        final rawLeft = xPos - (tooltipWidth / 2) + (barWidth / 2);
        final clampedLeft = rawLeft.clamp(8.0, size.width - tooltipWidth - 8.0);
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(clampedLeft, yPos - 64, tooltipWidth, 52),
          const Radius.circular(16),
        );

        canvas.drawRRect(
          tooltipRect.shift(const Offset(0, 4)),
          Paint()
            ..color = Colors.black.withOpacity(0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);
        textPainter.paint(canvas, Offset(clampedLeft + 12, yPos - 56));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.dataPoints != dataPoints;
}

class _GaugeChartPainter extends CustomPainter {
  final double percentage;

  _GaugeChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const int totalSegments = 8;
    const gapDegrees = 7.5;
    final gap = gapDegrees * pi / 180;
    final double totalAngle = pi;
    final double segmentAngle =
        (totalAngle - (gap * (totalSegments - 1))) / totalSegments;

    // Calculate fully filled segments and fractional remainder for partial fill
    final totalFilled = percentage * totalSegments;
    final filledSegments = totalFilled.floor();
    final partialFill = totalFilled - filledSegments;

    double currentAngle = pi;

    for (int i = 0; i < totalSegments; i++) {
      final isSolid = i < filledSegments;
      final isPartial = i == filledSegments && partialFill > 0;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.22
        ..strokeCap = StrokeCap.round;

      if (isSolid) {
        paint.color = _C.green;
      } else if (isPartial) {
        // Gradient spans only the partial fill fraction of this segment
        final partialEndAngle = currentAngle + segmentAngle * partialFill;
        paint.shader = ui.Gradient.linear(
          Offset(
            center.dx + radius * cos(currentAngle),
            center.dy + radius * sin(currentAngle),
          ),
          Offset(
            center.dx + radius * cos(partialEndAngle),
            center.dy + radius * sin(partialEndAngle),
          ),
          [_C.green, _C.bg],
        );
      } else {
        paint.color = _C.bg;
      }

      canvas.drawArc(rect, currentAngle, segmentAngle, false, paint);
      currentAngle += segmentAngle + gap;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(percentage * 100).toInt()}%',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: _C.textDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Vertically center text within the inner space of the gauge arc
    final availableHeight = center.dy - radius * 0.65;
    final textY =
        center.dy -
        textPainter.height -
        (availableHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, textY));
  }

  @override
  bool shouldRepaint(covariant _GaugeChartPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
