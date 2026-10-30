import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldtrack/core/providers/navigation_provider.dart';
import 'package:fieldtrack/features/notifications/providers/notifications_provider.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Unread', 'Mentions'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color backgroundColor) {
    final textWidth = message.length * 10.0 + 60.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = ((screenWidth - textWidth) / 2)
        .clamp(24.0, screenWidth)
        .toDouble();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        margin: EdgeInsets.only(
          bottom: 40,
          left: horizontalMargin,
          right: horizontalMargin,
        ),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  void _setSelectionMode(bool value) {
    if (_isSelectionMode == value) {
      ref.read(notificationSelectionModeProvider.notifier).state = value;
      return;
    }

    setState(() {
      _isSelectionMode = value;
    });
    ref.read(notificationSelectionModeProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);

    List<NotificationModel> filtered = [];
    if (notificationsState.hasValue) {
      filtered = notificationsState.value!.where((n) {
        if (_selectedFilterIndex == 1 && n.isRead) return false;
        if (_selectedFilterIndex == 2) return false;
        if (_searchQuery.isNotEmpty) {
          return n.title.toLowerCase().contains(_searchQuery) ||
              n.message.toLowerCase().contains(_searchQuery);
        }
        return true;
      }).toList();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Dynamic background and loader colors
    final scaffoldBg = isDark ? const Color(0xFF121212) : theme.scaffoldBackgroundColor;
    final primaryGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
    final loaderBg = isDark ? const Color(0xFF1E1E1E) : theme.cardColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar(isDark) : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsProvider.notifier).fetchNotifications(),
          color: primaryGreen,
          backgroundColor: loaderBg,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                if (_isSelectionMode)
                  _buildSelectionHeader(filtered, isDark)
                else
                  _buildHeaderTitle(filtered, isDark),

                _buildSearchBar(isDark),
                _buildFilters(isDark),

                notificationsState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: NotificationSkeletonList(),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Text(
                      'Error loading notifications',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (notifications) {
                    if (filtered.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final n = filtered[index];
                        final timeString = _formatTime(n.createdAt);

                        return GestureDetector(
                          onLongPress: () {
                            _setSelectionMode(true);
                            setState(() {
                              if (_selectedIds.contains(n.id)) {
                                _selectedIds.remove(n.id);
                              } else {
                                _selectedIds.add(n.id);
                              }
                            });
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (_selectedIds.contains(n.id)) {
                                  _selectedIds.remove(n.id);
                                } else {
                                  _selectedIds.add(n.id);
                                }
                              });
                              return;
                            }

                            if (!n.isRead) {
                              ref
                                  .read(notificationsProvider.notifier)
                                  .markAsRead(n.id);
                              _showSnackbar(
                                'Marked as read',
                                isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654),
                              );
                            }

                            if (n.type == 'CHECKED_IN' ||
                                n.type == 'CHECKED_OUT') {
                              context.push('/checkin');
                            } else if ((n.type == 'REVIEW_RECEIVED' ||
                                    n.type == 'ACTIVITY_APPROVED') &&
                                n.entityId != null) {
                              context.push('/activity-detail/${n.entityId}');
                            } else if (n.type == 'NEW_SUBMISSION') {
                              context.push('/activities');
                            }
                          },
                          child: _buildNotificationCard(
                            title: n.title,
                            subtitle: n.message,
                            time: timeString,
                            isRead: n.isRead,
                            isSelected: _selectedIds.contains(n.id),
                            icon: _getIconForType(n.type),
                            iconColor: _getColorForType(n.type, isDark),
                            isDark: isDark,
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

  // --- WIDGET COMPONENTS ---

  Widget _buildSelectionHeader(List<NotificationModel> filtered, bool isDark) {
    final bool isAllSelected =
        filtered.isNotEmpty && _selectedIds.length == filtered.length;
    final textColor = isDark ? Colors.white : Colors.black;
    final activeGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.x,
              color: textColor,
              size: 28,
            ),
            onPressed: () {
              _selectedIds.clear();
              _setSelectionMode(false);
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedIds.length} Selected',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          if (_selectedIds.isNotEmpty)
            IconButton(
              tooltip: 'Delete selected',
              icon: Icon(
                PhosphorIconsRegular.trash,
                color: isDark ? const Color(0xFFFCA5A5) : Colors.red,
                size: 24,
              ),
              onPressed: () {
                ref
                    .read(notificationsProvider.notifier)
                    .deleteBulkNotifications(_selectedIds.toList());
                _showSnackbar(
                  '${_selectedIds.length} deleted',
                  isDark ? const Color(0xFF450A0A) : Colors.redAccent,
                );
                _selectedIds.clear();
                _setSelectionMode(false);
              },
            ),
          InkWell(
            onTap: () {
              setState(() {
                if (isAllSelected) {
                  _selectedIds.clear();
                } else {
                  _selectedIds = filtered.map((n) => n.id).toSet();
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isAllSelected ? activeGreen : textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isAllSelected
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsRegular.checkCircle,
                    color: isAllSelected ? activeGreen : textColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBottomBar(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomBarAction(
              icon: PhosphorIconsRegular.envelopeOpen,
              label: 'Read',
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
              isDark: isDark,
              onTap: _selectedIds.isEmpty
                  ? null
                  : () {
                      ref
                          .read(notificationsProvider.notifier)
                          .markBulkAsRead(_selectedIds.toList());
                      _showSnackbar(
                        '${_selectedIds.length} marked as read',
                        isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654),
                      );
                      _selectedIds.clear();
                      _setSelectionMode(false);
                    },
            ),
            _buildBottomBarAction(
              icon: PhosphorIconsRegular.trash,
              label: 'Delete',
              color: isDark ? const Color(0xFFFCA5A5) : Colors.red,
              isDark: isDark,
              onTap: _selectedIds.isEmpty
                  ? null
                  : () {
                      ref
                          .read(notificationsProvider.notifier)
                          .deleteBulkNotifications(_selectedIds.toList());
                      _showSnackbar(
                        '${_selectedIds.length} deleted',
                        isDark ? const Color(0xFF450A0A) : Colors.redAccent,
                      );
                      _selectedIds.clear();
                      _setSelectionMode(false);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    final disabledColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : disabledColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEnabled ? color : disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(List<NotificationModel> filtered, bool isDark) {
    final pillBg = isDark ? const Color(0xFF14532D) : const Color(0xFFCBE5D2);
    final pillTextColor = isDark ? const Color(0xFF4ADE80) : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 44),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: pillTextColor,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showMenuBottomSheet(filtered, isDark),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: pillBg, shape: BoxShape.circle),
              child: Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                color: pillTextColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenuBottomSheet(List<NotificationModel> filtered, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 32,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuOption(
                icon: PhosphorIconsRegular.listChecks,
                title: 'Select items',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _setSelectionMode(true);
                },
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                icon: PhosphorIconsRegular.envelopeOpen,
                iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                title: 'Mark all as read',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                  _showSnackbar(
                    'All marked as read', 
                    isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? (isDark ? Colors.white : Colors.black), size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: isDark ? Colors.white70 : Colors.black,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: 'Search Notifications',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654), 
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
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
            child: _buildFilterChip(_filters[index], isDark, isActive: isActive),
          );
        }),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark, {bool isActive = false}) {
    final activeBg = isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654);
    final activeText = isDark ? const Color(0xFF4ADE80) : Colors.white;
    final inactiveText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? activeText : inactiveText,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
    required bool isDark,
    bool isSelected = false,
    String? imageUrl,
    IconData? icon,
    Color? iconColor,
  }) {
    final cardBorder = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    
    // Unread and Read Backgrounds
    final readBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final unreadBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFF4FDF7);
    final selectedBg = isDark ? const Color(0xFF14532D) : const Color(0xFFE8F5E9);
    final defaultBg = isRead ? readBg : unreadBg;

    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563);
    final timeColor = isDark ? const Color(0xFFA1A1AA) : (isRead ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
    final activeBorderColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : defaultBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isSelected
              ? activeBorderColor
              : (isRead
                    ? cardBorder
                    : activeBorderColor.withValues(alpha: isDark ? 0.5 : 0.3)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Samsung Style Selection Checkbox
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isSelected
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsRegular.circle,
                color: isSelected
                    ? activeBorderColor
                    : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                size: 26,
              ),
            ),

          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      ImageUtils.getFullImageUrl(imageUrl),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackIcon(isDark);
                      },
                    )
                  : _buildFallbackIcon(isDark),
            )
          else if (icon != null)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (iconColor ?? activeBorderColor).withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 28)),
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
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isRead && !_isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(right: 6, top: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeBorderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
      child: Icon(
        PhosphorIconsRegular.image,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14532D) : const Color(0xFFF3F9F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.bellSlash,
              size: 48,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications matching this filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
              height: 1.4,
            ),
          ),
        ],
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
      case 'CHECKED_IN':
        return PhosphorIconsFill.mapPin;
      case 'REVIEW_RECEIVED':
        return PhosphorIconsFill.star;
      case 'SYSTEM_ALERT':
        return PhosphorIconsFill.warningCircle;
      default:
        return PhosphorIconsFill.bellRinging;
    }
  }

  Color _getColorForType(String type, bool isDark) {
    switch (type) {
      case 'CHECKED_IN':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
      case 'REVIEW_RECEIVED':
        return isDark ? const Color(0xFFFDE047) : const Color(0xFFF59E0B);
      case 'SYSTEM_ALERT':
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE53935);
      default:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFF97316);
    }
  }
}

// --- SKELETON LOADER WIDGET ---

class NotificationSkeletonList extends StatefulWidget {
  const NotificationSkeletonList({super.key});

  @override
  State<NotificationSkeletonList> createState() =>
      _NotificationSkeletonListState();
}

class _NotificationSkeletonListState extends State<NotificationSkeletonList>
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
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _animation,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}