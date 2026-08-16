import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:provider/provider.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:fieldtrack/features/supervisor/dashboard/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import '../widgets/supervisor_top_header.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF3F4F6);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 24.0;
  static const controlHeight = 48.0;
}

enum _ScreenState { ready, empty, loading, error }

class SupervisorStudentsScreen extends StatefulWidget {
  const SupervisorStudentsScreen({super.key});

  @override
  State<SupervisorStudentsScreen> createState() =>
      _SupervisorStudentsScreenState();
}

class _SupervisorStudentsScreenState extends State<SupervisorStudentsScreen> {
  final _ScreenState _state = _ScreenState.ready;
  String _selectedFilter = 'All Students';
  String _searchQuery = '';

  String _programmeFilter = 'Programme';
  String _statusFilter = 'Status';

  List<String> get _programmes {
    final state = context.read<DashboardState>();
    final Set<String> prog = {'Programme'};
    for (final s in state.students) {
      if (s.programme.isNotEmpty) prog.add(s.programme);
    }
    return prog.toList();
  }

  List<String> get _statuses {
    return const ['Status', 'In Field', 'Checked Out', 'Not Checked in'];
  }

  List<StudentData> _filtered(List<StudentData> allStudents) {
    var list = List<StudentData>.from(allStudents);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.reg.toLowerCase().contains(q) ||
                s.topic.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_selectedFilter != 'All Students') {
      if (_selectedFilter == 'Active') {
        list = list.where((s) => s.status != 'Not Checked in').toList();
      } else {
        list = list
            .where(
              (s) =>
                  s.status == _selectedFilter ||
                  s.checkInStatus == _selectedFilter,
            )
            .toList();
      }
    }

    if (_programmeFilter != 'Programme') {
      list = list.where((s) => s.programme == _programmeFilter).toList();
    }
    if (_statusFilter != 'Status') {
      list = list
          .where(
            (s) =>
                s.status == _statusFilter || s.checkInStatus == _statusFilter,
          )
          .toList();
    }

