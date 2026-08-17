import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/providers/notifications_provider.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupervisorTopHeader extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final Widget? trailingWidget;

  const SupervisorTopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onSearchChanged,
    this.searchHint = 'Search',
    this.trailingWidget,
  });

  @override
  ConsumerState<SupervisorTopHeader> createState() => _SupervisorTopHeaderState();
}

class _SupervisorTopHeaderState extends ConsumerState<SupervisorTopHeader> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isNotificationOpen = false;
  bool _isSearchExpanded = false;

  void _toggleNotifications() {
    if (_isNotificationOpen) {
      _closeNotifications();
    } else {
      _showNotifications();
    }
  }

  void _closeNotifications() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isNotificationOpen = false;
      });
    }
  }

  void _showNotifications() {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: _buildNotificationContent(isModal: true),
            ),
          );
        },
      );
    } else {
      _overlayEntry = _createNotificationOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isNotificationOpen = true;
      });
    }
  }

  OverlayEntry _createNotificationOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Invisible barrier to close when clicking outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeNotifications,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              offset: const Offset(-250, 60), // Adjust dropdown position
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildNotificationContent(isModal: false),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationContent({required bool isModal}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isModal)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Mark all as read conceptually
                  if (!isModal) _closeNotifications();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: Consumer(
            builder: (context, ref, child) {
              final notifsAsync = ref.watch(notificationsProvider);
              return notifsAsync.when(
                data: (notifs) {
                  if (notifs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No notifications', style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      return _buildNotificationItem(
                        n.title,
                        n.message,
                        DateFormat('MMM d, h:mm a').format(n.createdAt),
                        isUnread: !n.isRead,
                        onTap: () {
                          ref.read(notificationsProvider.notifier).markAsRead(n.id);
                          if (isModal) {
                            Navigator.pop(context);
                          } else {
                            _closeNotifications();
                          }
                        }
                      );
                    },
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                error: (_, __) => const Center(child: Text('Failed to load notifications')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String time, {bool isUnread = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () { _closeNotifications(); },
      child: Container(
        color: isUnread ? const Color(0xFFF0FDF4) : Colors.transparent,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread ? const Color(0xFF16A34A) : Colors.transparent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);
    final hasUnread = (notifsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0) > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        final isDesktop = MediaQuery.of(context).size.width >= 1024;

        final titleSection = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isDesktop && !(_isSearchExpanded && narrow)) ...[
              IconButton(
                icon: Icon(PhosphorIcons.list(), color: Colors.black, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 16),
            ],
            if (!(_isSearchExpanded && narrow)) ...[

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (widget.subtitleWidget != null) ...[
                      const SizedBox(height: 4),
                      widget.subtitleWidget!,
                    ] else if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );

        final actionsSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onSearchChanged != null && (!narrow || _isSearchExpanded)) ...[
              if (_isSearchExpanded && narrow)
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = false;
                    });
                  },
                ),
              if (_isSearchExpanded && narrow) const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (_isSearchExpanded && narrow) ? constraints.maxWidth - 60 : 260,
                  minWidth: 140,
                ),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF9CA3AF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: widget.onSearchChanged,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: widget.searchHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onSearchChanged != null && narrow && !_isSearchExpanded) ...[
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                  },
                  icon: Icon(PhosphorIcons.magnifyingGlass(), color: const Color(0xFF4B5563), size: 22),
                ),
              ),
            ],
            if (!_isSearchExpanded || !narrow) ...[
              const SizedBox(width: 16),
              CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  onTap: _toggleNotifications,
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.bell, color: Color(0xFF6B7280), size: 24),
                        if (hasUnread) Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.trailingWidget != null) ...[
                const SizedBox(width: 16),
                widget.trailingWidget!,
              ],
            ],
          ],
        );

        if (constraints.maxWidth < 900) {
          // On tablets/mobile, wrap to two lines if needed, or stack them
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleSection,
              const SizedBox(height: 16),
              actionsSection,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 24),
            actionsSection,
          ],
        );
      },
    );
  }
}
