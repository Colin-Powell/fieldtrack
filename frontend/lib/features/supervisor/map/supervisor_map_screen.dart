import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart' as pkg_provider;
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import '../dashboard/dashboard_state.dart';
import '../widgets/supervisor_top_header.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import '../../../../core/services/location_naming_service.dart';
import 'package:intl/intl.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF3F4F6);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFE8F0FE);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFEDD5);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const purple = Color(0xFFA855F7);

  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 40.0;
}

// ==========================================
// DATA MODELS
// ==========================================
enum StudentStatus { inField, idle, checkedOut, offline, pendingReview }

class MapStudent {
  final String id;
  final String name;
  final String avatarUrl;
  final String topic;
  final String regNo;
  final StudentStatus status;
  final String time;
  final LatLng location;
  final String locationName;
  final List<LatLng> routeHistory;

  const MapStudent({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.regNo,
    required this.topic,
    required this.status,
    required this.time,
    required this.location,
    required this.locationName,
    required this.routeHistory,
  });

  Color get statusColor {
    switch (status) {
      case StudentStatus.inField:
        return _C.green;
      case StudentStatus.idle:
        return _C.orange;
      case StudentStatus.checkedOut:
        return _C.blue;
      case StudentStatus.offline:
        return _C.red;
      case StudentStatus.pendingReview:
        return _C.purple;
    }
  }

  String get statusText {
    switch (status) {
      case StudentStatus.inField:
        return 'In Field';
      case StudentStatus.idle:
        return 'Idle';
      case StudentStatus.checkedOut:
        return 'Checked Out';
      case StudentStatus.offline:
        return 'Offline';
      case StudentStatus.pendingReview:
        return 'Pending Review';
    }
  }

  String get locationLabel {
    if (locationName.isNotEmpty) {
      return locationName;
    }

    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
  }
}

class AlertUpdate {
  final String title;
  final String subtitle;
  final String time;

