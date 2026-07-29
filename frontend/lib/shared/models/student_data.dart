// ── FieldTrack Student Data Models ────────────────────────────────────────
// Comprehensive data models for student information, activities, and field work

// ══════════════════════════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════════════════════════

enum FieldStatus {
  notStarted,
  checkedIn,
  inField,
  activitySubmitted,
  awaitingReview,
  revisionRequested,
  approved,
  checkedOut,
  offline,
}

enum ActivityStatus {
  draft,
  submitted,
  underReview,
  approved,
  revisionRequested,
  rejected,
}

enum EvidenceType {
  image,
  video,
  pdf,
  excel,
  word,
  audio,
}

enum ReviewStatus {
  approved,
  revision,
  rejected,
  pending,
}

enum ReportStatus {
  draft,
  submitted,
  underReview,
  approved,
  revisionRequested,
}

enum TimelineType {
  checkIn,
  checkOut,
  gpsUpdate,
  activityStart,
  activitySubmit,
  evidenceUpload,
  review,
  system,
}

enum NotificationType {
  activity,
  review,
  gps,
  reminder,
  report,
  system,
}

// ══════════════════════════════════════════════════════════════════════════
// 1. BASIC INFORMATION
// ══════════════════════════════════════════════════════════════════════════

class PersonalInfo {
  final String id;
  final String avatarUrl;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final DateTime dateJoined;

