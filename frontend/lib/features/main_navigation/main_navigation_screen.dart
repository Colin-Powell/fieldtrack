import 'package:flutter/material.dart';
// Note: Ensure these imports point to your actual files
import 'package:fieldtrack/features/activities/activities_screen.dart';
import 'package:fieldtrack/features/dashboard/dashboard_screen.dart';
import 'package:fieldtrack/features/map/map_screen.dart';
import 'package:fieldtrack/features/notifications/notifications_screen.dart';
import 'package:fieldtrack/features/notifications/providers/notifications_provider.dart';
import 'package:fieldtrack/features/profile/profile_screen.dart';
import 'package:fieldtrack/core/widgets/error_boundary.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/navigation_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  static const _pages = <Widget>[
    DashboardScreen(),
    ActivitiesScreen(),
    MapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedIndex = ref.watch(navigationIndexProvider);
    final isSelectionMode = ref.watch(notificationSelectionModeProvider);
    final notifsAsync = ref.watch(notificationsProvider);
    final unreadCount =
        notifsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    // Dynamic Colors for Nav Bar
    final navBarBgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFF1BA654);
    final navBarShadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.5) 
        : const Color(0xFF1BA654).withValues(alpha: 0.3);
    final navBarBorder = isDark 
        ? Border.all(color: const Color(0xFF333333), width: 1.5) 
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : theme.scaffoldBackgroundColor,
      // extendBody ensures the body content scrolls underneath the floating nav bar
      extendBody: true,
      body: Stack(
        children: [
          // Main content screens - wrapped in ErrorBoundary to prevent app crashes
          ErrorBoundary(
            title: 'Screen Error',
            child: IndexedStack(index: selectedIndex, children: _pages),
          ),

          // Floating Navigation Bar
          if (!isSelectionMode)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: navBarBgColor,
                  borderRadius: BorderRadius.circular(36), // Pill shape
                  border: navBarBorder,
                  boxShadow: [
                    BoxShadow(
                      color: navBarShadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(
                      Icons.home,
                      'Home',
                      0,
                      selectedIndex,
                      isDark,
                    ),
                    _buildNavItem(
                      Icons.article,
                      'Activities',
                      1,
                      selectedIndex,
                      isDark,
                    ),
                    _buildNavItem(
                      Icons.location_on,
                      'Map',
                      2,
                      selectedIndex,
                      isDark,
                    ),
                    _buildNavItem(
                      Icons.notifications,
                      'Alerts',
                      3,
                      selectedIndex,
                      isDark,
                      badgeCount: unreadCount,
                    ),
                    _buildNavItem(
                      Icons.account_circle,
                      'Profile',
                      4,
                      selectedIndex,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int selectedIndex,
    bool isDark, {
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    
    // Dynamic Colors for the Items
    final activeBgColor = isDark ? const Color(0xFF14532D) : const Color(0xFFC3DFCC);
    final activeColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
    final inactiveColor = isDark ? const Color(0xFFA1A1AA) : Colors.white;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                // Notification Badge Logic
                if (badgeCount > 0 && !isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // Red badge always visible
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}