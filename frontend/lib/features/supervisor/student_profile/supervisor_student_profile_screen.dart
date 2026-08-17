import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/location_naming_service.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/features/supervisor/field_logs/supervisor_daily_field_logs_screen.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/features/supervisor/repositories/student_repository.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF0F2F5);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius =
      32.0; // Increased to match the highly rounded/pill look
}

class SupervisorStudentProfileScreen extends StatefulWidget {
  final String studentId;
  const SupervisorStudentProfileScreen({super.key, required this.studentId});

  @override
  State<SupervisorStudentProfileScreen> createState() =>
      _SupervisorStudentProfileScreenState();
}

class _SupervisorStudentProfileScreenState
    extends State<SupervisorStudentProfileScreen> {
  int _activeTabIndex = 0;
  StudentData? _student;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudent();
  }

  Future<void> _fetchStudent() async {
    try {
      final repo = StudentRepository(api: ApiClient());
      final student = await repo.fetchStudentById(widget.studentId);
      if (mounted) {
        setState(() {
          _student = student;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getFriendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String get _studentStatus {
    final raw = _student?.fieldStatus.name ?? '';
    if (raw.isEmpty) return 'Offline';

    final formatted = raw
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();

    return formatted.isEmpty
        ? 'Offline'
        : '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  Color get _studentStatusColor {
    switch (_student?.fieldStatus) {
      case FieldStatus.inField:
        return _C.green;
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _C.bg,
        child: const Center(child: CircularProgressIndicator(color: _C.green)),
      );
    }
    if (_error != null) {
      return Container(
        color: _C.bg,
        child: Center(
          child: Text(
            'Failed to load student: $_error',
            style: const TextStyle(color: _C.textMuted, fontFamily: 'Poppins'),
          ),
        ),
      );
    }
    final bool isOverview = _activeTabIndex == 0;
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 800;
            
            final children = [
              // Only show header + profile card on the Overview tab
              if (isOverview) ...[
                _buildHeader(context, isMobile: isMobile),
                SizedBox(height: isMobile ? 16 : 24),
                _buildProfileCard(isMobile: isMobile),
                SizedBox(height: isMobile ? 16 : 32),
              ],
              _buildTabs(),
              SizedBox(height: isMobile ? 16 : 32),
              
              if (isMobile)
                _buildTabContent(isMobile: isMobile)
              else
                Expanded(child: _buildTabContent(isMobile: isMobile)),
            ];

            return Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent({required bool isMobile}) {
    if (_activeTabIndex == 0) return _buildOverviewTab(isMobile: isMobile);
    if (_activeTabIndex == 1) {
      return SupervisorDailyFieldLogsScreen(
        studentId: widget.studentId,
        embedded: true,
      );
    }
    return const SizedBox.shrink();
  }

  // ── 1. HEADER (Title & Breadcrumbs) ───────────────────────────────────
  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.black, size: 28),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/supervisor/students');
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        // Wrap in Expanded to prevent overflow on smaller screens
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Profile Overview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
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
                  Text(
                    _student?.name ?? 'Loading...',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _C.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Actions Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40), // Pill shape
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: const [
              Text(
                'Actions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textMuted,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                PhosphorIconsRegular.caretDown,
                size: 16,
                color: _C.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. TOP PROFILE CARD ───────────────────────────────────────────────
  Widget _buildProfileCard({required bool isMobile}) {
    final avatarWidget = ClipOval(
              child:
                  _student?.avatarUrl != null && _student!.avatarUrl.isNotEmpty
                  ? Image.network(
                      ImageUtils.getFullImageUrl(_student!.avatarUrl),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: _C.border,
                        child: const Icon(
                          PhosphorIconsRegular.user,
                          color: _C.textMuted,
                          size: 40,
                        ),
                      ),
                    )
                  : Image.network(
                      'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=150&q=80',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: _C.border,
                        child: const Icon(
                          PhosphorIconsRegular.user,
                          color: _C.textMuted,
                          size: 40,
                        ),
                      ),
                    ),
    );

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _student?.name ?? 'Loading...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _studentStatusColor.withAlpha(
                  (0.15 * 255).round(),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _studentStatus,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _studentStatusColor,
                ),
              ),
            ),
          ],
        ),
        Text(
          _student != null && _student!.reg.isNotEmpty
              ? _student!.reg
              : 'Registration number not available',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              PhosphorIconsRegular.graduationCap,
              size: 16,
              color: _C.textDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _student != null && _student!.programme.isNotEmpty
                    ? _student!.programme
                    : 'Programme not provided',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              PhosphorIconsRegular.buildings,
              size: 16,
              color: _C.textDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _student != null &&
                        _student!.academicInfo.department.isNotEmpty
                    ? _student!.academicInfo.department
                    : 'Department not provided',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              PhosphorIconsRegular.mapPin,
              size: 16,
              color: _C.textDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _student != null &&
                        _student!.academicInfo.university.isNotEmpty
                    ? _student!.academicInfo.university
                    : 'Institution not provided',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

    final contactColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDetailRow(
          'Email',
          _student != null && _student!.personalInfo.email.isNotEmpty
              ? _student!.personalInfo.email
              : 'Email not provided',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Phone',
          _student != null && _student!.personalInfo.phone.isNotEmpty
              ? _student!.personalInfo.phone
              : 'Phone not provided',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Supervisor',
          _student != null &&
                  _student!.academicInfo.supervisorName.isNotEmpty
              ? _student!.academicInfo.supervisorName
              : 'Supervisor not assigned',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Research Topic',
          _student != null && _student!.topic.isNotEmpty
              ? _student!.topic
              : (_student != null &&
                        _student!
                            .academicInfo
                            .researchTopic
                            .isNotEmpty
                    ? _student!.academicInfo.researchTopic
                    : 'No research topic provided'),
          maxLines: 2,
        ),
      ],
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            avatarWidget,
            const SizedBox(height: 24),
            infoColumn,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: _C.border, height: 1),
            ),
            contactColumn,
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(90), // Pill/Highly rounded shape
        border: Border.all(color: _C.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 24),
            Expanded(flex: 5, child: infoColumn),
            Container(
              width: 1,
              color: _C.border,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(flex: 6, child: contactColumn),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110, // Fixed width for labels
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. PILL TABS ──────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabPill('Overview', 0),
        const SizedBox(width: 16),
        _buildTabPill('Field Logs', 1),
      ],
    );
  }

  Widget _buildTabPill(String title, int index) {
    final bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _C.green : Colors.white,
          borderRadius: BorderRadius.circular(40), // Perfectly round pill tab
          border: Border.all(color: isActive ? _C.green : Colors.transparent),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : _C.textMuted,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '${hr.toString().padLeft(2, '0')}:$min $ampm';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${_formatTime(dt)}, ${_formatDate(dt)}';
  }

  // ── 4. OVERVIEW TAB CONTENT (Fixed heights with Stretch) ──────────────
  Widget _buildOverviewTab({bool isMobile = false}) {
    final col1 = Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Statistics',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          Expanded(
            child: _buildStatPill(
              'Field Days',
              '${_student?.statistics.totalFieldDays ?? 0}',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStatPill(
              'Activities Submitted',
              '${_student?.statistics.totalActivities ?? 0}',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStatPill(
              'Evidence Files',
              '${_student?.statistics.totalEvidence ?? 0}',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStatPill(
              'Reports',
              '${_student?.statistics.totalReports ?? 0}',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStatPill(
              'First Check in',
              _formatDate(_student?.statistics.firstCheckIn),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStatPill(
              'Last Check Out',
              _formatDate(_student?.statistics.lastCheckOut),
            ),
          ),
        ],
      ),
    );

    final col2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Field Status',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          // This card expands strictly to remaining fixed height
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_C.cardRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_C.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFieldStatusItem(
                          PhosphorIconsRegular.target,
                          _student?.currentSession != null
                              ? 'Checked in'
                              : 'Offline',
                          _student?.currentSession != null
                              ? _formatDateTime(
                                  _student!.currentSession!.checkInTime,
                                )
                              : 'Not in field',
                          _student?.currentSession != null
                              ? _C.green
                              : _C.textMuted,
                        ),
                        _student?.currentSession != null
                            ? FutureBuilder<String>(
                                future: LocationNamingService().getLocationName(
                                  _student!.currentSession!.latitude,
                                  _student!.currentSession!.longitude,
                                ),
                                builder: (context, snapshot) {
                                  final loc = snapshot.data ?? 'Lat: ${_student!.currentSession!.latitude.toStringAsFixed(4)}, Lng: ${_student!.currentSession!.longitude.toStringAsFixed(4)}';
                                  return _buildFieldStatusItem(
                                    PhosphorIconsRegular.mapPin,
                                    'Location',
                                    loc,
                                    _C.textDark,
                                  );
                                },
                              )
                            : _buildFieldStatusItem(
                                PhosphorIconsRegular.mapPin,
                                'Location',
                                'N/A',
                                _C.textDark,
                              ),
                        _buildFieldStatusItem(
                          PhosphorIconsRegular.crosshair,
                          'Accuracy',
                          _student?.currentSession != null
                              ? '${_student!.currentSession!.accuracy.toStringAsFixed(1)} m'
                              : 'N/A',
                          _C.textDark,
                        ),
                        _buildFieldStatusItem(
                          PhosphorIconsRegular.clock,
                          'Time in Field',
                          _student?.currentSession != null
                              ? '${DateTime.now().difference(_student!.currentSession!.checkInTime).inHours}h ${DateTime.now().difference(_student!.currentSession!.checkInTime).inMinutes % 60}m'
                              : 'N/A',
                          _C.textDark,
                        ),
                        const SizedBox(
                          height: 60,
                        ), // Spacing for button overlay
                      ],
                    ),
                  ),

                  // Bottom Green Wave Background
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 160,
                    child: ClipPath(
                      clipper: _WaveClipper(),
                      child: Container(color: _C.greenLight),
                    ),
                  ),

                  // View Live Location Button
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/supervisor/student/${widget.studentId}/location');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.green,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ), // Pill button
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Live Location',
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
            ),
          ),
        ),
      ],
    );

    final col3 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

        // Timeline items
        if ((_student?.timeline ?? []).isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No recent activities',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textMuted,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: _student!.timeline.take(3).map((event) {
                final isLast = event == _student!.timeline.take(3).last;
                return Expanded(
                  child: _buildTimelineItem(
                    context,
                    title: event.title,
                    time: _formatTime(event.time),
                    status: event.type.name,
                    statusColor: event.type.name == 'activitySubmit'
                        ? _C.green
                        : _C.textMuted,
                    imgUrl: event.imageUrl != null
                        ? ImageUtils.getFullImageUrl(event.imageUrl!)
                        : 'https://images.unsplash.com/photo-1544257124-741165bc6f23?auto=format&fit=crop&w=150&q=80',
                    isLast: isLast,
                    activityId: event.type.name == 'activitySubmit'
                        ? event.activityId
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 48),
        OutlinedButton(
          onPressed: () {
            context.go('/supervisor/student/${widget.studentId}/logs');
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: _C.green),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ), // Pill shape
          ),
          child: const Text(
            'View all activities',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.green,
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 400, child: col1),
          const SizedBox(height: 32),
          SizedBox(height: 400, child: col2),
          const SizedBox(height: 32),
          SizedBox(height: 400, child: col3),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: col1),
        const SizedBox(width: 24),
        Expanded(child: col2),
        const SizedBox(width: 24),
        Expanded(child: col3),
      ],
    );
  }

  // Statistics pale-green Pill
  Widget _buildStatPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      decoration: BoxDecoration(
        color: _C.greenLight,
        borderRadius: BorderRadius.circular(40), // Pill shape for statistics
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: _C.textDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Field Status Icon + Text Row
  Widget _buildFieldStatusItem(
    IconData icon,
    String title,
    String subtitle,
    Color titleColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.greenLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _C.green, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Recent Activity Timeline Item
  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String time,
    required String status,
    required Color statusColor,
    required String imgUrl,
    required bool isLast,
    String? activityId,
  }) {
    final bool isActivity = activityId != null;
    final content = Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align to top for proper timeline drawing
      children: [
        // Timeline graphics
        Column(
          children: [
            ClipOval(
              child: Image.network(
                imgUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
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
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _C.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isActivity) {
      return GestureDetector(
        onTap: () {
          context.go(
            '/supervisor/student/${_student?.id}/activity/$activityId',
            extra: <String, String>{
              'studentName': _student?.name ?? 'Unknown',
              'activityTitle': title,
            },
          );
        },
        child: content,
      );
    }

    return content;
  }
}

// ==========================================
// CUSTOM CLIPPERS & PAINTERS
// ==========================================

// Wave Clipper for the green shape at the bottom of the middle card
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);

    // Wave starting point on the right
    path.lineTo(size.width, size.height * 0.4);

    // Curves for wave
    path.quadraticBezierTo(
      size.width * 0.7,
      0,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 1.1,
      0,
      size.height * 0.7,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Painter for the vertical dotted line in the timeline
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.textFaint
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 8;

    while (startY < size.height - 8) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