  const AlertUpdate({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

// ==========================================
// MAIN SCREEN
// ==========================================
class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({super.key});

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  String _searchQuery = '';
  final MapController _mapController = MapController();

  MapStudent? _selectedStudent;

  final List<AlertUpdate> _alerts = [
    const AlertUpdate(
      title: 'Student left designated region',
      subtitle: 'Jane Akinyi (BBIT/2021/045)',
      time: '2m ago',
    ),
    const AlertUpdate(
      title: 'Activity log submitted',
      subtitle: 'Mark Mutua (BCS/2021/102)',
      time: '15m ago',
    ),
  ];

  String _buildStudentLocationName(StudentData student) {
    if (student.gpsHistory.isNotEmpty) {
      final lastAddress = student.gpsHistory.last.address;
      if (lastAddress.isNotEmpty) {
        return lastAddress;
      }
    }

    final session = student.currentSession;
    if (session == null) return '';

    final parts = [
      session.village,
      session.ward,
      session.subCounty,
      session.county,
    ].where((part) => part.isNotEmpty).toList();

    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  List<MapStudent> _getAllStudents(List<StudentData> students) {
    // Show all students assigned, mapping their statuses and locations
    return students
        .map((s) {
          final status = s.fieldStatus == FieldStatus.inField
              ? StudentStatus.inField
              : s.fieldStatus == FieldStatus.checkedOut
              ? StudentStatus.checkedOut
              : s.fieldStatus == FieldStatus.offline
              ? StudentStatus.offline
              : (s.fieldStatus == FieldStatus.awaitingReview ||
                    s.fieldStatus == FieldStatus.revisionRequested)
              ? StudentStatus.pendingReview
              : StudentStatus.idle;
              
          // Determine location (current session > last gps > fallback)
          LatLng location = const LatLng(-1.2921, 36.8219); // Default fallback
          if (s.currentSession != null) {
            location = LatLng(s.currentSession!.latitude, s.currentSession!.longitude);
          } else if (s.gpsHistory.isNotEmpty) {
            location = LatLng(s.gpsHistory.last.latitude, s.gpsHistory.last.longitude);
          }
          
          String timeStr = '--';
          if (s.currentSession != null) {
            timeStr = DateFormat('hh:mm a').format(s.currentSession!.checkInTime);
          }

          return MapStudent(
            id: s.id,
            name: s.name,
            regNo: s.reg,
            topic: s.topic,
            status: status,
            time: timeStr,
            location: location,
            locationName: _buildStudentLocationName(s),
            routeHistory: s.activities
                .map((a) => LatLng(a.location.latitude, a.location.longitude))
                .toList(),
            avatarUrl: s.avatarUrl.isNotEmpty
                ? s.avatarUrl
                : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(s.name)}&background=1BA654&color=fff',
          );
        })
        .toList();
  }

  List<MapStudent> _getFilteredStudents(List<MapStudent> allStudents) {
    if (_searchQuery.isEmpty) return allStudents;
    final q = _searchQuery.toLowerCase();
    return allStudents
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.topic.toLowerCase().contains(q),
        )
        .toList();
  }

  void _selectStudent(MapStudent student) {
    setState(() => _selectedStudent = student);
    _mapController.move(
      student.location,
      14.5,
    ); // Zooms into selected student route
  }

  void _showStudentModal(MapStudent student) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _StudentActionModal(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStudents = context.select<DashboardState, List<StudentData>>(
      (s) => s.students,
    );
    final allStudents = _getAllStudents(rawStudents);
    final filteredStudents = _getFilteredStudents(allStudents);

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 32),
              _buildMainContent(allStudents, filteredStudents, rawStudents),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeletons ─────────────────────────────────────────────────────────
  // ── 1. Top Header ─────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return SupervisorTopHeader(
      title: 'Live Field Map',
      subtitle: 'Monitor Students in the field in real-time',
      searchHint: 'Search Student...',
      onSearchChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  // ── 2. Main Content (Responsive Row/Col) ──────────────────────────────
  Widget _buildMainContent(
    List<MapStudent> allStudents,
    List<MapStudent> filteredStudents,
    List<StudentData> rawStudents,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;

        final leftCol = Column(
          children: [
            _buildTopStatsCard(allStudents, rawStudents),
            const SizedBox(height: 24),
            _buildMapCard(filteredStudents),
          ],
        );

        final rightCol = Column(
          children: [
            _buildStudentsListCard(allStudents, filteredStudents),
            const SizedBox(height: 24),
            _buildAlertsCard(),
          ],
        );

        if (isNarrow) {
          return Column(
            children: [leftCol, const SizedBox(height: 24), rightCol],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 70, child: leftCol),
            const SizedBox(width: 24),
            Expanded(flex: 30, child: rightCol),
          ],
        );
      },
    );
  }

  // ── 3. Top Stats Card ─────────────────────────────────────────────────
  Widget _buildTopStatsCard(
    List<MapStudent> allStudents,
    List<StudentData> rawStudents,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final inFieldCount = rawStudents
              .where(
                (s) => s.checkInStatus.toLowerCase().trim() == 'checked in',
              )
              .length;
          final checkedOutCount = rawStudents
              .where(
                (s) => s.checkInStatus.toLowerCase().trim() == 'checked out',
              )
              .length;
          final pendingReviewCount = rawStudents
              .where(
                (s) =>
                    s.fieldStatus == FieldStatus.awaitingReview ||
                    s.fieldStatus == FieldStatus.revisionRequested,
              )
              .length;
          final notCheckedInCount = rawStudents
              .where(
                (s) => s.checkInStatus.toLowerCase().trim() != 'checked in',
              )
              .length;

          final stats = [
            _buildStatItem(
              'Students in Field',
              '$inFieldCount',
              'Live now',
              PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
              _C.greenLight,
              _C.green,
            ),
            _buildStatItem(
              'Checked Out',
              '$checkedOutCount',
              'Today',
              PhosphorIcons.student(PhosphorIconsStyle.fill),
              _C.blueLight,
              _C.blue,
            ),
            _buildStatItem(
              'Pending Review',
              '$pendingReviewCount',
              'Review queue',
              PhosphorIcons.hourglass(PhosphorIconsStyle.fill),
              _C.orangeLight,
              _C.orange,
            ),
            _buildStatItem(
              'Not checked in',
              '$notCheckedInCount',
              'Today',
              PhosphorIcons.userMinus(PhosphorIconsStyle.fill),
              _C.redLight,
              _C.red,
            ),
          ];

          if (isNarrow) {
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: stats
                  .map(
                    (s) => SizedBox(
                      width: (constraints.maxWidth - 24) / 2,
                      child: s,
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats,
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color circleBg,
    Color iconColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: iconColor == _C.green ? _C.green : _C.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. Map Card ───────────────────────────────────────────────────────
  Widget _buildMapCard(List<MapStudent> filteredStudents) {
    final initialCenter =
        _selectedStudent?.location ??
        (filteredStudents.isNotEmpty
            ? filteredStudents.first.location
            : const LatLng(-1.2921, 36.8219));

    return Container(
      height: 650,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_C.cardRadius),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.0,
                onTap: (_, __) => setState(() => _selectedStudent = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_selectedStudent != null &&
                    _selectedStudent!.routeHistory.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _selectedStudent!.routeHistory,
                        strokeWidth: 4.5,
                        color: _selectedStudent!.statusColor,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: filteredStudents
                      .map(
                        (s) => Marker(
                          point: s.location,
                          width: _selectedStudent?.id == s.id ? 100 : 80,
                          height: _selectedStudent?.id == s.id ? 108 : 88,
                          alignment: Alignment.bottomCenter,
                          child: Tooltip(
                            message:
                                '${s.name}\n${s.regNo}\n${s.statusText}\n${s.locationLabel}',
                            preferBelow: false,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.6,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Floating name label
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: s.statusColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    s.name.split(' ').first,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: s.statusColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Avatar pin
                                GestureDetector(
                                  onTap: () => _selectStudent(s),
                                  child: Container(
                                    width: _selectedStudent?.id == s.id
                                        ? 56
                                        : 44,
                                    height: _selectedStudent?.id == s.id
                                        ? 56
                                        : 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: s.statusColor,
                                        width: _selectedStudent?.id == s.id
                                            ? 4.5
                                            : 3.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: s.statusColor.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: 46,
                                      height: 46,
                                      child: AppAvatar(
                                        imagePath: s.avatarUrl.isNotEmpty
                                            ? s.avatarUrl
                                            : null,
                                        size: 46,
                                        shape: AvatarShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

            Positioned(
              top: 24,
              right: 24,
              child: _buildMapPillButton('Map Style', PhosphorIcons.stack()),
            ),
            Positioned(top: 100, right: 24, child: _buildZoomControls()),
            Positioned(
              top: 210,
              right: 24,
              child: _buildMapIconButton(PhosphorIcons.crosshair()),
            ),

            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(child: _buildMapLegend()),
            ),

            if (_selectedStudent != null)
              Positioned(
                top: 24,
                left: 24,
                child: _buildMapTooltipCard(_selectedStudent!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTooltipCard(MapStudent student) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: AppAvatar(
                  imagePath: student.avatarUrl.isNotEmpty
                      ? student.avatarUrl
                      : null,
                  size: 48,
                  shape: AvatarShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _C.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      student.regNo,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedStudent = null),
                child: Icon(PhosphorIcons.x(), color: _C.textFaint, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                color: student.statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<String>(
                  future: student.locationName.isNotEmpty
                      ? Future.value(student.locationName)
                      : LocationNamingService().getLocationName(student.location.latitude, student.location.longitude),
                  builder: (context, snapshot) {
                    final displayLoc = snapshot.data ?? 'Lat: ${student.location.latitude.toStringAsFixed(4)}, Lng: ${student.location.longitude.toStringAsFixed(4)}';
                    return Text(
                      displayLoc,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showStudentModal(student),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'View Full Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPillButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.textMuted, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: _C.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Icon(PhosphorIcons.caretDown(), color: _C.textMuted, size: 16),
        ],
      ),
    );
  }

  Widget _buildMapIconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _C.textDark, size: 20),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            child: const SizedBox(
              height: 48,
              child: Center(
                child: Icon(Icons.add, color: _C.textDark, size: 20),
              ),
            ),
          ),
          const Divider(height: 1, color: _C.border, indent: 8, endIndent: 8),
          InkWell(
            onTap: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            child: const SizedBox(
              height: 48,
              child: Center(
                child: Icon(Icons.remove, color: _C.textDark, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        children: [
          _buildLegendItem('In Field', _C.green),
          _buildLegendItem('Idle', _C.orange),
          _buildLegendItem('Checked Out', _C.blue),
          _buildLegendItem('Offline', _C.red),
          _buildLegendItem('Pending Review', _C.purple),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: _C.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── 5. Right Sidebar: Students List ───────────────────────────────────
  Widget _buildStudentsListCard(
    List<MapStudent> allStudents,
    List<MapStudent> filteredStudents,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student in Field (${allStudents.length})',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 24),

          if (filteredStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  "No students found.",
                  style: TextStyle(fontFamily: 'Poppins', color: _C.textFaint),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: _C.border),
              ),
              itemBuilder: (context, index) {
                final s = filteredStudents[index];
                final isSelected = _selectedStudent?.id == s.id;

                return InkWell(
                  onTap: () {
                    _selectStudent(s);
                    _showStudentModal(s);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _C.greenLight.withOpacity(0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: AppAvatar(
                            imagePath: s.avatarUrl.isNotEmpty
                                ? s.avatarUrl
                                : null,
                            size: 44,
                            shape: AvatarShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _C.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.topic,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: _C.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.statusText,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: s.statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.time,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: _C.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── 6. Right Sidebar: Alerts & Updates ────────────────────────────────
  Widget _buildAlertsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts & Updates',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 24),

          if (_alerts.isEmpty)
            const Text(
              "No recent alerts.",
              style: TextStyle(fontFamily: 'Poppins', color: _C.textFaint),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _C.greenLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: _C.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _C.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: _C.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      alert.time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==========================================
// CENTERED ACTION MODAL (Dialog)
// ==========================================
class _StudentActionModal extends StatelessWidget {
  final MapStudent student;
  const _StudentActionModal({required this.student});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 450,
        ), // Keeps it neatly centered & sized
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: AppAvatar(
                      imagePath: student.avatarUrl.isNotEmpty
                          ? student.avatarUrl
                          : null,
                      size: 64,
                      shape: AvatarShape.circle,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.regNo} • ${student.statusText}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: student.statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.x(),
                        color: _C.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                      color: _C.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Topic',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _C.textMuted,
                            ),
                          ),
                          Text(
                            student.topic,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _C.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        PhosphorIcons.chatCircleText(),
                        color: _C.textDark,
                        size: 20,
                      ),
                      label: const Text(
                        'Message',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: _C.border, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final studentData = StudentData(
                          id: student.id,
                          name: student.name,
                          avatarUrl: student.avatarUrl,
                          reg: student.regNo,
                          programme: '',
                          topic: student.topic,
                          status: student.statusText,
                          checkInStatus: student.statusText,
                          lastActivity: student.time,
                        );
                        context.go(
                          '/supervisor/student/${student.id}',
                          extra: studentData.toMap(),
                        );
                      },
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
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
  }
}

// ==========================================
// SKELETON LOADER WIDGET
// ==========================================
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
            color: const Color(0xFFE5E7EB).withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