  const PersonalInfo({
    required this.id,
    required this.avatarUrl,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dateJoined,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 2. ACADEMIC INFORMATION
// ══════════════════════════════════════════════════════════════════════════

class AcademicInfo {
  final String regNo;
  final String programme;
  final String department;
  final String faculty;
  final String university;
  final int yearOfStudy;
  final String researchTopic;
  final String researchCategory;
  final String supervisorId;
  final String supervisorName;

  const AcademicInfo({
    required this.regNo,
    required this.programme,
    required this.department,
    required this.faculty,
    required this.university,
    required this.yearOfStudy,
    required this.researchTopic,
    required this.researchCategory,
    required this.supervisorId,
    required this.supervisorName,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 3. ACCOUNT STATUS
// ══════════════════════════════════════════════════════════════════════════

class AccountStatus {
  final bool active;
  final bool accountVerified;
  final bool profileCompleted;
  final bool locationEnabled;
  final bool notificationsEnabled;

  const AccountStatus({
    required this.active,
    required this.accountVerified,
    required this.profileCompleted,
    required this.locationEnabled,
    required this.notificationsEnabled,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 4. CURRENT FIELD SESSION
// ══════════════════════════════════════════════════════════════════════════

class CurrentFieldSession {
  final bool active;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final Duration duration;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final String county;
  final String subCounty;
  final String ward;
  final String village;

  const CurrentFieldSession({
    required this.active,
    required this.checkInTime,
    this.checkOutTime,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.county,
    required this.subCounty,
    required this.ward,
    required this.village,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 5. STUDENT STATISTICS
// ══════════════════════════════════════════════════════════════════════════

class StudentStatistics {
  final int totalFieldDays;
  final int totalActivities;
  final int totalReports;
  final int totalEvidence;
  final int totalImages;
  final int totalVideos;
  final int totalDocuments;
  final double totalDistanceTravelled;
  final Duration totalTimeInField;
  final DateTime firstCheckIn;
  final DateTime lastCheckOut;
  final double averageGPSAccuracy;

  const StudentStatistics({
    required this.totalFieldDays,
    required this.totalActivities,
    required this.totalReports,
    required this.totalEvidence,
    required this.totalImages,
    required this.totalVideos,
    required this.totalDocuments,
    required this.totalDistanceTravelled,
    required this.totalTimeInField,
    required this.firstCheckIn,
    required this.lastCheckOut,
    required this.averageGPSAccuracy,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 6. GPS LOCATION
// ══════════════════════════════════════════════════════════════════════════

class GPSLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final DateTime capturedAt;
  final String address;

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.capturedAt,
    required this.address,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 7. EVIDENCE FILE
// ══════════════════════════════════════════════════════════════════════════

class EvidenceFile {
  final String id;
  final EvidenceType type;
  final String fileName;
  final String url;
  final double sizeMB;
  final DateTime uploadedAt;
  final String uploadedBy;

  const EvidenceFile({
    required this.id,
    required this.type,
    required this.fileName,
    required this.url,
    required this.sizeMB,
    required this.uploadedAt,
    required this.uploadedBy,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 8. SUPERVISOR REVIEW
// ══════════════════════════════════════════════════════════════════════════

class SupervisorReview {
  final String reviewerId;
  final String reviewerName;
  final DateTime reviewedOn;
  final double rating;
  final ReviewStatus status;
  final String comments;
  final List<String> attachments;

  const SupervisorReview({
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewedOn,
    required this.rating,
    required this.status,
    required this.comments,
    required this.attachments,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 9. FIELD ACTIVITY
// ══════════════════════════════════════════════════════════════════════════

class FieldActivity {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final ActivityStatus status;
  final String methodology;
  final String objectives;
  final String findings;
  final String remarks;
  final GPSLocation location;
  final List<EvidenceFile> evidence;
  final SupervisorReview? review;

  const FieldActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
    required this.methodology,
    required this.objectives,
    required this.findings,
    required this.remarks,
    required this.location,
    required this.evidence,
    this.review,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 10. DAILY FIELD LOG
// ══════════════════════════════════════════════════════════════════════════

class DailyFieldLog {
  final DateTime date;
  final DateTime checkIn;
  final DateTime checkOut;
  final Duration duration;
  final double distanceTravelled;
  final List<FieldActivity> activities;

  const DailyFieldLog({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.duration,
    required this.distanceTravelled,
    required this.activities,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 11. STUDENT REPORT
// ══════════════════════════════════════════════════════════════════════════

class StudentReport {
  final String id;
  final String title;
  final DateTime submittedOn;
  final ReportStatus status;
  final String downloadUrl;

  const StudentReport({
    required this.id,
    required this.title,
    required this.submittedOn,
    required this.status,
    required this.downloadUrl,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 12. TIMELINE EVENT
// ══════════════════════════════════════════════════════════════════════════

class TimelineEvent {
  final DateTime time;
  final TimelineType type;
  final String title;
  final String description;

  const TimelineEvent({
    required this.time,
    required this.type,
    required this.title,
    required this.description,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 13. NOTIFICATION
// ══════════════════════════════════════════════════════════════════════════

class StudentNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final NotificationType type;

  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
    required this.type,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 14. STUDENT ANALYTICS
// ══════════════════════════════════════════════════════════════════════════

class StudentAnalytics {
  final double completionRate;
  final double attendanceRate;
  final double reviewScore;
  final double averageActivitiesPerDay;
  final double averageTimeInField;
  final double gpsCompliance;

  const StudentAnalytics({
    required this.completionRate,
    required this.attendanceRate,
    required this.reviewScore,
    required this.averageActivitiesPerDay,
    required this.averageTimeInField,
    required this.gpsCompliance,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 15. STUDENT PERMISSIONS
// ══════════════════════════════════════════════════════════════════════════

class StudentPermissions {
  final bool canSubmit;
  final bool canCheckIn;
  final bool canCheckOut;
  final bool canUploadEvidence;
  final bool canEditActivities;

  const StudentPermissions({
    required this.canSubmit,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.canUploadEvidence,
    required this.canEditActivities,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// MASTER MODEL: STUDENT DATA (Backward Compatible)
// ══════════════════════════════════════════════════════════════════════════
// This keeps the flat fields that existing code uses, plus the rich sub-models

class StudentData {
  // ── Flat fields (backward compatible with existing code) ─────────────
  final String id;
  final String name;
  final String avatarUrl;
  final String reg;
  final String programme;
  final String topic;
  final String status;       // maps to fieldStatus string
  final String checkInStatus;
  final String lastActivity;

  // ── Rich sub-models (new) ────────────────────────────────────────────
  final PersonalInfo personalInfo;
  final AcademicInfo academicInfo;
  final AccountStatus accountStatus;
  final FieldStatus fieldStatus;
  final CurrentFieldSession? currentSession;
  final StudentStatistics statistics;
  final StudentAnalytics analytics;
  final StudentPermissions permissions;
  final List<FieldActivity> activities;
  final List<DailyFieldLog> dailyLogs;
  final List<EvidenceFile> evidence;
  final List<StudentReport> reports;
  final List<SupervisorReview> reviews;
  final List<StudentNotification> notifications;
  final List<TimelineEvent> timeline;
  final List<GPSLocation> gpsHistory;

  // ── Primary constructor (all fields) ─────────────────────────────────
  StudentData({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.reg,
    required this.programme,
    required this.topic,
    required this.status,
    required this.checkInStatus,
    required this.lastActivity,
    PersonalInfo? personalInfo,
    AcademicInfo? academicInfo,
    AccountStatus? accountStatus,
    this.fieldStatus = FieldStatus.inField,
    this.currentSession,
    StudentStatistics? statistics,
    StudentAnalytics? analytics,
    StudentPermissions? permissions,
    List<FieldActivity>? activities,
    List<DailyFieldLog>? dailyLogs,
    List<EvidenceFile>? evidence,
    List<StudentReport>? reports,
    List<SupervisorReview>? reviews,
    List<StudentNotification>? notifications,
    List<TimelineEvent>? timeline,
    List<GPSLocation>? gpsHistory,
  })  : personalInfo = personalInfo ??
            PersonalInfo(
              id: id,
              avatarUrl: avatarUrl,
              firstName: name.split(' ').first,
              lastName: name.split(' ').last,
              fullName: name,
              email: '',
              phone: '',
              dateJoined: DateTime.now(),
            ),
        academicInfo = academicInfo ??
            AcademicInfo(
              regNo: reg,
              programme: programme,
              department: '',
              faculty: '',
              university: '',
              yearOfStudy: 1,
              researchTopic: topic,
              researchCategory: '',
              supervisorId: '',
              supervisorName: '',
            ),
        accountStatus = accountStatus ??
            AccountStatus(
              active: true,
              accountVerified: true,
              profileCompleted: true,
              locationEnabled: true,
              notificationsEnabled: true,
            ),
        statistics = statistics ??
            StudentStatistics(
              totalFieldDays: 0,
              totalActivities: 0,
              totalReports: 0,
              totalEvidence: 0,
              totalImages: 0,
              totalVideos: 0,
              totalDocuments: 0,
              totalDistanceTravelled: 0,
              totalTimeInField: Duration.zero,
              firstCheckIn: DateTime.now(),
              lastCheckOut: DateTime.now(),
              averageGPSAccuracy: 0,
            ),
        analytics = analytics ??
            StudentAnalytics(
              completionRate: 0,
              attendanceRate: 0,
              reviewScore: 0,
              averageActivitiesPerDay: 0,
              averageTimeInField: 0,
              gpsCompliance: 0,
            ),
        permissions = permissions ??
            StudentPermissions(
              canSubmit: true,
              canCheckIn: true,
              canCheckOut: true,
              canUploadEvidence: true,
              canEditActivities: true,
            ),
        activities = activities ?? [],
        dailyLogs = dailyLogs ?? [],
        evidence = evidence ?? [],
        reports = reports ?? [],
        reviews = reviews ?? [],
        notifications = notifications ?? [],
        timeline = timeline ?? [],
        gpsHistory = gpsHistory ?? [];

  // ── Convenience factory for flat-constructor code ────────────────────
  factory StudentData.flat({
    required String id,
    required String name,
    required String avatarUrl,
    required String reg,
    required String programme,
    required String topic,
    required String status,
    required String checkInStatus,
    required String lastActivity,
  }) {
    return StudentData(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      reg: reg,
      programme: programme,
      topic: topic,
      status: status,
      checkInStatus: checkInStatus,
      lastActivity: lastActivity,
    );
  }

  /// Returns a Map representation for passing via GoRouter `extra`
  Map<String, String> toMap() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'reg': reg,
    'programme': programme,
    'topic': topic,
    'status': status,
    'checkInStatus': checkInStatus,
    'lastActivity': lastActivity,
  };

  /// Creates a StudentData from a Map (e.g., from GoRouter `extra`)
  factory StudentData.fromMap(Map<String, String> map) => StudentData.flat(
    id: map['id'] ?? '',
    name: map['name'] ?? 'Unknown',
    avatarUrl: map['avatarUrl'] ?? '',
    reg: map['reg'] ?? '',
    programme: map['programme'] ?? '',
    topic: map['topic'] ?? '',
    status: map['status'] ?? '',
    checkInStatus: map['checkInStatus'] ?? '',
    lastActivity: map['lastActivity'] ?? '',
  );

  /// Sample data matching the students list
  static const List<StudentData> sampleStudents = [
    // Using .flat() isn't const-compatible; use default constructor with flat fields
  ];

  /// Get sample students as a List
  static List<StudentData> get samples => _buildSamples();

  static List<StudentData> _buildSamples() => [
    StudentData.flat(
      id: '1',
      name: 'Jane Akinyi',
      avatarUrl:
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42442/22',
      programme: 'Msc Geography',
      topic: 'Mangrove Ecosystem...',
      status: 'In Field',
      checkInStatus: 'Checked In',
      lastActivity: '10:42 AM',
    ),
    StudentData.flat(
      id: '2',
      name: 'Brian Okoth',
      avatarUrl:
          'https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42442/22',
      programme: 'PHD Env.Science',
      topic: 'Water quality Assess..',
      status: 'In Field',
      checkInStatus: 'Checked In',
      lastActivity: '09:15 AM',
    ),
    StudentData.flat(
      id: '3',
      name: 'Alice Wambui',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42443/22',
      programme: 'Msc Geography',
      topic: 'Coastal Erosion Study..',
      status: 'Checked Out',
      checkInStatus: 'Checked Out',
      lastActivity: '10:42 AM',
    ),
    StudentData.flat(
      id: '4',
      name: 'David Ochieng',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42444/22',
      programme: 'Msc Geography',
      topic: 'Land Use Change...',
      status: 'In Field',
      checkInStatus: 'Checked In',
      lastActivity: '10:42 AM',
    ),
    StudentData.flat(
      id: '5',
      name: 'Eve Mutua',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42445/22',
      programme: 'Msc Geography',
      topic: 'GIS Based Flood..',
      status: 'In Field',
      checkInStatus: 'Checked In',
      lastActivity: 'Yesterday',
    ),
    StudentData.flat(
      id: '6',
      name: 'Zack Kipkorir',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      reg: 'MB21/PU/42448/22',
      programme: 'Msc Geography',
      topic: 'Soil Fertility Mapping...',
      status: 'Not Checked in',
      checkInStatus: '—',
      lastActivity: '—',
    ),
  ];

  /// Lookup a student by ID from sample data
  static StudentData? getById(String id) {
    try {
      return samples.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

