import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/providers/activity_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/shared/widgets/empty_state_widget.dart';
import 'package:fieldtrack/shared/widgets/skeleton_loader.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  // State variables for our tabs and loading skeleton
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'All',
    'Today',
    'Drafts',
    'Submitted',
    'Needs Revision',
  ];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _activitiesPerPage = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 0; // Reset pagination on search
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Simulating a network delay to show the skeleton loader

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF1BA654),
              onRefresh: () async {
                  final status = _getStatusString(_selectedFilterIndex);
                  final params = (
                    page: _currentPage + 1,
                    limit: _activitiesPerPage,
                    status: status.isNotEmpty ? status : null,
                    search: _searchQuery.isNotEmpty ? _searchQuery : null,
                  );

                  ref.invalidate(studentActivitiesProvider);
                await ref.read(studentActivitiesProvider(params).future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    _buildHeaderTitle(),
                    _buildSearchBar(),
                    _buildFilters(),
                    _buildContent(), // Displays Loading, Empty State, or List
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Button
          Positioned(bottom: 110, right: 24, child: _buildFab()),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeaderTitle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFCBE5D2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          'My Activities',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Clean, single-input pill search bar using native TextField decoration
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: Colors.black,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: 'Search activities',
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          // Clean Pill Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFF1BA654), width: 1.5),
          ),
        ),
      ),
    );
  }

  // Interactive Switch Tabs
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(_filters.length, (index) {
            final isActive = _selectedFilterIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (!isActive) {
                    setState(() => _selectedFilterIndex = index);
                  }
                },
                child: _buildFilterChip(_filters[index], isActive: isActive),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1BA654) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  // Determines which content to show based on state
  String _getStatusString(int index) {
    if (index == 1) return 'TODAY';
    if (index == 2) return 'DRAFT';
    if (index == 3) return 'SUBMITTED';
    if (index == 4) return 'REVISION_REQUESTED';
    return '';
  }

  Widget _buildContent() {
    return Column(
      children: [
        for (int i = 0; i <= _currentPage; i++) 
           _buildPage(i, isLastPage: i == _currentPage),
      ],
    );
  }

  Widget _buildPage(int pageIndex, {required bool isLastPage}) {
    final status = _getStatusString(_selectedFilterIndex);
    final params = (
      page: pageIndex + 1,
      limit: _activitiesPerPage,
      status: status.isNotEmpty ? status : null,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    final activitiesAsync = ref.watch(studentActivitiesProvider(params));

    return ApiResultBuilder<List<dynamic>>(
      asyncValue: activitiesAsync,
      onRetry: () => ref.refresh(studentActivitiesProvider(params)),
      customLoading: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ListSkeletonLoader(itemCount: 4, itemHeight: 120),
      ),
      onData: (activities) {
        if (activities.isEmpty && pageIndex == 0) {
          return _buildEmptyState();
        }

        final paginatedActivities = activities;
        final bool hasMore = paginatedActivities.length == _activitiesPerPage;

        if (paginatedActivities.isEmpty && pageIndex == 0) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Activity list
            ...paginatedActivities.map((activity) {
              final title = activity['title'] ?? 'Untitled Activity';
              final status = activity['status'] ?? 'DRAFT';

              Color statusColor = const Color(0xFF1BA654);
              Color statusBgColor = const Color(0xFFC3DFCC);
              String statusText = status;

              if (status == 'DRAFT') {
                statusColor = const Color(0xFF3B82F6);
                statusBgColor = const Color(0xFFDBEAFE);
                statusText = 'Draft';
              } else if (status == 'UNDER_REVIEW') {
                statusColor = const Color(0xFFEAB308);
                statusBgColor = const Color(0xFFFEF08A);
                statusText = 'Under Review';
              } else if (status == 'REJECTED') {
                statusColor = const Color(0xFFEF4444);
                statusBgColor = const Color(0xFFFEE2E2);
                statusText = 'Rejected';
              } else if (status == 'REVISION_REQUESTED') {
                statusColor = const Color(0xFFF97316);
                statusBgColor = const Color(0xFFFFEDD5);
                statusText = 'Needs Revision';
              } else if (status == 'APPROVED' ||
                  status == 'SUBMITTED' ||
                  status == 'RESUBMITTED') {
                statusText = 'Submitted';
              }

              String timeStr = '';
              if (activity['timestamp'] != null) {
                final dt = DateTime.parse(activity['timestamp']).toLocal();
                timeStr = DateFormat('dd MMM yyyy \u2014 hh:mm a').format(dt);
              }

              String? imageUrl;
              final evidenceList = activity['evidence'] as List<dynamic>? ?? [];
              for (final ev in evidenceList) {
                final mimeType = ev['mimeType'] as String? ?? '';
                if (mimeType.startsWith('image/')) {
                  final path = ev['storagePath'];
                  if (path != null) {
                    imageUrl = path;
                    break;
                  }
                }
              }

              final locName = activity['locationName'] as String?;
              final fallbackLoc =
                  "Lat: ${activity['latitude']?.toStringAsFixed(4) ?? '-'}, Lng: ${activity['longitude']?.toStringAsFixed(4) ?? '-'}";

              return _buildActivityCard(
                id: activity['id'] ?? '',
                title: title,
                location: locName != null && locName.isNotEmpty
                    ? locName
                    : fallbackLoc,
                time: timeStr,
                statusText: statusText,
                statusColor: statusColor,
                statusBgColor: statusBgColor,
                gpsVerifiedColor: const Color(0xFF1BA654),
                imageUrl: imageUrl,
              );
            }).toList(),
              // Pagination controls
              if (isLastPage && hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentPage++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1BA654),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(48),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: const Text('Load More', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _deleteActivity(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Activity',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this activity? This cannot be undone.',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(activityServiceProvider);
      final res = await api.deleteActivity(id);
      if (res is Success) {
        ref.invalidate(studentActivitiesProvider);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text((res as Failure).message)));
        }
      }
    }
  }

  // Clean Empty State
  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: 'No Activities',
      message:
          'You have not added any activities yet. Click the + button to create a new draft activity for your field session.',
      icon: PhosphorIconsRegular.clipboardText,
    );
  }

  Widget _buildActivityCard({
    required String id,
    required String title,
    required String location,
    required String time,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required Color gpsVerifiedColor,
    required String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () => context.push('/activity-detail/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: imageUrl != null
                  ? Image.network(
                      ImageUtils.getFullImageUrl(imageUrl),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            PhosphorIconsRegular.image,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        PhosphorIconsRegular.image,
                        color: Color(0xFF9CA3AF),
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF737373),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GPS Verified',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: gpsVerifiedColor,
                        ),
                      ),
                    ],
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
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
              onPressed: () => _deleteActivity(id),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: Colors.black,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () => context.push('/field-session'),
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1BA654),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'New Activity',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Color(0xFF1BA654),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Skeleton Layout matching the Activity Card
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Skeleton Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          const SizedBox(width: 16),
          // Skeleton Text Rows
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 90,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 110,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            PhosphorIconsRegular.caretRight,
            color: Color(0xFFF3F4F6),
            size: 24,
          ),
        ],
      ),
    );
  }
}
