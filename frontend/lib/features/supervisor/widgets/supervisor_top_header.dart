import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupervisorTopHeader extends StatefulWidget {
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
  State<SupervisorTopHeader> createState() => _SupervisorTopHeaderState();
}

class _SupervisorTopHeaderState extends State<SupervisorTopHeader> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isNotificationOpen = false;

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
    _overlayEntry = _createNotificationOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isNotificationOpen = true;
    });
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                              onPressed: _closeNotifications,
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
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            _buildNotificationItem(
                              'New Field Log',
                              'Jane Akinyi submitted a new field log.',
                              '10 min ago',
                              isUnread: true,
                            ),
                            _buildNotificationItem(
                              'Report Ready',
                              'Weekly supervision report is ready.',
                              '2 hours ago',
                            ),
                            _buildNotificationItem(
                              'Location Update',
                              'David Mutua left the geofenced area.',
                              '1 day ago',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String time, {bool isUnread = false}) {
    return InkWell(
      onTap: () {
        _closeNotifications();
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
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
            if (widget.onSearchChanged != null) ...[
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: narrow ? 160 : 260,
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
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A), // Green dot
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
        );
      },
    );
  }
}
