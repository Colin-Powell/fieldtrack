import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';
import 'dart:math';
import 'package:fieldtrack/core/network/error_handler.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';

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
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const cardRadius = 32.0;
}

// ==========================================
// MODELS
// ==========================================
enum UserRole { student, supervisor, admin }

enum UserStatus { active, suspended, onLeave }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  UserStatus status;
  final String avatarUrl;

  // Student specific
  final String? regNo;
  String? supervisorName;

  // Supervisor specific
  final int? assignedStudentsCount;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.avatarUrl,
    this.regNo,
    this.supervisorName,
    this.assignedStudentsCount,
  });

  Color get statusColor {
    switch (status) {
      case UserStatus.active:
        return _C.green;
      case UserStatus.suspended:
        return _C.red;
      case UserStatus.onLeave:
        return _C.orange;
    }
  }

  String get statusText {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.onLeave:
        return 'On Leave';
    }
  }
}

// ==========================================
// MAIN SCREEN
// ==========================================
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _searchQuery = '';

  // Sub-screen State tracking (Simulated Pages without GoRouter)
  // 'list' -> Main listing
  // 'add' -> Add User Screen
  // 'edit' -> Edit User Screen
  // 'profile' -> User Profile Screen
  String _currentView = 'list';
  String? _targetUserId;

  // Filters
  String _studentFilter = 'All';
  String _supervisorFilter = 'All';
  String _adminFilter = 'All';

  // State Data
  List<AppUser> _users = [];
  final Set<String> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedStudentIds.clear(); // Clear selections when changing tabs
      });
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/admin/users');

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['users'];
        final fetchedUsers = usersData.map((u) {
          UserRole parsedRole;
          switch (u['role']) {
            case 'STUDENT':
              parsedRole = UserRole.student;
              break;
            case 'SUPERVISOR':
              parsedRole = UserRole.supervisor;
              break;
            default:
              parsedRole = UserRole.admin;
          }

          UserStatus parsedStatus;
          switch (u['status']) {
            case 'SUSPENDED':
              parsedStatus = UserStatus.suspended;
              break;
            case 'ON_LEAVE':
              parsedStatus = UserStatus.onLeave;
              break;
            default:
              parsedStatus = UserStatus.active;
          }

          return AppUser(
            id: u['id'],
            name: u['name'],
            email: u['email'],
            role: parsedRole,
            department: u['department'] ?? '-',
            status: parsedStatus,
            avatarUrl: u['avatarUrl'] ?? '',
            regNo: u['regNo'],
            supervisorName: u['supervisorName'],
            assignedStudentsCount: u['assignedStudentsCount'],
          );
        }).toList();

        if (mounted) {
          setState(() {
            _users = fetchedUsers;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) ToastService.showError('Failed to fetch users');
      }
    } catch (e) {
      if (mounted) ToastService.showError('Error fetching users: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Getters for filtered lists
  List<AppUser> _getFilteredUsers(UserRole role, String filter) {
    var list = _users.where((u) => u.role == role).toList();

    // Global Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                (u.regNo?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Pill Filters
    if (filter != 'All') {
      if (filter == 'Active')
        list = list.where((u) => u.status == UserStatus.active).toList();
      if (filter == 'Suspended')
        list = list.where((u) => u.status == UserStatus.suspended).toList();
      if (filter == 'On Leave')
        list = list.where((u) => u.status == UserStatus.onLeave).toList();
      if (filter == 'Unassigned' && role == UserRole.student)
        list = list.where((u) => u.supervisorName == null).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == 'add') {
      return _EmbeddedAddUserWidget(
        onBack: () {
          setState(() => _currentView = 'list');
          _fetchUsers();
        },
      );
    }
    if (_currentView == 'edit' && _targetUserId != null) {
      return _EmbeddedEditUserWidget(
        userId: _targetUserId!,
        onBack: () {
          setState(() => _currentView = 'list');
          _fetchUsers();
        },
      );
    }
    if (_currentView == 'profile' && _targetUserId != null) {
      return _EmbeddedUserProfileWidget(
        userId: _targetUserId!,
        onBack: () {
          setState(() => _currentView = 'list');
          _fetchUsers();
        },
        onEdit: (uid) {
          setState(() {
            _targetUserId = uid;
            _currentView = 'edit';
          });
        },
      );
    }

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 32),

              if (_isLoading)
                Expanded(child: _buildMainContentSkeleton())
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_C.cardRadius),
                      border: Border.all(color: _C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTabHeaderAndActions(),
                        const Divider(height: 1, color: _C.border),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildStudentsTab(),
                              _buildSupervisorsTab(),
                              _buildAdminsTab(),
                            ],
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
    );
  }

  // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'User Management',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage students, supervisors, and administrators',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: _C.textMuted,
              ),
            ),
          ],
        );

        final searchAndAdd = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isNarrow ? double.infinity : 320,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.magnifyingGlass(),
                    color: _C.textFaint,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.textFaint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentView = 'add';
                });
              },
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'Add User',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        );

        if (isNarrow)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 20), searchAndAdd],
          );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            searchAndAdd,
          ],
        );
      },
    );
  }

  // â”€â”€ TAB HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTabHeaderAndActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: _C.green,
            unselectedLabelColor: _C.textMuted,
            indicatorColor: _C.green,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Supervisors'),
              Tab(text: 'Administrators'),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(
              PhosphorIcons.downloadSimple(),
              size: 18,
              color: _C.textDark,
            ),
            label: const Text(
              'Export',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _C.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ TAB: STUDENTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStudentsTab() {
    final students = _getFilteredUsers(UserRole.student, _studentFilter);
    final allSelected =
        students.isNotEmpty && _selectedStudentIds.length == students.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter & Bulk Actions Row
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildFilterPill(
                    'All',
                    _studentFilter == 'All',
                    () => setState(() => _studentFilter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    'Active',
                    _studentFilter == 'Active',
                    () => setState(() => _studentFilter = 'Active'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    'Unassigned',
                    _studentFilter == 'Unassigned',
                    () => setState(() => _studentFilter = 'Unassigned'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    'Suspended',
                    _studentFilter == 'Suspended',
                    () => setState(() => _studentFilter = 'Suspended'),
                  ),
                ],
              ),
              if (_selectedStudentIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAssignSupervisorModal(),
                  icon: const Icon(
                    Icons.group_add_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Assign Supervisor (${_selectedStudentIds.length})',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: _C.border),

        // Table Wrapper
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = max(constraints.maxWidth, 1000.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableWidth,
                    maxWidth: tableWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Container(
                        color: _C.bg.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: allSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentIds.addAll(
                                        students.map((e) => e.id),
                                      );
                                    } else {
                                      _selectedStudentIds.clear();
                                    }
                                  });
                                },
                                activeColor: _C.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _tableHeader('Student Name'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Reg Number'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Department'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Supervisor'),
                            ),
                            Expanded(flex: 1, child: _tableHeader('Status')),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _C.border),

                      // Body
                      if (students.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "No students found",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: _C.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _C.border),
                            itemBuilder: (context, index) {
                              final s = students[index];
                              final isSelected = _selectedStudentIds.contains(
                                s.id,
                              );
                              return InkWell(
                                onTap: () => _showRowActionsModal(s),
                                child: Container(
                                  color: isSelected
                                      ? _C.greenLight.withOpacity(0.3)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true)
                                                _selectedStudentIds.add(s.id);
                                              else
                                                _selectedStudentIds.remove(
                                                  s.id,
                                                );
                                            });
                                          },
                                          activeColor: _C.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            _buildAvatarCircle(s.avatarUrl, 36),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: _C.textDark,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    s.email,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 12,
                                                      color: _C.textFaint,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.regNo ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: _C.textMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.department,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: _C.textMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.supervisorName ?? 'Not Assigned',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: s.supervisorName == null
                                                ? _C.orange
                                                : _C.textMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildStatusBadge(s),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: Icon(
                                            PhosphorIcons.dotsThreeVertical(),
                                            color: _C.textMuted,
                                          ),
                                          onPressed: () =>
                                              _showRowActionsModal(s),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // â”€â”€ TAB: SUPERVISORS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSupervisorsTab() {
    final supervisors = _getFilteredUsers(
      UserRole.supervisor,
      _supervisorFilter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              _buildFilterPill(
                'All',
                _supervisorFilter == 'All',
                () => setState(() => _supervisorFilter = 'All'),
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'Active',
                _supervisorFilter == 'Active',
                () => setState(() => _supervisorFilter = 'Active'),
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'On Leave',
                _supervisorFilter == 'On Leave',
                () => setState(() => _supervisorFilter = 'On Leave'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _C.border),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = max(constraints.maxWidth, 900.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableWidth,
                    maxWidth: tableWidth,
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: _C.bg.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _tableHeader('Supervisor Name'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Department'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Assigned Students'),
                            ),
                            Expanded(flex: 1, child: _tableHeader('Status')),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _C.border),
                      if (supervisors.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "No supervisors found",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: _C.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: supervisors.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _C.border),
                            itemBuilder: (context, index) {
                              final s = supervisors[index];
                              return InkWell(
                                onTap: () => _showRowActionsModal(s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            _buildAvatarCircle(s.avatarUrl, 36),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: _C.textDark,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    s.email,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 12,
                                                      color: _C.textFaint,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.department,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: _C.textMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${s.assignedStudentsCount ?? 0}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _C.textDark,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildStatusBadge(s),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: Icon(
                                            PhosphorIcons.dotsThreeVertical(),
                                            color: _C.textMuted,
                                          ),
                                          onPressed: () =>
                                              _showRowActionsModal(s),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // â”€â”€ TAB: ADMINS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAdminsTab() {
    final admins = _getFilteredUsers(UserRole.admin, _adminFilter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              _buildFilterPill(
                'All',
                _adminFilter == 'All',
                () => setState(() => _adminFilter = 'All'),
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'Active',
                _adminFilter == 'Active',
                () => setState(() => _adminFilter = 'Active'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _C.border),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = max(constraints.maxWidth, 800.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableWidth,
                    maxWidth: tableWidth,
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: _C.bg.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _tableHeader('Administrator'),
                            ),
                            Expanded(
                              flex: 2,
                              child: _tableHeader('Department'),
                            ),
                            Expanded(flex: 1, child: _tableHeader('Status')),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _C.border),
                      if (admins.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "No admins found",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: _C.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: admins.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _C.border),
                            itemBuilder: (context, index) {
                              final s = admins[index];
                              return InkWell(
                                onTap: () => _showRowActionsModal(s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            _buildAvatarCircle(s.avatarUrl, 36),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: _C.textDark,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    s.email,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 12,
                                                      color: _C.textFaint,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.department,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: _C.textMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildStatusBadge(s),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: Icon(
                                            PhosphorIcons.dotsThreeVertical(),
                                            color: _C.textMuted,
                                          ),
                                          onPressed: () =>
                                              _showRowActionsModal(s),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // â”€â”€ HELPER WIDGETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _C.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _C.green : _C.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _C.green : _C.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _C.textFaint,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAvatarCircle(String avatarUrl, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: AppAvatar(
        imagePath: avatarUrl,
        size: size,
        shape: AvatarShape.circle,
        initials: null,
      ),
    );
  }

  Widget _buildStatusBadge(AppUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: user.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.statusText,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: user.statusColor,
        ),
      ),
    );
  }

  // â”€â”€ SKELETON LOADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMainContentSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: const [
                _SkeletonBox(width: 100, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                _SkeletonBox(width: 100, height: 32, borderRadius: 20),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (c, i) => Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: const [
                    _SkeletonBox(width: 36, height: 36, borderRadius: 18),
                    SizedBox(width: 16),
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 20,
                        borderRadius: 4,
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 20,
                        borderRadius: 4,
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 20,
                        borderRadius: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ MODALS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String? _assignSupervisorSelectedId;
  bool _isAssigning = false;

  void _showAssignSupervisorModal({String? singleStudentId}) {
    final supervisors = _users
        .where((u) => u.role == UserRole.supervisor)
        .toList();
    _assignSupervisorSelectedId = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final count = singleStudentId != null
              ? 1
              : _selectedStudentIds.length;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _C.greenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            PhosphorIcons.userSwitch(),
                            color: _C.green,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assign Supervisor',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textDark,
                                ),
                              ),
                              Text(
                                'Assigning $count student(s) to a supervisor.',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: _C.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: _C.border),
                    const SizedBox(height: 20),

                    // Supervisor Dropdown
                    const Text(
                      'Select Supervisor',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _assignSupervisorSelectedId,
                          hint: const Text(
                            'Choose a supervisor...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: _C.textFaint,
                              fontSize: 14,
                            ),
                          ),
                          isExpanded: true,
                          icon: Icon(
                            PhosphorIcons.caretDown(),
                            color: _C.textMuted,
                            size: 16,
                          ),
                          items: supervisors.isEmpty
                              ? [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'No supervisors available',
                                      style: TextStyle(color: _C.textMuted),
                                    ),
                                  ),
                                ]
                              : supervisors
                                    .map(
                                      (sup) => DropdownMenuItem(
                                        value: sup.id,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _C.greenLight,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  sup.name[0],
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: _C.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    sup.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _C.textDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    sup.department,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 11,
                                                      color: _C.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (v) => setModalState(
                            () => _assignSupervisorSelectedId = v,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isAssigning
                              ? null
                              : () => Navigator.pop(ctx),
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
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: _C.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed:
                              (_isAssigning ||
                                  _assignSupervisorSelectedId == null)
                              ? null
                              : () async {
                                  setModalState(() => _isAssigning = true);
                                  try {
                                    final apiClient = ApiClient();
                                    final targets = singleStudentId != null
                                        ? [singleStudentId]
                                        : _selectedStudentIds.toList();
                                    bool allOk = true;
                                    for (final studentUserId in targets) {
                                      final resp = await apiClient.dio.patch(
                                        '/admin/users/$studentUserId/supervisor',
                                        data: {
                                          'supervisorId':
                                              _assignSupervisorSelectedId,
                                        },
                                      );
                                      if (resp.statusCode != 200) allOk = false;
                                    }
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      setState(
                                        () => _selectedStudentIds.clear(),
                                      );
                                      _fetchUsers(); // Refresh list
                                      ToastService.showSuccess(
                                        allOk
                                            ? 'Supervisor assigned successfully'
                                            : 'Some assignments failed',
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted)
                                      ToastService.showError(
                                        'Failed to assign supervisor',
                                      );
                                  } finally {
                                    if (mounted)
                                      setModalState(() => _isAssigning = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isAssigning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Assign',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
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

  void _showRowActionsModal(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Identity Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.green.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _C.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _C.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(user),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _C.border),
                const SizedBox(height: 8),

                // Actions
                _buildActionTile(PhosphorIcons.eye(), 'View Profile', () {
                  Navigator.pop(ctx);
                  setState(() {
                    _targetUserId = user.id;
                    _currentView = 'profile';
                  });
                }),
                _buildActionTile(
                  PhosphorIcons.pencilSimple(),
                  'Edit Details',
                  () {
                    Navigator.pop(ctx);
                    setState(() {
                      _targetUserId = user.id;
                      _currentView = 'edit';
                    });
                  },
                ),

                // Show Assign Supervisor for students only
                if (user.role == UserRole.student)
                  _buildActionTile(
                    PhosphorIcons.userSwitch(),
                    user.supervisorName == null
                        ? 'Assign Supervisor'
                        : 'Reassign Supervisor',
                    () {
                      Navigator.pop(ctx);
                      _showAssignSupervisorModal(singleStudentId: user.id);
                    },
                  ),

                if (user.status == UserStatus.active)
                  _buildActionTile(
                    PhosphorIcons.pauseCircle(),
                    'Suspend User',
                    () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiClient().dio.patch(
                          '/admin/users/${user.id}/status',
                          data: {'status': 'SUSPENDED'},
                        );
                        _fetchUsers();
                        if (mounted)
                          ToastService.showSuccess(
                            '${user.name} has been suspended',
                          );
                      } catch (_) {
                        if (mounted)
                          ToastService.showError('Failed to suspend user');
                      }
                    },
                    isDanger: true,
                  )
                else
                  _buildActionTile(
                    PhosphorIcons.playCircle(),
                    'Activate User',
                    () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiClient().dio.patch(
                          '/admin/users/${user.id}/status',
                          data: {'status': 'ACTIVE'},
                        );
                        _fetchUsers();
                        if (mounted)
                          ToastService.showSuccess(
                            '${user.name} has been reactivated',
                          );
                      } catch (_) {
                        if (mounted)
                          ToastService.showError('Failed to activate user');
                      }
                    },
                  ),

                _buildActionTile(
                  PhosphorIcons.trash(),
                  'Archive User',
                  () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiClient().dio.delete('/admin/users/${user.id}');
                      _fetchUsers();
                      if (mounted)
                        ToastService.showSuccess(
                          '${user.name} has been archived',
                        );
                    } catch (_) {
                      if (mounted)
                        ToastService.showError('Failed to archive user');
                    }
                  },
                  isDanger: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? _C.red : _C.textDark),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: isDanger ? _C.red : _C.textDark,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ==========================================
// EMBEDDED SUB-WIDGET: ADD USER
// ==========================================
class _EmbeddedAddUserWidget extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _EmbeddedAddUserWidget({required this.onBack});

  @override
  ConsumerState<_EmbeddedAddUserWidget> createState() =>
      _EmbeddedAddUserWidgetState();
}

class _EmbeddedAddUserWidgetState
    extends ConsumerState<_EmbeddedAddUserWidget> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regStaffController = TextEditingController();

  // Extra fields
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programmeController = TextEditingController();
  final _topicController = TextEditingController();

  final _officeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _capacityController = TextEditingController();

  List<Map<String, dynamic>> _availableSupervisors = [];
  String? _selectedSupervisorId;
  String _selectedRole = 'Student';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    try {
      final response = await ApiClient().dio.get('/admin/users');
      if (response.statusCode == 200) {
        final users = response.data['users'] as List<dynamic>;
        final supervisors = users
            .where((u) => u['role'] == 'SUPERVISOR')
            .toList();
        if (mounted) {
          setState(() {
            _availableSupervisors = supervisors
                .map((s) => {'id': s['id'], 'name': s['name']})
                .toList();
          });
        }
      }
    } catch (e) {
      // Silently fail or log
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regStaffController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _facultyController.dispose();
    _programmeController.dispose();
    _topicController.dispose();
    _officeController.dispose();
    _specializationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final regStaff = _regStaffController.text.trim();

    if (name.isEmpty || email.isEmpty || regStaff.isEmpty) {
      ToastService.showError(
        'Please fill required fields (Name, Email, Number)',
      );
      return;
    }

    if (_selectedRole == 'Admin') {
      ToastService.showError('Admin creation not supported yet');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parts = name.split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'User';

      final endpoint = _selectedRole == 'Student'
          ? '/admin/users/students'
          : '/admin/users/supervisors';

      final body = _selectedRole == 'Student'
          ? {
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'registrationNo': regStaff,
              'phone': _phoneController.text.trim(),
              'programme': _programmeController.text.trim(),
              'department': _departmentController.text.trim(),
              'faculty': _facultyController.text.trim(),
              'researchTopic': _topicController.text.trim(),
              if (_selectedSupervisorId != null)
                'supervisorId': _selectedSupervisorId,
            }
          : {
              'fullName': name,
              'email': email,
              'staffNumber': regStaff,
              'phone': _phoneController.text.trim(),
              'department': _departmentController.text.trim(),
              'faculty': _facultyController.text.trim(),
              'office': _officeController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'studentCapacity':
                  int.tryParse(_capacityController.text.trim()) ?? 20,
            };

      final apiClient = ApiClient();
      final response = await apiClient.dio.post(endpoint, data: body);

      if (response.statusCode == 201) {
        ToastService.showSuccess('$_selectedRole created successfully');
        final tempPassword = response.data['tempPassword'] as String;

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'User Created',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SelectableText(
                'The user was created successfully.\n\nTemporary Password:\n$tempPassword\n\nPlease copy this password and share it with the user securely. They will be forced to change it on their first login.',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'I copied it, Done',
                    style: TextStyle(
                      color: _C.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          widget.onBack();
        }
      } else {
        ToastService.showError(
          response.data?['error'] ?? 'Failed to create user',
        );
      }
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ??
          'Failed to create user (Status ${e.response?.statusCode})';
      ToastService.showError(errorMsg);
    } catch (e) {
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.textDark,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: _C.textFaint,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.green),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: _C.textMuted,
                size: 16,
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 14,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Supervisor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Text(
                'Select a supervisor (Optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textFaint,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: const Icon(
                PhosphorIconsRegular.caretDown,
                color: _C.textMuted,
                size: 16,
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 14,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._availableSupervisors.map(
                  (s) => DropdownMenuItem<String>(
                    value: s['id'],
                    child: Text(s['name']),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedSupervisorId = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.arrowLeft,
                        color: _C.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _C.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(40),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Full Name',
                                'e.g. John Doe',
                                _nameController,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                'Email Address',
                                'e.g. john@fieldtrack.edu',
                                _emailController,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField('Role', [
                                'Student',
                                'Supervisor',
                                'Admin',
                              ]),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                _selectedRole == 'Student'
                                    ? 'Reg Number'
                                    : 'Employee Number',
                                'Required',
                                _regStaffController,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          'Phone Number',
                          'e.g. +254 700 000000',
                          _phoneController,
                        ),

                        const SizedBox(height: 48),
                        const Divider(color: _C.border),
                        const SizedBox(height: 32),

                        Text(
                          '${_selectedRole} Details',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Faculty',
                                'e.g. Science',
                                _facultyController,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                'Department',
                                'e.g. Computer Science',
                                _departmentController,
                              ),
                            ),
                          ],
                        ),

                        if (_selectedRole == 'Student') ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Programme',
                                  'e.g. BSc Computer Science',
                                  _programmeController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTextField(
                                  'Research Topic',
                                  'Optional',
                                  _topicController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSupervisorDropdown(),
                        ],

                        if (_selectedRole == 'Supervisor') ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Office',
                                  'e.g. Room 402',
                                  _officeController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTextField(
                                  'Max Student Capacity',
                                  'e.g. 20',
                                  _capacityController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            'Specialization',
                            'e.g. AI, Machine Learning',
                            _specializationController,
                          ),
                        ],

                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isLoading ? null : widget.onBack,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: const BorderSide(color: _C.border),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: _C.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// EMBEDDED SUB-WIDGET: EDIT USER
// ==========================================
class _EmbeddedEditUserWidget extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onBack;
  const _EmbeddedEditUserWidget({required this.userId, required this.onBack});

  @override
  ConsumerState<_EmbeddedEditUserWidget> createState() =>
      _EmbeddedEditUserWidgetState();
}

