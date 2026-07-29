import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// Note: Ensure these imports point to your actual files
import 'package:fieldtrack/features/activities/activities_screen.dart';
import 'package:fieldtrack/features/dashboard/dashboard_screen.dart';
import 'package:fieldtrack/features/map/map_screen.dart';
import 'package:fieldtrack/features/notifications/notifications_screen.dart';
import 'package:fieldtrack/features/profile/profile_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/navigation_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    ActivitiesScreen(),
    MapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF1BA654);
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      // extendBody ensures the body content scrolls underneath the floating nav bar
      extendBody: true,
      body: Stack(
        children: [
          // Main content screens
          IndexedStack(
            index: selectedIndex,
            children: _pages,
          ),
          
          // Floating Navigation Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: greenColor,
                borderRadius: BorderRadius.circular(36), // Pill shape
                boxShadow: [
                  BoxShadow(
                    color: greenColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(Icons.home, 'Home', 0, selectedIndex, greenColor),
                  _buildNavItem(Icons.article, 'Activities', 1, selectedIndex, greenColor),
                  _buildNavItem(Icons.location_on, 'Map', 2, selectedIndex, greenColor),
                  _buildNavItem(Icons.notifications, 'Alerts', 3, selectedIndex, greenColor, badgeCount: 2),
                  _buildNavItem(Icons.account_circle, 'Profile', 4, selectedIndex, greenColor),
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

  Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex, Color activeColor, {int badgeCount = 0}) {
    final isSelected = selectedIndex == index;
    const activeBgColor = Color(0xFFC3DFCC); // Light Green
    
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
                  color: isSelected ? activeColor : Colors.white,
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
                        color: Color(0xFFEF4444), // Red badge
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
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
                  fontFamily: 'Roboto',
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