    return list;
  }

  int _getCount(List<StudentData> allStudents, String filter) {
    if (filter == 'All Students') return allStudents.length;
    if (filter == 'Active') {
      return allStudents.where((s) => s.status != 'Not Checked in').length;
    }
    return allStudents
        .where((s) => s.status == filter || s.checkInStatus == filter)
        .length;
  }

  void _showAddStudentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddStudentModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: SafeArea(
        // Outer layout is fixed (no scroll view)
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 32),
              _buildFiltersRow(),
              const SizedBox(height: 24),
              // Body takes remaining height
              Expanded(child: _buildBody(context)),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final state = context.watch<DashboardState>();
                  final list = _filtered(state.students);
                  if (list.isNotEmpty) {
                    return _buildPagination(list.length);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Row (Figma matching layout) ─────────────────────────────────
  Widget _buildTopHeader(BuildContext context) {
    final addStudentBtn = SizedBox(
      height: _C.controlHeight,
      child: ElevatedButton.icon(
        onPressed: _showAddStudentModal,
        icon: const Icon(
          PhosphorIconsRegular.plusCircle,
          size: 20,
          color: Colors.white,
        ),
        label: const Text(
          'Add Student',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.green,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );

    return SupervisorTopHeader(
      title: 'Students',
      subtitle: 'Manage and monitor all students under your supervision',
      searchHint: 'Search by name, reg. number or topic...',
      onSearchChanged: (v) => setState(() => _searchQuery = v),
      trailingWidget: addStudentBtn,
    );
  }

  // ── Filters Row ───────────────────────────────────────────────────────
  Widget _buildFiltersRow() {
    final state = context.watch<DashboardState>();
    final studentsList = state.students;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All Students',
            count: '${_getCount(studentsList, "All Students")}',
            selected: _selectedFilter == 'All Students',
            onTap: () => setState(() => _selectedFilter = 'All Students'),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Active',
            count: '${_getCount(studentsList, "Active")}',
            selected: _selectedFilter == 'Active',
            onTap: () => setState(() => _selectedFilter = 'Active'),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Checked In',
            count: '${_getCount(studentsList, "Checked In")}',
            selected: _selectedFilter == 'Checked In',
            onTap: () => setState(() => _selectedFilter = 'Checked In'),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'In Field',
            count: '${_getCount(studentsList, "In Field")}',
            selected: _selectedFilter == 'In Field',
            onTap: () => setState(() => _selectedFilter = 'In Field'),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Checked Out',
            count: '${_getCount(studentsList, "Checked Out")}',
            selected: _selectedFilter == 'Checked Out',
            onTap: () => setState(() => _selectedFilter = 'Checked Out'),
          ),

          const SizedBox(width: 16),
          _DropdownFilter(
            label: 'Programme',
            currentValue: _programmeFilter,
            items: _programmes,
            onChanged: (val) => setState(() => _programmeFilter = val),
          ),
          const SizedBox(width: 12),
          _DropdownFilter(
            label: 'Status',
            currentValue: _statusFilter,
            items: _statuses,
            onChanged: (val) => setState(() => _statusFilter = val),
          ),
          const SizedBox(width: 12),
          _OutlinedIconButton(
            icon: PhosphorIconsRegular.funnel,
            label: 'Filters',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    final state = context.watch<DashboardState>();
    final list = _filtered(state.students);

    if (state.students.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_C.cardRadius),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(PhosphorIconsRegular.student, size: 48, color: _C.textFaint),
            SizedBox(height: 16),
            Text(
              'No Assigned Students',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You currently have no students assigned to you.',
              style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_C.cardRadius),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(PhosphorIconsRegular.users, size: 48, color: _C.textFaint),
            SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters.',
              style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
            ),
          ],
        ),
      );
    }

    return _buildTable(context, list);
  }

  // ── Table (Single Shot Width, No Horizontal Scroll) ───────────────────
  Widget _buildTable(BuildContext context, List<StudentData> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: max(constraints.maxWidth, 1000),
              ),
              child: SizedBox(
                width: max(constraints.maxWidth, 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: _TableHeader('Student')),
                          Expanded(flex: 2, child: _TableHeader('Reg. Number')),
                          Expanded(flex: 2, child: _TableHeader('Programme')),
                          Expanded(
                            flex: 3,
                            child: _TableHeader('Research Topic'),
                          ),
                          Expanded(flex: 2, child: _TableHeader('Status')),
                          Expanded(flex: 2, child: _TableHeader('Review')),
                          Expanded(
                            flex: 2,
                            child: _TableHeader('Last Activity'),
                          ),
                          SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.center,
                              child: _TableHeader('Actions'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _C.border),
                    // Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: _C.border),
                        itemBuilder: (context, index) =>
                            _StudentTableRow(student: list[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────
  Widget _buildPagination(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing 1 to $count Of $count Students',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: _C.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: const [
            _PaginationBtn(icon: Icons.chevron_left, enabled: true),
            SizedBox(width: 8),
            _PaginationPage('1', selected: true),
            SizedBox(width: 8),
            _PaginationPage('2', selected: false),
            SizedBox(width: 8),
            _PaginationPage('3', selected: false),
            SizedBox(width: 8),
            _PaginationPage('4', selected: false),
            SizedBox(width: 8),
            _PaginationPage('5', selected: false),
            SizedBox(width: 8),
            _PaginationPage('...', selected: false),
            SizedBox(width: 8),
            _PaginationBtn(icon: Icons.chevron_right, enabled: true),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// Filter chip
// ==========================================
class _FilterChip extends StatelessWidget {
  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _C.green : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? _C.green : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selected ? Colors.white : _C.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.9) : _C.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: selected ? _C.green : _C.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Dropdown filter
// ==========================================
class _DropdownFilter extends StatelessWidget {
  final String label;
  final String currentValue;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.currentValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return items
            .map(
              (e) => PopupMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: currentValue == e
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsRegular.caretDown,
              color: _C.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _C.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Table pieces
// ==========================================
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _C.textDark,
      ),
    );
  }
}

class _StudentTableRow extends ConsumerWidget {
  final StudentData student;
  const _StudentTableRow({required this.student});

  void _navigateToProfile(BuildContext context) {
    context.go('/supervisor/student/${student.id}');
  }

  /// Format an ISO timestamp or raw string as a human-readable "time ago" string.
  static String _formatLastActivity(String raw) {
    if (raw.isEmpty || raw == '—') return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _navigateToProfile(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: AppAvatar(
                      imagePath: student.avatarUrl.isNotEmpty
                          ? student.avatarUrl
                          : null,
                      size: 36,
                      shape: AvatarShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PillBadge(label: student.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) {
                    final activitiesAsync = ref.watch(
                      studentActivitiesByStudentIdProvider({'studentId': student.id}),
                    );

                    return activitiesAsync.when(
                      data: (result) {
                        if (result is Success<List<dynamic>>) {
                          final activities = result.data;
                          final pendingCount = activities.where((a) {
                            final map = a as Map<String, dynamic>;
                            final status = map['status'] as String? ?? '';
                            return status == 'SUBMITTED' ||
                                status == 'UNDER_REVIEW';
                          }).length;

                          if (pendingCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF97316,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$pendingCount Pending',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFFC2410C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text(
                          '—',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: _C.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const Text(
                        '—',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatLastActivity(student.lastActivity),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Working Actions Menu
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    color: _C.textFaint,
                    size: 20,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text(
                      'View Details',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Edit Student',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    _navigateToProfile(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  const _PillBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (label.toUpperCase()) {
      case 'IN FIELD':
      case 'CHECKED IN':
        bg = const Color(0xFFE6F5EC);
        text = _C.green;
        break;
      case 'CHECKED OUT':
        bg = const Color(0xFFE8F0FE);
        text = const Color(0xFF4285F4);
        break;
      case 'OFFLINE':
      case 'NOT CHECKED IN':
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFF97316);
        break;
      case 'ACTIVE':
        bg = const Color(0xFFE6F5EC);
        text = _C.green;
        break;
      case 'SUSPENDED':
        bg = const Color(0xFFFFF3CD);
        text = const Color(0xFFD97706);
        break;
      case 'ARCHIVED':
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF6B7280);
        break;
      case '—':
        bg = Colors.transparent;
        text = _C.textMuted;
        break;
      default:
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFF97316);
        break;
    }

    if (label == '—') {
      return Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ==========================================
// Pagination
// ==========================================
class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  const _PaginationBtn({required this.icon, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _C.border),
      ),
      child: Icon(icon, size: 20, color: enabled ? _C.textDark : _C.textFaint),
    );
  }
}

class _PaginationPage extends StatelessWidget {
  final String page;
  final bool selected;
  const _PaginationPage(this.page, {required this.selected});

  @override
  Widget build(BuildContext context) {
    if (page == '...') {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _C.border),
        ),
        child: const Text('•••', style: TextStyle(color: _C.textMuted)),
      );
    }
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.transparent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _C.textFaint : _C.border),
      ),
      child: Text(
        page,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: selected ? _C.textDark : _C.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ==========================================
// Model
// ==========================================
class _StudentRow {
  final String id,
      name,
      avatarUrl,
      reg,
      programme,
      topic,
      status,
      checkInStatus,
      lastActivity;
  const _StudentRow({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.reg,
    required this.programme,
    required this.topic,
    required this.status,
    required this.checkInStatus,
    required this.lastActivity,
  });
}

// ==========================================
// Center Pop-up Modal (Add Student)
// ==========================================
class AddStudentModal extends StatelessWidget {
  const AddStudentModal();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hugs content tightly
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Student',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    PhosphorIconsRegular.x,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildFormInput('Full Name', 'e.g., John Doe'),
            const SizedBox(height: 16),

            _buildFormInput('Registration Number', 'e.g., MB21/PU/42442/22'),
            const SizedBox(height: 16),

            _buildFormInput('Programme', 'e.g., MSc Geography'),
            const SizedBox(height: 16),

            _buildFormInput('Research Topic', 'Enter topic', maxLines: 2),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: const BorderSide(color: _C.border),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle save logic
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Save Student',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.textFaint),
            filled: true,
            fillColor: _C.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