class _EmbeddedEditUserWidgetState
    extends ConsumerState<_EmbeddedEditUserWidget> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regStaffController = TextEditingController();

  // Extra fields
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programmeController = TextEditingController();
  final _topicController = TextEditingController();

  final _officeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _capacityController = TextEditingController();

  List<Map<String, dynamic>> _availableSupervisors = [];
  String? _selectedSupervisorId;
  String _selectedRole = 'Student';
  String _selectedStatus = 'ACTIVE';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ApiClient();

      final usersResponse = await apiClient.dio.get('/admin/users');
      if (usersResponse.statusCode == 200) {
        final users = usersResponse.data['users'] as List<dynamic>;
        final supervisors = users
            .where((u) => u['role'] == 'SUPERVISOR')
            .toList();
        _availableSupervisors = supervisors
            .map((s) => {'id': s['id'], 'name': s['name']})
            .toList();
      }

      final userResponse = await apiClient.dio.get(
        '/admin/users/${widget.userId}',
      );
      if (userResponse.statusCode == 200) {
        final user = userResponse.data['user'];
        _selectedRole = user['role'] == 'STUDENT'
            ? 'Student'
            : (user['role'] == 'SUPERVISOR' ? 'Supervisor' : 'Admin');
        _selectedStatus = user['status'];
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';

        if (user['role'] == 'STUDENT' && user['studentProfile'] != null) {
          final p = user['studentProfile'];
          _regStaffController.text = p['registrationNo'] ?? '';
          _phoneController.text = p['phone'] ?? '';
          _departmentController.text = p['department'] ?? '';
          _facultyController.text = p['faculty'] ?? '';
          _programmeController.text = p['programme'] ?? '';
          _topicController.text = p['topic'] ?? '';
          _selectedSupervisorId = p['supervisorId'];
        } else if (user['role'] == 'SUPERVISOR' &&
            user['supervisorProfile'] != null) {
          final p = user['supervisorProfile'];
          _regStaffController.text = p['staffNumber'] ?? '';
          _phoneController.text = p['phone'] ?? '';
          _departmentController.text = p['department'] ?? '';
          _facultyController.text = p['faculty'] ?? '';
          _officeController.text = p['office'] ?? '';
          _specializationController.text = p['specialization'] ?? '';
          _capacityController.text = p['studentCapacity']?.toString() ?? '20';
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to load user data');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regStaffController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _facultyController.dispose();
    _programmeController.dispose();
    _topicController.dispose();
    _officeController.dispose();
    _specializationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ToastService.showError('Please fill required fields (Name)');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'name': name,
        'status': _selectedStatus,
        'phone': _phoneController.text.trim(),
        'programme': _programmeController.text.trim(),
        'department': _departmentController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'topic': _topicController.text.trim(),
        'supervisorId': _selectedSupervisorId,
        'studentCapacity': _capacityController.text.trim(),
      };

      final apiClient = ApiClient();
      final response = await apiClient.dio.put(
        '/admin/users/${widget.userId}',
        data: body,
      );

      if (response.statusCode == 200) {
        ToastService.showSuccess('User updated successfully');
        widget.onBack();
      } else {
        ToastService.showError(
          response.data?['error'] ?? 'Failed to update user',
        );
      }
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ??
          'Failed to update user (Status ${e.response?.statusCode})';
      ToastService.showError(errorMsg);
    } catch (e) {
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.textDark,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              if (readOnly)
                const TextSpan(
                  text: ' (Restricted)',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: readOnly ? _C.textMuted : _C.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: _C.textFaint,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: readOnly ? _C.border : _C.green),
            ),
            filled: true,
            fillColor: readOnly ? _C.border.withOpacity(0.3) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String currentValue,
    Function(String) onChanged, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.textDark,
            ),
            children: [
              if (readOnly)
                const TextSpan(
                  text: ' (Restricted)',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? _C.border.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: readOnly ? Colors.transparent : _C.textMuted,
                size: 16,
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: readOnly ? _C.textMuted : _C.textDark,
                fontSize: 14,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: readOnly
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDropdown() {
    // If the currently selected supervisor ID is not in the available list and is not null,
    // we need to dynamically add a fallback option to prevent DropdownButton from throwing an assertion error.
    final hasSelected =
        _selectedSupervisorId == null ||
        _availableSupervisors.any((s) => s['id'] == _selectedSupervisorId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Supervisor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Text(
                'Select a supervisor (Optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textFaint,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: _C.textMuted,
                size: 16,
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 14,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                if (!hasSelected && _selectedSupervisorId != null)
                  DropdownMenuItem<String>(
                    value: _selectedSupervisorId,
                    child: Text('Assigned Supervisor ($_selectedSupervisorId)'),
                  ),
                ..._availableSupervisors.map(
                  (s) => DropdownMenuItem<String>(
                    value: s['id'],
                    child: Text(s['name']),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedSupervisorId = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _C.green))
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        InkWell(
                          onTap: widget.onBack,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.arrowLeft,
                              color: _C.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          'Edit User',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _C.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main Content
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(40),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Information',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Full Name',
                                      'e.g. John Doe',
                                      _nameController,
                                      isRequired: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      'Email Address',
                                      'e.g. john@fieldtrack.edu',
                                      _emailController,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Role',
                                      ['Student', 'Supervisor', 'Admin'],
                                      _selectedRole,
                                      (v) {},
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      _selectedRole == 'Student'
                                          ? 'Reg Number'
                                          : 'Employee Number',
                                      'Required',
                                      _regStaffController,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Phone Number',
                                      'e.g. +254 700 000000',
                                      _phoneController,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Status',
                                      [
                                        'ACTIVE',
                                        'PENDING',
                                        'DISABLED',
                                        'SUSPENDED',
                                        'LOCKED',
                                        'ARCHIVED',
                                      ],
                                      _selectedStatus,
                                      (v) =>
                                          setState(() => _selectedStatus = v),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),
                              const Divider(color: _C.border),
                              const SizedBox(height: 32),

                              Text(
                                '${_selectedRole} Details',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Faculty',
                                      'e.g. Science',
                                      _facultyController,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      'Department',
                                      'e.g. Computer Science',
                                      _departmentController,
                                    ),
                                  ),
                                ],
                              ),

                              if (_selectedRole == 'Student') ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Programme',
                                        'e.g. BSc Computer Science',
                                        _programmeController,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        'Research Topic',
                                        'Optional',
                                        _topicController,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildSupervisorDropdown(),
                              ],

                              if (_selectedRole == 'Supervisor') ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Office',
                                        'e.g. Room 402',
                                        _officeController,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        'Max Student Capacity',
                                        'e.g. 20',
                                        _capacityController,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  'Specialization',
                                  'e.g. AI, Machine Learning',
                                  _specializationController,
                                ),
                              ],

                              const SizedBox(height: 48),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: _isSaving ? null : widget.onBack,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: const BorderSide(color: _C.border),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: _C.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _C.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ==========================================
