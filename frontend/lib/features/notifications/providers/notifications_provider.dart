import 'dart:async';

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
  final String? entityId;
  final String? entityType;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.entityId,
    this.entityType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM_ALERT',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
    );
  }
}

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiClient _api;
  Timer? _refreshTimer;

  NotificationsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchNotifications();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await fetchNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.dio.get('/notifications');
      final rawData = response.data;
      final List<dynamic> data = rawData is List 
          ? rawData 
          : (rawData['data'] as List<dynamic>? ?? []);
          
      final notifications = data
          .map((e) => NotificationModel.fromJson(e))
          .toList();
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

  Future<void> markAllAsRead() async {
    try {
      await _api.dio.patch('/notifications/read-all');
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            entityId: n.entityId,
            entityType: n.entityType,
          );
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Show error silently
    }
  }

  Future<void> markBulkAsRead(List<String> ids) async {
    try {
      await _api.dio.post('/notifications/read-bulk', data: {'ids': ids});
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (ids.contains(n.id)) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              entityId: n.entityId,
              entityType: n.entityType,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _api.dio.delete('/notifications/$id');
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data(currentList.where((n) => n.id != id).toList());
      }
    } catch (e) {}
  }

  Future<void> deleteBulkNotifications(List<String> ids) async {
    try {
      await _api.dio.post('/notifications/delete-bulk', data: {'ids': ids});
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data(currentList.where((n) => !ids.contains(n.id)).toList());
      }
    } catch (e) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      return NotificationsNotifier(ApiClient());
    });
