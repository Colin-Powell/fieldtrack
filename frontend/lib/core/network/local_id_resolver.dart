import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class LocalIdResolver {
  static const String _boxName = 'local_id_mappings';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  void addMapping(String localId, String serverId) {
    _box.put(localId, serverId);
  }

  String? getServerId(String localId) {
    return _box.get(localId);
  }

  /// Replaces any occurrences of local IDs with server IDs in a string.
  /// This is used to fix URLs like `/activities/local_123/evidence`.
  String resolveInString(String input) {
    String result = input;
    for (var localId in _box.keys) {
      final serverId = _box.get(localId);
      if (serverId != null) {
        result = result.replaceAll(localId as String, serverId);
      }
    }
    return result;
  }

  /// Deeply resolves local IDs in a JSON map or list.
  dynamic resolveInJson(dynamic data) {
    if (data is String) {
      return resolveInString(data);
    } else if (data is Map) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        result[resolveInString(key as String)] = resolveInJson(value);
      });
      return result;
    } else if (data is List) {
      return data.map((item) => resolveInJson(item)).toList();
    }
    return data;
  }
}

final localIdResolver = LocalIdResolver();
