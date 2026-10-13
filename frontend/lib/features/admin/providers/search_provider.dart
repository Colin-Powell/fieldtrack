import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'dart:async';

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _load();
  }

  static const _key = 'admin_recent_searches';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_key) ?? [];
    state = searches;
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final newList = [trimmed, ...state.where((s) => s.toLowerCase() != trimmed.toLowerCase())];
    if (newList.length > 5) newList.removeLast(); // Keep top 5
    
    state = newList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, newList);
  }

  Future<void> clearSearches() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final globalSearchProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.trim().isEmpty) return {'users': [], 'departments': [], 'projects': []};
  
  // A small delay to act as a debounce if a user is typing fast
  await Future.delayed(const Duration(milliseconds: 300));
  
  final api = ApiClient();
  final response = await api.dio.get('/admin/search', queryParameters: {'q': query});
  return response.data;
});
