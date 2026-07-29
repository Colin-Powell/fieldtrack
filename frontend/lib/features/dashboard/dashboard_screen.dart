import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/core/providers/checkin_provider.dart';
import 'package:fieldtrack/core/providers/navigation_provider.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';
import 'package:fieldtrack/features/dashboard/providers/student_dashboard_provider.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/shared/widgets/skeleton_loader.dart';
import 'package:fieldtrack/shared/widgets/empty_state_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);
    final checkInState = ref.watch(checkInProvider);
    const greenColor = Color(0xFF1BA654);

    // Status styling based on checkin state
    final Color statusBgColor = checkInState.isCheckedIn ? const Color(0xFFC3DFCC) : const Color(0xFFFFEBEE);
    final Color statusIconBgColor = checkInState.isCheckedIn ? greenColor : const Color(0xFFE53935);
    final Color statusTextColor = checkInState.isCheckedIn ? greenColor : const Color(0xFFE53935);
    final String statusTitle = checkInState.isCheckedIn ? 'Checked In' : 'Not Checked In';
    final String statusTime = checkInState.isCheckedIn 
        ? '${DateFormat('hh:mm a').format(checkInState.checkInTime!)} | ${DateFormat('dd MMM yyyy').format(checkInState.checkInTime!)}'
        : 'Tap to check in';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // Extra bottom padding ensures the last items aren't hidden behind the floating nav bar
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, locState, checkInState, statusBgColor, statusIconBgColor, statusTextColor, statusTitle, statusTime, ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Today\'s Summary'),
            _buildSummaryGrid(ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Quick Actions'),
            _buildQuickActions(context, ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Recent Activities'),
            _buildRecentActivities(context, ref),
            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
    );
  }

  // --- 1. GREEN HEADER COMPONENT ---
  Widget _buildHeader(
      BuildContext context, 
      LocationState locState, 
      CheckInState checkInState,
      Color statusBgColor,
      Color statusIconBgColor,
      Color statusTextColor,
      String statusTitle,
      String statusTime,
      WidgetRef ref
  ) {
    const greenColor = Color(0xFF1BA654);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Display student name or fallback
    final name = user?.name ?? 'Student';
    
    // Fetch real student profile details from authentication payload
    final prog = user?.programme ?? 'Environmental Sciences';
    final dept = user?.department ?? 'Pwani University';
    final details = '$prog\n$dept';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: greenColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning,',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              // Profile Image
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    PhosphorIconsFill.userCircle,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildHeaderStat(
                  'Location',
                  locState.isLocating
                      ? 'Locating...'
                      : locState.locationName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildHeaderStat(
                  'Accuracy',
                  locState.isLocating
                      ? '—'
                      : '${locState.accuracy.toStringAsFixed(0)} m',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildHeaderStat('Time in field', '02h 15m'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Pill Card
          GestureDetector(
            onTap: () {
              if (!checkInState.isCheckedIn) {
                context.push('/checkin');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusBgColor, 
                borderRadius: BorderRadius.circular(40), 
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusIconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsFill.article, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  // Text Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Status',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: statusTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusTitle,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusTime,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0xFF737373),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: statusTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // --- 2. SUMMARY GRID ---
  Widget _buildSummaryGrid(WidgetRef ref) {
    final statsAsync = ref.watch(studentDashboardProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        clipBehavior: Clip.antiAlias, // Ensures internal dividers don't bleed out of larger corner radii
        decoration: BoxDecoration(
          color: const Color(0xFFF3F9F5), // Very light pale green
          borderRadius: BorderRadius.circular(40), // Increased for larger pill shape
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSummaryCell('Activities', '${stats.approvals}', PhosphorIconsFill.article)),
                  Container(width: 1, height: 60, color: const Color(0xFFE5E7EB)),
                  Expanded(child: _buildSummaryCell('Hours Logged', '${stats.hoursLogged}', PhosphorIconsFill.folder)),
                ],
              ),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
              Row(
                children: [
                  Expanded(child: _buildSummaryCell('Status', stats.status, PhosphorIconsFill.cloudCheck)),
                  Container(width: 1, height: 60, color: const Color(0xFFE5E7EB)),
                  Expanded(child: _buildSummaryCell('Check Out', '--', PhosphorIconsBold.arrowsClockwise)),
                ],
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF169B45))),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(child: Text('Error loading stats', style: TextStyle(color: Colors.red))),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCell(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1BA654), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Color(0xFF737373),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. QUICK ACTIONS ---
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionBtn(
            'Check Out', 
            PhosphorIconsRegular.target, 
            const Color(0xFFFEE2E2), 
            const Color(0xFFEF4444),
            onTap: () async {
              final success = await ref.read(checkInProvider.notifier).checkOut();
              if (success) {
                ToastService.showSuccess('Checked out. Session recorded.');
              }
            },
          ),
          _buildQuickActionBtn(
            'New Activity', 
            PhosphorIconsFill.article, 
            const Color(0xFFC3DFCC), 
            const Color(0xFF1BA654),
            onTap: () => context.push('/field-session'),
          ),
          _buildQuickActionBtn(
            'Feedback', 
            PhosphorIconsFill.chatCircleText, 
            const Color(0xFFC3DFCC), 
            const Color(0xFF1BA654),
            onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
          ),
          _buildQuickActionBtn(
            'View Map', 
            PhosphorIconsFill.mapTrifold, 
            const Color(0xFFC3DFCC), 
            const Color(0xFF1BA654),
            onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(studentActivitiesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ApiResultBuilder<List<dynamic>>(
        asyncValue: activitiesAsync,
        onRetry: () => ref.refresh(studentActivitiesProvider),
        customLoading: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ListSkeletonLoader(itemCount: 3, itemHeight: 90),
        ),
        onData: (activities) {
          if (activities.isEmpty) {
            return const EmptyStateWidget(
              title: 'No recent activities',
              message: 'Check in or create a draft to get started.',
              icon: PhosphorIconsRegular.clipboardText,
            );
          }

          return Column(
            children: activities.map<Widget>((activity) {
              final title = activity['title'] ?? 'Untitled Activity';
              final status = activity['status'] ?? 'DRAFT';
              
              // Map status to colors
              Color statusColor = const Color(0xFF1BA654);
              Color statusBgColor = const Color(0xFFC3DFCC);
              if (status == 'DRAFT') {
                statusColor = const Color(0xFF3B82F6);
                statusBgColor = const Color(0xFFDBEAFE);
              } else if (status == 'UNDER_REVIEW') {
                statusColor = const Color(0xFFEAB308);
                statusBgColor = const Color(0xFFFEF08A);
              } else if (status == 'REJECTED') {
                statusColor = const Color(0xFFEF4444);
                statusBgColor = const Color(0xFFFEE2E2);
              }

              // Extract time
              String timeStr = '';
              if (activity['timestamp'] != null) {
                final dt = DateTime.parse(activity['timestamp']).toLocal();
                timeStr = DateFormat('dd MMM yyyy • hh:mm a').format(dt);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildActivityCard(
                  context: context,
                  id: activity['id'],
                  title: title,
                  location: "Lat: ${activity['latitude']?.toStringAsFixed(4) ?? '-'}, Lng: ${activity['longitude']?.toStringAsFixed(4) ?? '-'}",
                  time: timeStr,
                  status: status,
                  statusColor: statusColor,
                  statusBgColor: statusBgColor,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required String id,
    required String title,
    required String location,
    required String time,
    required String status,
    Color statusColor = const Color(0xFF1BA654),
    Color statusBgColor = const Color(0xFFC3DFCC),
  }) {
    return GestureDetector(
      onTap: () => context.push('/activity-detail/$id'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // Increased for larger pill shape
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Fallback Image Icon replacing the Network Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Light grey placeholder
                borderRadius: BorderRadius.circular(32), // Completely round
              ),
            child: const Icon(
              PhosphorIconsRegular.image, 
              color: Color(0xFF9CA3AF), // Grey icon
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20), // Increased for pill styling
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(PhosphorIconsRegular.caretRight, color: Colors.black, size: 20),
        ],
      ),
      ),
    );
  }

  // --- HELPER FOR SECTION TITLES ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

