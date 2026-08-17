import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/features/admin/widgets/admin_top_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/error_boundary.dart';

class AdminScaffold extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    if (widget.currentLocation.startsWith('/admin/dashboard')) {
      selectedIndex = 0;
    } else if (widget.currentLocation.startsWith('/admin/users')) {
      selectedIndex = 1;
    } else if (widget.currentLocation.startsWith('/admin/departments')) {
      selectedIndex = 2;
    } else if (widget.currentLocation.startsWith('/admin/projects')) {
      selectedIndex = 3;
    } else if (widget.currentLocation.startsWith('/admin/reports')) {
      selectedIndex = 4;
    } else if (widget.currentLocation.startsWith('/admin/map')) {
      selectedIndex = 5;
    } else if (widget.currentLocation.startsWith('/admin/notifications')) {
      selectedIndex = 6;
    } else if (widget.currentLocation.startsWith('/admin/audit')) {
      selectedIndex = 7;
    } else if (widget.currentLocation.startsWith('/admin/settings')) {
      selectedIndex = 8;
    } else if (widget.currentLocation.startsWith('/admin/profile')) {
      selectedIndex = 9;
    }

    const Color sidebarColor = Color(0xFF169B45);
    const Color activeItemBg = Colors.white;
    const Color activeItemIcon = Color(0xFF169B45);

    final bool isMobile = MediaQuery.of(context).size.width < 1024;

    Widget buildSidebar({required bool isDrawer}) {
      final bool expanded = isDrawer || _isExpanded;
      return GestureDetector(
        onTap: () {
          if (!isDrawer) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: expanded
              ? 240
              : 120, // 120px collapsed as per spec (120-140px)
          margin: isDrawer
              ? EdgeInsets.zero
              : const EdgeInsets.only(left: 32, top: 32, bottom: 32),
          constraints: BoxConstraints(
            maxHeight: isDrawer
                ? double.infinity
                : MediaQuery.of(context).size.height - 64,
          ),
          decoration: BoxDecoration(
            color: sidebarColor,
            borderRadius: isDrawer
                ? BorderRadius.zero
                : BorderRadius.circular(32),
            boxShadow: isDrawer
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'lib/assets/Images/logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.2),
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.squaresFour,
                        PhosphorIconsRegular.squaresFour,
                        'Dashboard',
                        0,
                        selectedIndex,
                        '/admin/dashboard',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                        shortcutHint: 'Alt+D',
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.users,
                        PhosphorIconsRegular.users,
                        'Users',
                        1,
                        selectedIndex,
                        '/admin/users',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                        shortcutHint: 'Alt+U',
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.buildings,
                        PhosphorIconsRegular.buildings,
                        'Departments',
                        2,
                        selectedIndex,
                        '/admin/departments',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.files,
                        PhosphorIconsRegular.files,
                        'Projects',
                        3,
                        selectedIndex,
                        '/admin/projects',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.chartBar,
                        PhosphorIconsRegular.chartBar,
                        'Reports',
                        4,
                        selectedIndex,
                        '/admin/reports',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.mapTrifold,
                        PhosphorIconsRegular.mapTrifold,
                        'Map',
                        5,
                        selectedIndex,
                        '/admin/map',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.bell,
                        PhosphorIconsRegular.bell,
                        'Alerts',
                        6,
                        selectedIndex,
                        '/admin/notifications',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.shield,
                        PhosphorIconsRegular.shield,
                        'Audit',
                        7,
                        selectedIndex,
                        '/admin/audit',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.gear,
                        PhosphorIconsRegular.gear,
                        'Settings',
                        8,
                        selectedIndex,
                        '/admin/settings',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.2),
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),

              _buildLogoutItem(context, expanded, isDrawer),
              const SizedBox(height: 16),

              // Avatar
              GestureDetector(
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  context.go('/admin/profile');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final user = ref.watch(authProvider).user;
                        return Container(
                          width: 60, // 60px Profile Avatar
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.substring(0, 1) ?? 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              'System Admin',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7), // Neutral background from spec
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: buildSidebar(isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          // Floating Sidebar
          if (!isMobile) buildSidebar(isDrawer: false),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                AdminTopHeader(currentLocation: widget.currentLocation),

                // Content with Error Boundary
                Expanded(
                  child: ErrorBoundary(
                    title: 'Screen Error',
                    child: ClipRRect(child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
    int selectedIndex,
    String route,
    Color activeBg,
    Color activeIconColor,
    bool expanded,
    bool isDrawer, {
    String? shortcutHint,
  }) {
    final bool isSelected = index == selectedIndex;
    final String tooltipMessage = shortcutHint != null ? '$label ($shortcutHint)' : label;

    return Tooltip(
      message: tooltipMessage,
      child: GestureDetector(
      onTap: () {
        if (isDrawer) Navigator.pop(context);
        if (!isSelected) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: expanded ? 180 : 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? activeIconColor
                  : Colors.white.withValues(alpha: isSelected ? 1.0 : 0.8),
              size: 28, // Icon size 28px
            ),
            if (expanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? activeIconColor
                        : Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Inter', // Material 3 typography style
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context, bool expanded, bool isDrawer) {
    return GestureDetector(
      onTap: () async {
        if (isDrawer) Navigator.pop(context);
        try {
          // You must import 'package:fieldtrack/core/network/api_client.dart' for this to work
          await ApiClient().dio.post('/auth/logout');
        } catch (_) {}
        ProviderScope.containerOf(context, listen: false).read(authProvider.notifier).logout();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: expanded ? 180 : 72,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.signOut,
              color: Colors.white,
              size: 24,
            ),
            if (expanded) ...[
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
