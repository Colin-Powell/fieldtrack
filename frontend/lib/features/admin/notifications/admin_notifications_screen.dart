import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';

// ── Notification Model ──
class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final String time;
  final bool isRead;
  final String senderName;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.time,
    required this.isRead,
    required this.senderName,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM_ALERT',
      category: json['category'] ?? 'System Notifications',
      time: json['time'] ?? '',
      isRead: json['isRead'] ?? false,
      senderName: json['senderName'] ?? 'System',
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(time);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return time;
    }
  }

  Color get categoryColor {
    switch (type) {
      case 'SYSTEM_ALERT':
        return Colors.blue;
      case 'CHECKED_IN':
      case 'CHECKED_OUT':
        return const Color(0xFF169B45);
      case 'REVIEW_RECEIVED':
      case 'NEW_SUBMISSION':
        return Colors.purple;
      case 'SUPERVISOR_MESSAGE':
        return Colors.orange;
      default:
        return const Color(0xFF169B45);
    }
  }
}

// ── Providers ──
final adminNotificationsProvider = FutureProvider<List<AdminNotification>>((
  ref,
) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/notifications');
  final List<dynamic> data = response.data['notifications'];
  return data
      .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
      .toList();
});

final _categories = [
  'All Messages',
  'System Notifications',
  'University Announcements',
  'Emergency Alerts',
  'Maintenance',
];

IconData _getIconForCategory(String category) {
  switch (category) {
    case 'All Messages':
      return PhosphorIcons.tray();
    case 'System Notifications':
      return PhosphorIcons.cpu();
    case 'University Announcements':
      return PhosphorIcons.megaphone();
    case 'Emergency Alerts':
      return PhosphorIcons.warningCircle();
    case 'Maintenance':
      return PhosphorIcons.wrench();
    default:
      return PhosphorIcons.tray();
  }
}

// ── Notifications Screen ──
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  int _selectedCategory = 0;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _typeOptions = const [
    {'label': 'System Alert', 'value': 'SYSTEM_ALERT'},
    {'label': 'Announcement', 'value': 'ANNOUNCEMENT'},
    {'label': 'Supervisor Message', 'value': 'SUPERVISOR_MESSAGE'},
  ];
  String _selectedType = 'SYSTEM_ALERT';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send Broadcast',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. System Update',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: () {
                      final seen = <String>{};
                      final items = <DropdownMenuItem<String>>[];
                      for (final option in _typeOptions) {
                        final value = option['value'] as String?;
                        if (value == null || seen.contains(value)) continue;
                        seen.add(value);
                        items.add(
                          DropdownMenuItem<String>(
                            value: value,
                            child: Text(option['label'] as String),
                          ),
                        );
                      }
                      return items;
                    }(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => _selectedType = value);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Notification Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Type your broadcast message here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSending
                            ? null
                            : () async {
                                if (_titleController.text.trim().isEmpty ||
                                    _messageController.text.trim().isEmpty) {
                                  ToastService.showError(
                                    'Title and message are required',
                                  );
                                  return;
                                }
                                setModalState(() => _isSending = true);
                                try {
                                  await ApiClient().dio.post(
                                    '/admin/notifications/broadcast',
                                    data: {
                                      'title': _titleController.text.trim(),
                                      'message': _messageController.text.trim(),
                                      'type': _selectedType,
                                    },
                                  );
                                  ToastService.showSuccess(
                                    'Broadcast sent successfully',
                                  );
                                  _titleController.clear();
                                  _messageController.clear();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  ref.invalidate(adminNotificationsProvider);
                                } catch (e) {
                                  ToastService.showError(
                                    'Failed to send broadcast',
                                  );
                                } finally {
                                  if (ctx.mounted)
                                    setModalState(() => _isSending = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BA654),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Broadcast',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(adminNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Broadcast Center & Notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showBroadcastDialog,
                icon: Icon(PhosphorIcons.paperPlaneRight(), size: 18),
                label: const Text('Send Broadcast'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BA654),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar categories
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: List.generate(
                            _categories.length,
                            (i) => _buildCategoryItem(
                              _categories[i],
                              _getIconForCategory(_categories[i]),
                              _selectedCategory == i,
                              () => setState(() => _selectedCategory = i),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Notifications list
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: () {
                          final filteredList = _selectedCategory == 0 
                            ? notifications 
                            : notifications.where((n) => n.category == _categories[_selectedCategory]).toList();
                            
                          if (filteredList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIcons.tray(),
                                    size: 64,
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, i) =>
                                _buildNotificationCard(filteredList[i]),
                          );
                        }(),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  Expanded(flex: 1, child: Container()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1BA654),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              error: (err, stack) => Row(
                children: [
                  Expanded(flex: 1, child: Container()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.warning(),
                              size: 48,
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load notifications',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1BA654).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1BA654) : const Color(0xFF6B7280),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1BA654)
                : const Color(0xFF4B5563),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotification notification) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: notification.categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notification.type.replaceAll('_', ' '),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: notification.categoryColor,
                  ),
                ),
              ),
              Text(
                notification.formattedTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notification.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'From: ${notification.senderName}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
