import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupervisorScaffold extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const SupervisorScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<SupervisorScaffold> createState() => _SupervisorScaffoldState();
}

class _SupervisorScaffoldState extends State<SupervisorScaffold> {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // Floating Sidebar
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isExpanded ? 240 : 100,
              margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 32,
              ),
              decoration: BoxDecoration(
                color: sidebarColor,
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: _isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      if (_isExpanded) const SizedBox(width: 8),
                      const Text(
                        'F',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (_isExpanded) ...[
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
                    child: Divider(
                      color: Colors.white.withOpacity(0.3),
                      height: 1,
                    ),
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
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: Colors.white.withOpacity(0.3),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLogoutItem(context),
                  const SizedBox(height: 16),

                  // Avatar
                  GestureDetector(
                    onTap: () =>
                        context.go('/supervisor/settings', extra: 'Profile'),
                    child: Row(
                      mainAxisAlignment: _isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (_isExpanded) const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(PhosphorIconsFill.userCircle, color: Colors.white, size: 32),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Prof. Okeyo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Area
          Expanded(child: ClipRRect(child: widget.child)),
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
  ) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isExpanded ? 208 : 56,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 0),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: _isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeIconColor : Colors.white,
              size: 24,
            ),
            if (_isExpanded) ...[
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

  Widget _buildLogoutItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/supervisor/login');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isExpanded ? 208 : 56,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: _isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.signOut,
              color: Colors.white,
              size: 24,
            ),
            if (_isExpanded) ...[
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
