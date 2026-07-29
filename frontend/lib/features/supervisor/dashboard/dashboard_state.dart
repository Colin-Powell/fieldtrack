import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:fieldtrack/features/supervisor/repositories/student_repository.dart';

// ── Data models ───────────────────────────────────────────────────────────

class RecentActivity {
  final String title;
  final String location;
  final String time;
  final String imageUrl;
  final String? activityId;
  final String? studentId;
  final String? studentName;

  const RecentActivity({
    required this.title,
    required this.location,
    required this.time,
    required this.imageUrl,
    this.activityId,
    this.studentId,
    this.studentName,
  });
}

class FeedItem {
  final String time;
  final String content;

  const FeedItem({required this.time, required this.content});
}

// ── Dashboard State ───────────────────────────────────────────────────────

class DashboardState extends ChangeNotifier {
  final StudentRepository _repository;
  DashboardState({StudentRepository? repository})
    : _repository = repository ?? StudentRepository();

  // ── Loading / Error state ────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // ── Reactive dashboard stats ──
  Map<String, dynamic>? _supervisor;
  Map<String, dynamic>? _trend;
  
  int _checkedIn = 0;
  int _inField = 0;
  int _checkedOut = 0;
  int _studentsCheckedInToday = 0;
  int _studentsInField = 0;
  int _activitiesSubmitted = 0;
  int _pendingReviews = 0;

  Map<String, dynamic>? get supervisor => _supervisor;
  Map<String, dynamic>? get trend => _trend;
  
  int get checkedIn => _checkedIn;
  int get inField => _inField;
  int get checkedOut => _checkedOut;
  int get studentsCheckedInToday => _studentsCheckedInToday;
  int get studentsInField => _studentsInField;
  int get activitiesSubmitted => _activitiesSubmitted;
  int get pendingReviews => _pendingReviews;

  // ── Data-backed lists ────────────────────────────────────────────────
  List<StudentData> _students = [];
  List<RecentActivity> _allActivities = [];
  List<FeedItem> _feedItems = [];

  /// Full student list for dashboard drill-down.
  List<StudentData> get students => _students;

  /// Students currently in the field (derived from student data).
  int get studentsInFieldFromData =>
      _students.where((s) => s.fieldStatus == FieldStatus.inField).length;

  /// Students checked in today (derived from student data).
  int get studentsCheckedInFromData =>
      _students.where((s) => s.checkInStatus == 'Checked In').length;

  // ── Search query ─────────────────────────────────────────────────────
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Filtered recent activities ───────────────────────────────────────
  List<RecentActivity> get filteredActivities {
    if (_searchQuery.isEmpty) {
      return _allActivities;
    }
    final q = _searchQuery.toLowerCase();
    return _allActivities.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q);
    }).toList();
  }

  List<FeedItem> get feedItems => _feedItems;

  @override
  void dispose() {
    super.dispose();
  }

  // ── Load dashboard data from repository ──────────────────────────────

  /// Called once at app start to hydrate the dashboard from the API.
  /// Falls back to hardcoded defaults when the backend is unavailable.
  Future<void> loadDashboard({bool isPolling = false}) async {
    if (!isPolling) {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      // 1. Fetch dashboard stats
      final stats = await _repository.fetchDashboardStats();
      
      _supervisor = stats['supervisor'] as Map<String, dynamic>?;
      
      if (stats['statistics'] != null) {
        final st = stats['statistics'] as Map<String, dynamic>;
        _checkedOut = st['checkedOut'] as int? ?? 0;
        _checkedIn = st['checkedIn'] as int? ?? 0;
        _studentsInField = st['studentsInField'] as int? ?? 0;
        _activitiesSubmitted = st['activitiesSubmitted'] as int? ?? 0;
        _pendingReviews = st['pendingApprovals'] as int? ?? 0;
      }
      
      _studentsCheckedInToday = stats['studentsCheckedIn'] as int? ?? 0;
      if (stats['trend'] != null) {
        _trend = Map<String, String>.from(stats['trend'] as Map);
      }
      
      if (stats['recentActivities'] != null) {
        final recent = stats['recentActivities'] as List<dynamic>;
        _allActivities = recent.map((e) {
          final map = e as Map<String, dynamic>;
          final user = map['user'] as Map<String, dynamic>?;
          return RecentActivity(
            title: map['title'] as String? ?? 'Activity',
            location: 'Location Captured',
            time: map['timestamp'] != null ? _formatTime(DateTime.parse(map['timestamp'])) : '',
            imageUrl: user?['avatarUrl'] as String? ?? '',
            activityId: map['id'] as String?,
            studentId: map['studentId'] as String?,
            studentName: user?['name'] as String?,
          );
        }).toList();
      }
      
    } catch (_) {
      // Empty state
      if (!isPolling) _allActivities = [];
    }

    try {
      // 2. Fetch all students (provides data for list)
      _students = await _repository.fetchStudents();
      
      // Update feed items from real student events
      _feedItems = [];
      for (final student in _students) {
        if (student.lastActivity.isNotEmpty) {
          _feedItems.add(
            FeedItem(
              time: _formatTimeAgoShort(student.lastActivity),
              content: 'Activity submitted by ${student.name}',
            ),
          );
        }
      }
    } catch (_) {
      if (!isPolling) _students = [];
    }

    if (!isPolling) {
      _isLoading = false;
    }
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Formats time like "10:45 AM"
  String _formatTime(DateTime dt) {
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '${hr.toString().padLeft(2, '0')}:$min $ampm';
  }

  /// Short time label (HH:MM) used in feed items.
  String _formatTimeAgoShort(String raw) {
    // If it's already a short time string return it; otherwise try parsing
    if (raw.length <= 5 && raw.contains(':')) return raw;
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
