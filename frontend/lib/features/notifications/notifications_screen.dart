import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/features/notifications/providers/notifications_provider.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Unread', 'Mentions'];

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildHeaderTitle(),
                _buildSearchBar(),
                _buildFilters(),
                
                notificationsState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: CircularProgressIndicator(color: Color(0xFF1BA654)),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: Text('Error loading notifications', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (notifications) {
                    final filtered = notifications.where((n) {
                      if (_selectedFilterIndex == 1) return !n.isRead;
                      if (_selectedFilterIndex == 2) return false; // Mentions not yet implemented on backend
                      return true; // All
                    }).toList();

                    if (filtered.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final n = filtered[index];
                        final timeString = _formatTime(n.createdAt);
                        
                        return GestureDetector(
                          onTap: () {
                            if (!n.isRead) {
                              ref.read(notificationsProvider.notifier).markAsRead(n.id);
                            }
                          },
                          child: Opacity(
                            opacity: n.isRead ? 0.6 : 1.0,
                            child: _buildNotificationCard(
                              title: n.title,
                              subtitle: n.message,
                              time: timeString,
                              icon: _getIconForType(n.type),
                              iconColor: _getColorForType(n.type),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'CHECKED_IN': return PhosphorIconsFill.mapPin;
      case 'REVIEW_RECEIVED': return PhosphorIconsFill.star;
      case 'SYSTEM_ALERT': return PhosphorIconsFill.warningCircle;
      default: return PhosphorIconsFill.bellRinging;
    }
  }
  
  Color _getColorForType(String type) {
    switch (type) {
      case 'CHECKED_IN': return const Color(0xFF1BA654);
      case 'REVIEW_RECEIVED': return const Color(0xFFF59E0B);
      case 'SYSTEM_ALERT': return const Color(0xFFE53935);
      default: return const Color(0xFFF97316);
    }
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
          'Notifications',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(PhosphorIconsRegular.magnifyingGlass, color: Colors.black, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: 'Search Notifications',
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required String time,
    String? imageUrl,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: imageUrl.isNotEmpty
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
                          child: const Icon(PhosphorIconsRegular.image, color: Color(0xFF9CA3AF), size: 32),
                        );
                      },
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(PhosphorIconsRegular.image, color: Color(0xFF9CA3AF), size: 32),
                    ),
            )
          else if (icon != null)
            SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: Icon(icon, color: iconColor, size: 48),
              ),
            ),
            
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F9F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.bellSlash,
              size: 48,
              color: Color(0xFF1BA654),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have no new notifications matching this filter.',
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
}
