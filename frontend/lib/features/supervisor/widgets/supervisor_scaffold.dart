import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:fieldtrack/core/widgets/error_boundary.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SupervisorScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentLocation;

  const SupervisorScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  ConsumerState<SupervisorScaffold> createState() => _SupervisorScaffoldState();
}

class _SupervisorScaffoldState extends ConsumerState<SupervisorScaffold> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    if (widget.currentLocation.startsWith('/supervisor/students') ||
        widget.currentLocation.startsWith('/supervisor/student/')) {
      selectedIndex = 1;
    } else if (widget.currentLocation.startsWith('/supervisor/reports')) {
      selectedIndex = 2;
    } else if (widget.currentLocation.startsWith('/supervisor/map')) {
      selectedIndex = 3;
    } else if (widget.currentLocation.startsWith('/supervisor/settings')) {
      selectedIndex = 4;
    }

    const Color sidebarColor = Color(0xFF1BA654);
    const Color activeItemBg = Colors.white;
    const Color activeItemIcon = Color(0xFF1BA654);

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
          width: expanded ? 240 : 100,
          margin: isDrawer
              ? EdgeInsets.zero
              : const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          constraints: BoxConstraints(
            maxHeight: isDrawer
                ? double.infinity
                : MediaQuery.of(context).size.height - 32,
          ),
          decoration: BoxDecoration(
            color: sidebarColor,
            borderRadius: isDrawer
                ? BorderRadius.zero
                : BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // Logo
              Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (expanded) const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/logo.png',
                    width: expanded ? 32 : 40,
                    height: expanded ? 32 : 40,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(PhosphorIconsFill.leaf, color: Colors.white, size: expanded ? 32 : 40),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'FieldTrack',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white.withOpacity(0.3), height: 1),
              ),
              const SizedBox(height: 32),

              // Navigation Items (scrollable area)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.house,
                        PhosphorIconsRegular.house,
                        'Dashboard',
                        0,
                        selectedIndex,
                        '/supervisor/dashboard',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 16),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.graduationCap,
                        PhosphorIconsRegular.graduationCap,
                        'Students',
                        1,
                        selectedIndex,
                        '/supervisor/students',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 16),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.addressBook,
                        PhosphorIconsRegular.addressBook,
                        'Reports',
                        2,
                        selectedIndex,
                        '/supervisor/reports',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 16),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.mapTrifold,
                        PhosphorIconsRegular.mapTrifold,
                        'Map',
                        3,
                        selectedIndex,
                        '/supervisor/map',
                        activeItemBg,
                        activeItemIcon,
                        expanded,
                        isDrawer,
                      ),
                      const SizedBox(height: 16),
                      _buildNavItem(
                        context,
                        PhosphorIconsFill.gear,
                        PhosphorIconsRegular.gear,
                        'Settings',
                        4,
                        selectedIndex,
                        '/supervisor/settings',
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
                child: Divider(color: Colors.white.withOpacity(0.3), height: 1),
              ),
              const SizedBox(height: 24),

              _buildLogoutItem(context, expanded, isDrawer),
              const SizedBox(height: 16),

              // Avatar
              GestureDetector(
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  context.go('/supervisor/settings', extra: 'Profile');
                },
                child: Builder(
                  builder: (ctx) {
                    final user = ref.watch(authProvider).user;
                    final avatarUrl = user?.avatarUrl ?? '';
                    final displayName = user?.name ?? 'Supervisor';
                    return Row(
                      mainAxisAlignment: expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (expanded) const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: AppAvatar(
                              imagePath: avatarUrl.isNotEmpty
                                  ? avatarUrl
                                  : null,
                              size: 48,
                              shape: AvatarShape.circle,
                              initials: displayName.isNotEmpty
                                  ? displayName
                                        .split(' ')
                                        .map((s) => s.isNotEmpty ? s[0] : '')
                                        .take(2)
                                        .join()
                                  : null,
                            ),
                          ),
                        ),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: buildSidebar(isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) buildSidebar(isDrawer: false),

          // Main Content Area
          Expanded(
            child: ErrorBoundary(
              title: 'Screen Error',
              child: ClipRRect(child: widget.child),
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
    bool isDrawer,
  ) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        if (isDrawer) Navigator.pop(context);
        if (!isSelected) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: expanded ? 208 : 56,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeIconColor : Colors.white,
              size: 24,
            ),
            if (expanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeIconColor : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Poppins',
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

  Widget _buildLogoutItem(BuildContext context, bool expanded, bool isDrawer) {
    return GestureDetector(
      onTap: () async {
        if (isDrawer) Navigator.pop(context);
        try {
          await ApiClient().dio.post('/auth/logout');
        } catch (_) {}
        ref.read(authProvider.notifier).logout();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: expanded ? 208 : 56,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
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
                    fontFamily: 'Poppins',
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
