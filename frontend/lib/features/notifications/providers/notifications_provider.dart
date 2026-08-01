import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/api_result.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM_ALERT',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiClient _api;

  NotificationsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.dio.get('/notifications');
      final data = response.data as List<dynamic>;
      final notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
      state = AsyncValue.data(notifications);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.dio.patch('/notifications/$id/read');
      // Optimistically update the UI
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Revert or show error silently
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ApiClient());
});