// EMBEDDED SUB-WIDGET: USER PROFILE
// ==========================================
class _EmbeddedUserProfileWidget extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) onEdit;
  const _EmbeddedUserProfileWidget({
    required this.userId,
    required this.onBack,
    required this.onEdit,
  });

  @override
  ConsumerState<_EmbeddedUserProfileWidget> createState() =>
      _EmbeddedUserProfileWidgetState();
}

class _EmbeddedUserProfileWidgetState
    extends ConsumerState<_EmbeddedUserProfileWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/admin/users/${widget.userId}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _user = response.data['user'];
            _auditLogs = _user?['auditLogs'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to load user profile');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset Password',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to reset this user\'s password?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _C.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        '/admin/users/${widget.userId}/reset-password',
      );
      if (response.statusCode == 200) {
        final tempPassword = response.data['tempPassword'];
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                'Password Reset Successful',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The user\'s password has been reset. Please share this temporary password with them securely:',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: Center(
                      child: SelectableText(
                        tempPassword,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: _C.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
          _fetchData();
        }
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to reset password');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.patch(
        '/admin/users/${widget.userId}/status',
        data: {'status': newStatus},
      );
      if (response.statusCode == 200) {
        ToastService.showSuccess('Status updated to $newStatus');
        _fetchData();
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to update status');
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Archive User',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to archive this user? They will no longer be able to log in, but their data will be preserved.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _C.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Archive',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.delete(
        '/admin/users/${widget.userId}',
      );
      if (response.statusCode == 200) {
        ToastService.showSuccess('User archived successfully');
        widget.onBack();
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to archive user');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'SUSPENDED':
        return Colors.red;
      case 'DISABLED':
        return Colors.grey;
      case 'LOCKED':
        return Colors.deepPurple;
      case 'ARCHIVED':
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogList() {
    if (_auditLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No audit logs available for this user.',
            style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _auditLogs.length,
      separatorBuilder: (context, index) => const Divider(color: _C.border),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final date = DateTime.parse(log['timestamp']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.listBullets(),
                  color: _C.textMuted,
                  size: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: _C.textDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log['details']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy HH:mm').format(date),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _C.bg,
        child: const Center(child: CircularProgressIndicator(color: _C.green)),
      );
    }

    if (_user == null) {
      return Container(
        color: _C.bg,
        child: const Center(child: Text('User not found')),
      );
    }

    final String role = _user!['role'];
    final Map<String, dynamic>? profile = role == 'STUDENT'
        ? _user!['studentProfile']
        : (role == 'SUPERVISOR' ? _user!['supervisorProfile'] : null);

    String regOrStaffNo = '-';
    if (role == 'STUDENT' && profile != null)
      regOrStaffNo = profile['registrationNo'] ?? '-';
    if (role == 'SUPERVISOR' && profile != null)
      regOrStaffNo = profile['staffNumber'] ?? '-';

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.arrowLeft,
                            color: _C.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _C.textDark,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => widget.onEdit(widget.userId),
                        icon: Icon(PhosphorIcons.pencilSimple(), size: 18),
                        label: const Text('Edit Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.textDark,
                          side: const BorderSide(color: _C.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reset')
                            _resetPassword();
                          else if (value == 'delete')
                            _deleteUser();
                          else
                            _updateStatus(value);
                        },
                        itemBuilder: (context) => [
                          if (_user!['status'] != 'SUSPENDED')
                            const PopupMenuItem(
                              value: 'SUSPENDED',
                              child: Text(
                                'Suspend User',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          if (_user!['status'] == 'SUSPENDED')
                            const PopupMenuItem(
                              value: 'ACTIVE',
                              child: Text(
                                'Reactivate User',
                                style: TextStyle(color: _C.green),
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Text('Reset Password'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Archive User',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          child: Icon(
                            PhosphorIcons.dotsThreeVertical(),
                            color: _C.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Details)
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // User Summary Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _C.border),
                              ),
                              padding: const EdgeInsets.all(32),
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: _C.green.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      _user!['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: _C.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _user!['name'],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: _C.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _user!['email'],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: _C.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _C.bg,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                role,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _C.textDark,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  _user!['status'],
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _user!['status'],
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(
                                                    _user!['status'],
                                                  ),
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
                            ),

                            // Specific Details
                            _buildInfoCard('Account Information', [
                              _buildInfoRow('Identifier', regOrStaffNo),
                              _buildInfoRow(
                                'Phone Number',
                                profile?['phone'] ?? '-',
                              ),
                              _buildInfoRow(
                                'Department',
                                profile?['department'] ?? '-',
                              ),
                              _buildInfoRow(
                                'Faculty',
                                profile?['faculty'] ?? '-',
                              ),
                              if (role == 'STUDENT')
                                _buildInfoRow(
                                  'Programme',
                                  profile?['programme'] ?? '-',
                                ),
                              if (role == 'STUDENT')
                                _buildInfoRow(
                                  'Research Topic',
                                  profile?['topic'] ?? '-',
                                ),
                              if (role == 'SUPERVISOR')
                                _buildInfoRow(
                                  'Office',
                                  profile?['office'] ?? '-',
                                ),
                              if (role == 'SUPERVISOR')
                                _buildInfoRow(
                                  'Specialization',
                                  profile?['specialization'] ?? '-',
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Activity & Audit)
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _C.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Audit & Activity Log',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                ),
                              ),
                            ),
                            const Divider(color: _C.border, height: 1),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _buildAuditLogList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
