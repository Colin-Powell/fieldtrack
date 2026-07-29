import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // State variables for our tabs and loading skeleton
  int _selectedFilterIndex = 0;
  bool _isLoading = true;
  final List<String> _filters = ['All', 'Today', 'In Progress', 'Submitted'];

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial load
  }

  // Simulating a network delay to show the skeleton loader
  void _fetchData() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
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

          // Floating Action Button
          Positioned(bottom: 32, right: 24, child: _buildFab()),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_filters.length, (index) {
          final isActive = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              if (!isActive) {
                setState(() => _selectedFilterIndex = index);
                _fetchData(); // Trigger loading state for new tab
              }
            },
            child: _buildFilterChip(_filters[index], isActive: isActive),
          );
        }),
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
  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        children: const [_SkeletonCard(), _SkeletonCard(), _SkeletonCard()],
      );
    }

    // Mocking an empty state for the 'Today' tab (Index 1) for demonstration
    if (_selectedFilterIndex == 1) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3)
          _buildActivityCard(
            title: 'Mangrove Vegetation Survey',
            location: 'Mtwapa Creek',
            time: '08:45 AM • 1h 20m',
            statusText: 'Submitted',
            statusColor: const Color(0xFF1BA654),
            statusBgColor: const Color(0xFFC3DFCC),
            gpsVerifiedColor: const Color(0xFF1BA654),
            imageUrl:
                'https://images.unsplash.com/photo-1627914041132-720da5d7df53?q=80&w=256&auto=format&fit=crop',
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2)
          _buildActivityCard(
            title: 'Water Quality Sampling',
            location: 'Mtwapa Creek',
            time: '25 Jul 2026 • 08:45 AM',
            statusText: 'In Progress',
            statusColor: const Color(0xFF3B82F6),
            statusBgColor: const Color(0xFFDBEAFE),
            gpsVerifiedColor: const Color(0xFF3B82F6),
            imageUrl:
                'https://images.unsplash.com/photo-1616423640778-28d1b53229bd?q=80&w=256&auto=format&fit=crop',
          ),
      ],
    );
  }

  // Clean Empty State
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F9F5), // Light green background
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.folderDashed,
              size: 48,
              color: Color(0xFF1BA654),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No activities found',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no activities matching this filter at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String location,
    required String time,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required Color gpsVerifiedColor,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () => context.push('/activity-detail'),
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
            child: Image.network(
              imageUrl,
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
                    Text(
                      location,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF737373),
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
