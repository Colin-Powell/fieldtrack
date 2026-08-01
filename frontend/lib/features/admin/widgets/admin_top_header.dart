import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../notifications/admin_notifications_screen.dart';
import 'admin_search_bar.dart';

class AdminTopHeader extends ConsumerWidget {
  final String currentLocation;

  const AdminTopHeader({
    super.key,
    required this.currentLocation,
  });

  String _getPageTitle() {
    if (currentLocation.startsWith('/admin/dashboard')) return 'System Dashboard';
    if (currentLocation.startsWith('/admin/users')) return 'User Management';
    if (currentLocation.startsWith('/admin/departments')) return 'Departments';
    if (currentLocation.startsWith('/admin/projects')) return 'Research Projects';
    if (currentLocation.startsWith('/admin/reports')) return 'Reports';
    if (currentLocation.startsWith('/admin/map')) return 'Live Map';
    if (currentLocation.startsWith('/admin/notifications')) return 'Notifications';
    if (currentLocation.startsWith('/admin/audit')) return 'Audit Logs';
    if (currentLocation.startsWith('/admin/settings')) return 'Settings';
    if (currentLocation.startsWith('/admin/profile')) return 'Profile';
    return 'Admin Portal';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final notificationsAsync = ref.watch(adminNotificationsProvider);
    final hasUnread = (notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0) > 0;
    final userName = user?.name ?? 'Admin User';
    final userEmail = user?.email ?? 'admin@university.edu';
    final pageTitle = _getPageTitle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F9),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Title and Search
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    pageTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 24),
                // Search Bar
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const AdminSearchBar(),
                  ),
                ),
              ],
            ),
          ),
          // Right Side: Actions and Profile
          Row(
            children: [
              // Notification Bell
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: IconButton(
                  onPressed: () => context.go('/admin/notifications'),
                  icon: Stack(
                    children: [
                      Icon(PhosphorIcons.bell(), color: const Color(0xFF4B5563), size: 22),
                      if (hasUnread) Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Help Circle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(PhosphorIcons.question(), color: const Color(0xFF4B5563), size: 22),
                ),
              ),
              const SizedBox(width: 24),

              // Profile Dropdown
              PopupMenuButton(
                offset: const Offset(0, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                  PopupMenuItem(
                    onTap: () => context.go('/admin/profile'),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.userCircle(), size: 20, color: const Color(0xFF4B5563)),
                        const SizedBox(width: 12),
                        const Text('My Profile', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => context.go('/admin/settings'),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.gear(), size: 20, color: const Color(0xFF4B5563)),
                        const SizedBox(width: 12),
                        const Text('System Settings', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/admin/login');
                    },
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.signOut(), size: 20, color: const Color(0xFFEF4444)),
                        const SizedBox(width: 12),
                        const Text('Logout', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF1BA654),
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(PhosphorIcons.caretDown(), color: const Color(0xFF6B7280), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
