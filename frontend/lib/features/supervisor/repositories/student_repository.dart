import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/api_endpoints.dart';
import 'package:fieldtrack/shared/models/student_data.dart';

// ══════════════════════════════════════════════════════════════════════════
// JSON MAPPING EXTENSIONS
// ══════════════════════════════════════════════════════════════════════════
// These convert between JSON (from API) and the domain model classes.

extension PersonalInfoJson on PersonalInfo {
  Map<String, dynamic> toJson() => {
    'id': id,
    'avatarUrl': avatarUrl,
    'firstName': firstName,
    'lastName': lastName,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'dateJoined': dateJoined.toIso8601String(),
  };

  static PersonalInfo fromJson(Map<String, dynamic> json) => PersonalInfo(
    id: json['id'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    dateJoined: json['dateJoined'] != null
        ? DateTime.parse(json['dateJoined'] as String)
        : DateTime.now(),
  );
}

extension AcademicInfoJson on AcademicInfo {
  Map<String, dynamic> toJson() => {
    'regNo': regNo,
    'programme': programme,
    'department': department,
    'faculty': faculty,
    'university': university,
    'yearOfStudy': yearOfStudy,
    'researchTopic': researchTopic,
    'researchCategory': researchCategory,
    'supervisorId': supervisorId,
    'supervisorName': supervisorName,
  };

  static AcademicInfo fromJson(Map<String, dynamic> json) => AcademicInfo(
    regNo: json['regNo'] as String? ?? '',
    programme: json['programme'] as String? ?? '',
    department: json['department'] as String? ?? '',
    faculty: json['faculty'] as String? ?? '',
    university: json['university'] as String? ?? '',
    yearOfStudy: json['yearOfStudy'] as int? ?? 1,
    researchTopic: json['researchTopic'] as String? ?? '',
    researchCategory: json['researchCategory'] as String? ?? '',
    supervisorId: json['supervisorId'] as String? ?? '',
    supervisorName: json['supervisorName'] as String? ?? '',
  );
}

extension AccountStatusJson on AccountStatus {
  Map<String, dynamic> toJson() => {
    'active': active,
    'accountVerified': accountVerified,
    'profileCompleted': profileCompleted,
    'locationEnabled': locationEnabled,
    'notificationsEnabled': notificationsEnabled,
  };

  static AccountStatus fromJson(Map<String, dynamic> json) => AccountStatus(
    active: json['active'] as bool? ?? false,
    accountVerified: json['accountVerified'] as bool? ?? false,
    profileCompleted: json['profileCompleted'] as bool? ?? false,
    locationEnabled: json['locationEnabled'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
  );
}

extension CurrentFieldSessionJson on CurrentFieldSession {
  Map<String, dynamic> toJson() => {
    'active': active,
    'checkInTime': checkInTime.toIso8601String(),
    'checkOutTime': checkOutTime?.toIso8601String(),
    'duration': duration.inSeconds,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'county': county,
    'subCounty': subCounty,
    'ward': ward,
    'village': village,
  };

  static CurrentFieldSession? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return CurrentFieldSession(
      active: json['active'] as bool? ?? false,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      county: json['county'] as String? ?? '',
      subCounty: json['subCounty'] as String? ?? '',
      ward: json['ward'] as String? ?? '',
      village: json['village'] as String? ?? '',
    );
  }
}

extension StudentStatisticsJson on StudentStatistics {
  Map<String, dynamic> toJson() => {
    'totalFieldDays': totalFieldDays,
    'totalActivities': totalActivities,
    'totalReports': totalReports,
    'totalEvidence': totalEvidence,
    'totalImages': totalImages,
    'totalVideos': totalVideos,
    'totalDocuments': totalDocuments,
    'totalDistanceTravelled': totalDistanceTravelled,
    'totalTimeInField': totalTimeInField.inSeconds,
    'firstCheckIn': firstCheckIn.toIso8601String(),
    'lastCheckOut': lastCheckOut.toIso8601String(),
    'averageGPSAccuracy': averageGPSAccuracy,
  };

  static StudentStatistics fromJson(
    Map<String, dynamic> json,
  ) => StudentStatistics(
    totalFieldDays: json['totalFieldDays'] as int? ?? 0,
    totalActivities: json['totalActivities'] as int? ?? 0,
    totalReports: json['totalReports'] as int? ?? 0,
    totalEvidence: json['totalEvidence'] as int? ?? 0,
    totalImages: json['totalImages'] as int? ?? 0,
    totalVideos: json['totalVideos'] as int? ?? 0,
    totalDocuments: json['totalDocuments'] as int? ?? 0,
    totalDistanceTravelled:
        (json['totalDistanceTravelled'] as num?)?.toDouble() ?? 0,
    totalTimeInField: Duration(seconds: json['totalTimeInField'] as int? ?? 0),
    firstCheckIn: DateTime.parse(
      json['firstCheckIn'] as String? ?? DateTime.now().toIso8601String(),
    ),
    lastCheckOut: DateTime.parse(
      json['lastCheckOut'] as String? ?? DateTime.now().toIso8601String(),
    ),
    averageGPSAccuracy: (json['averageGPSAccuracy'] as num?)?.toDouble() ?? 0,
  );
}

extension GPSLocationJson on GPSLocation {
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'heading': heading,
    'speed': speed,
    'capturedAt': capturedAt.toIso8601String(),
    'address': address,
  };

  static GPSLocation fromJson(Map<String, dynamic> json) {
    // Backend LocationPing uses 'timestamp', legacy used 'capturedAt'
    final rawDate = json['timestamp'] as String? ?? json['capturedAt'] as String?;
    return GPSLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      capturedAt: rawDate != null ? DateTime.parse(rawDate) : DateTime.now(),
      address: json['address'] as String? ?? '',
    );
  }
}

extension EvidenceFileJson on EvidenceFile {
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'fileName': fileName,
    'url': url,
    'sizeMB': sizeMB,
    'uploadedAt': uploadedAt.toIso8601String(),
    'uploadedBy': uploadedBy,
  };

  static EvidenceFile fromJson(Map<String, dynamic> json) => EvidenceFile(
    id: json['id'] as String? ?? '',
    type: EvidenceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => EvidenceType.image,
    ),
    fileName: json['fileName'] as String? ?? '',
    url: json['url'] as String? ?? '',
    sizeMB: (json['sizeMB'] as num?)?.toDouble() ?? 0,
    uploadedAt: DateTime.parse(
      json['uploadedAt'] as String? ?? DateTime.now().toIso8601String(),
    ),
    uploadedBy: json['uploadedBy'] as String? ?? '',
  );
}

extension SupervisorReviewJson on SupervisorReview {
  Map<String, dynamic> toJson() => {
    'reviewerId': reviewerId,
    'reviewerName': reviewerName,
    'reviewedOn': reviewedOn.toIso8601String(),
    'rating': rating,
    'status': status.name,
    'comments': comments,
    'attachments': attachments,
  };

  static SupervisorReview fromJson(Map<String, dynamic> json) =>
      SupervisorReview(
        reviewerId: json['reviewerId'] as String? ?? '',
        reviewerName: json['reviewerName'] as String? ?? '',
        reviewedOn: DateTime.parse(
          json['reviewedOn'] as String? ?? DateTime.now().toIso8601String(),
        ),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        status: ReviewStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReviewStatus.pending,
        ),
        comments: json['comments'] as String? ?? '',
        attachments:
            (json['attachments'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

extension FieldActivityJson on FieldActivity {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inSeconds,
    'status': status.name,
    'methodology': methodology,
    'objectives': objectives,
    'findings': findings,
    'remarks': remarks,
    'location': location.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'review': review?.toJson(),
  };

  static FieldActivity fromJson(Map<String, dynamic> json) => FieldActivity(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    startTime: DateTime.parse(
      json['startTime'] as String? ?? DateTime.now().toIso8601String(),
    ),
    endTime: DateTime.parse(
      json['endTime'] as String? ?? DateTime.now().toIso8601String(),
    ),
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    status: ActivityStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ActivityStatus.draft,
    ),
    methodology: json['methodology'] as String? ?? '',
    objectives: json['objectives'] as String? ?? '',
    findings: json['findings'] as String? ?? '',
    remarks: json['remarks'] as String? ?? '',
    location: GPSLocationJson.fromJson(
      json['location'] as Map<String, dynamic>? ?? {},
    ),
    evidence:
        (json['evidence'] as List<dynamic>?)
            ?.map((e) => EvidenceFileJson.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    review: json['review'] != null
        ? SupervisorReviewJson.fromJson(json['review'] as Map<String, dynamic>)
        : null,
  );
}

extension DailyFieldLogJson on DailyFieldLog {
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut.toIso8601String(),
    'duration': duration.inSeconds,
    'distanceTravelled': distanceTravelled,
    'activities': activities.map((a) => a.toJson()).toList(),
  };

  static DailyFieldLog fromJson(Map<String, dynamic> json) => DailyFieldLog(
    date: DateTime.parse(
      json['date'] as String? ?? DateTime.now().toIso8601String(),
    ),
    checkIn: DateTime.parse(
      json['checkIn'] as String? ?? DateTime.now().toIso8601String(),
    ),
    checkOut: DateTime.parse(
      json['checkOut'] as String? ?? DateTime.now().toIso8601String(),
    ),
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    distanceTravelled: (json['distanceTravelled'] as num?)?.toDouble() ?? 0,
    activities:
        (json['activities'] as List<dynamic>?)
            ?.map((e) => FieldActivityJson.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

extension StudentReportJson on StudentReport {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'submittedOn': submittedOn.toIso8601String(),
    'status': status.name,
    'downloadUrl': downloadUrl,
  };

  static StudentReport fromJson(Map<String, dynamic> json) => StudentReport(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    submittedOn: DateTime.parse(
      json['submittedOn'] as String? ?? DateTime.now().toIso8601String(),
    ),
    status: ReportStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ReportStatus.draft,
    ),
    downloadUrl: json['downloadUrl'] as String? ?? '',
  );
}

extension TimelineEventJson on TimelineEvent {
  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'type': type.name,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
  };

  static TimelineEvent fromJson(Map<String, dynamic> json) => TimelineEvent(
    time: DateTime.parse(
      json['time'] as String? ?? DateTime.now().toIso8601String(),
    ),
    type: TimelineType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TimelineType.system,
    ),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );
}

extension StudentNotificationJson on StudentNotification {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'read': read,
    'type': type.name,
  };

  static StudentNotification fromJson(Map<String, dynamic> json) =>
      StudentNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        time: DateTime.parse(
          json['time'] as String? ?? DateTime.now().toIso8601String(),
        ),
        read: json['read'] as bool? ?? false,
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.system,
        ),
      );
}

extension StudentAnalyticsJson on StudentAnalytics {
  Map<String, dynamic> toJson() => {
    'completionRate': completionRate,
    'attendanceRate': attendanceRate,
    'reviewScore': reviewScore,
    'averageActivitiesPerDay': averageActivitiesPerDay,
    'averageTimeInField': averageTimeInField,
    'gpsCompliance': gpsCompliance,
  };

  static StudentAnalytics fromJson(Map<String, dynamic> json) =>
      StudentAnalytics(
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
        attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
        reviewScore: (json['reviewScore'] as num?)?.toDouble() ?? 0,
        averageActivitiesPerDay:
            (json['averageActivitiesPerDay'] as num?)?.toDouble() ?? 0,
        averageTimeInField:
            (json['averageTimeInField'] as num?)?.toDouble() ?? 0,
        gpsCompliance: (json['gpsCompliance'] as num?)?.toDouble() ?? 0,
      );
}

extension StudentPermissionsJson on StudentPermissions {
  Map<String, dynamic> toJson() => {
    'canSubmit': canSubmit,
    'canCheckIn': canCheckIn,
    'canCheckOut': canCheckOut,
    'canUploadEvidence': canUploadEvidence,
    'canEditActivities': canEditActivities,
  };

  static StudentPermissions fromJson(Map<String, dynamic> json) =>
      StudentPermissions(
        canSubmit: json['canSubmit'] as bool? ?? true,
        canCheckIn: json['canCheckIn'] as bool? ?? true,
        canCheckOut: json['canCheckOut'] as bool? ?? true,
        canUploadEvidence: json['canUploadEvidence'] as bool? ?? true,
        canEditActivities: json['canEditActivities'] as bool? ?? true,
      );
}

extension StudentDataJson on StudentData {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'reg': reg,
    'programme': programme,
    'topic': topic,
    'status': status,
    'checkInStatus': checkInStatus,
    'lastActivity': lastActivity,
    'personalInfo': personalInfo.toJson(),
    'academicInfo': academicInfo.toJson(),
    'accountStatus': accountStatus.toJson(),
    'fieldStatus': fieldStatus.name,
    'currentSession': currentSession?.toJson(),
    'statistics': statistics.toJson(),
    'analytics': analytics.toJson(),
    'permissions': permissions.toJson(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'dailyLogs': dailyLogs.map((l) => l.toJson()).toList(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'reports': reports.map((r) => r.toJson()).toList(),
    'reviews': reviews.map((r) => r.toJson()).toList(),
    'notifications': notifications.map((n) => n.toJson()).toList(),
    'timeline': timeline.map((t) => t.toJson()).toList(),
    'gpsHistory': gpsHistory.map((g) => g.toJson()).toList(),
  };
}

// ══════════════════════════════════════════════════════════════════════════
// STUDENT REPOSITORY
// ══════════════════════════════════════════════════════════════════════════
// Handles all student-related API calls and maps JSON responses to domain models.

class StudentRepository {
  final ApiClient _api;
  StudentRepository({ApiClient? api}) : _api = api ?? ApiClient();

  // ── Students ──────────────────────────────────────────────────────────

  /// Fetch all students under the supervisor.
  Future<List<StudentData>> fetchStudents() async {
    final response = await _api.dio.get(ApiEndpoints.students);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) {
      final map = json as Map<String, dynamic>;
      return _studentFromJson(map);
    }).toList();
  }

  /// Fetch a single student by ID with full enrichment.
  Future<StudentData> fetchStudentById(String id) async {
    final response = await _api.dio.get(ApiEndpoints.studentById(id));
    return _studentFromJson(response.data as Map<String, dynamic>);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────

  /// Dashboard summary stats
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await _api.dio.get(ApiEndpoints.dashboardStats);
    return response.data as Map<String, dynamic>;
  }

  // ── Activities ────────────────────────────────────────────────────────

  /// Fetch activities for a student.
  Future<List<FieldActivity>> fetchStudentActivities(String studentId) async {
    final response = await _api.dio.get(ApiEndpoints.studentActivities(studentId));
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => FieldActivityJson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single activity by student ID and activity ID.
  Future<FieldActivity> fetchStudentActivity(
    String studentId,
    String activityId,
  ) async {
    final response = await _api.dio.get(
      ApiEndpoints.studentActivity(studentId, activityId),
    );
    return FieldActivityJson.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Daily Logs ────────────────────────────────────────────────────────

  /// Fetch daily field logs for a student.
  Future<List<DailyFieldLog>> fetchStudentDailyLogs(String studentId) async {
    final response = await _api.dio.get(ApiEndpoints.studentDailyLogs(studentId));
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => DailyFieldLogJson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Evidence ──────────────────────────────────────────────────────────

  /// Fetch evidence for a specific student activity.
  Future<List<EvidenceFile>> fetchStudentEvidence(
    String studentId,
    String activityId,
  ) async {
    final response = await _api.dio.get(
      ApiEndpoints.studentEvidence(studentId, activityId),
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => EvidenceFileJson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Location / GPS ────────────────────────────────────────────────────

  /// Fetch current location for a student.
  Future<CurrentFieldSession?> fetchStudentLocation(String studentId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.studentLocation(studentId));
      return CurrentFieldSessionJson.fromJson(
        response.data as Map<String, dynamic>?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch GPS history for a student.
  Future<List<GPSLocation>> fetchStudentGpsHistory(String studentId) async {
    final response = await _api.dio.get(ApiEndpoints.studentGpsHistory(studentId));
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => GPSLocationJson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Reviews ───────────────────────────────────────────────────────────

  /// Submit a review for a student activity.
  Future<SupervisorReview> submitReview(
    String studentId,
    String activityId, {
    required String reviewerId,
    required double rating,
    required String status,
    required String comments,
  }) async {
    final response = await _api.dio.post(
      ApiEndpoints.reviewActivity,
      data: {
        'reviewerId': reviewerId,
        'activityId': activityId,
        'rating': rating,
        'status': status,
        'comments': comments,
      },
    );
    return SupervisorReviewJson.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Reports ───────────────────────────────────────────────────────────

  /// Fetch reports for a student.
  Future<List<StudentReport>> fetchStudentReports(String studentId) async {
    try {
      final response = await _api.dio.get(
        '/supervisor/students/$studentId/reports',
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => StudentReportJson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Timeline ──────────────────────────────────────────────────────────

  /// Fetch timeline events for a student.
  Future<List<TimelineEvent>> fetchStudentTimeline(String studentId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.studentTimeline(studentId));
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => TimelineEventJson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────

  /// Fetch notifications for a student.
  Future<List<StudentNotification>> fetchStudentNotifications(
    String studentId,
  ) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.studentNotifications(studentId),
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (e) => StudentNotificationJson.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Private helper ────────────────────────────────────────────────────

  /// Map a full student JSON object to a [StudentData] instance.
  StudentData _studentFromJson(Map<String, dynamic> json) {
    final personalInfo = json['personalInfo'] != null
        ? PersonalInfoJson.fromJson(
            json['personalInfo'] as Map<String, dynamic>,
          )
        : PersonalInfo(
            id: json['id'] as String? ?? '',
            avatarUrl: json['avatarUrl'] as String? ?? '',
            firstName: (json['name'] as String?)?.split(' ').first ?? '',
            lastName: (json['name'] as String?)?.split(' ').last ?? '',
            fullName: json['name'] as String? ?? '',
            email: json['email'] as String? ?? '',
            phone: json['phone'] as String? ?? '',
            dateJoined: DateTime.now(),
          );

    final academicInfo = json['academicInfo'] != null
        ? AcademicInfoJson.fromJson(
            json['academicInfo'] as Map<String, dynamic>,
          )
        : AcademicInfo(
            regNo: json['reg'] as String? ?? '',
            programme: json['programme'] as String? ?? '',
            department: json['department'] as String? ?? '',
            faculty: json['faculty'] as String? ?? '',
            university: json['university'] as String? ?? '',
            yearOfStudy: json['yearOfStudy'] as int? ?? 1,
            researchTopic: json['topic'] as String? ?? '',
            researchCategory: json['researchCategory'] as String? ?? '',
            supervisorId: json['supervisorId'] as String? ?? '',
            supervisorName: json['supervisorName'] as String? ?? '',
          );

    final fieldStatus = FieldStatus.values.firstWhere(
      (e) => e.name == json['fieldStatus'],
      orElse: () => FieldStatus.inField,
    );

    final statistics = json['statistics'] != null
        ? StudentStatisticsJson.fromJson(
            json['statistics'] as Map<String, dynamic>,
          )
        : StudentStatistics(
            totalFieldDays: json['totalFieldDays'] as int? ?? 0,
            totalActivities: json['totalActivities'] as int? ?? 0,
            totalReports: json['totalReports'] as int? ?? 0,
            totalEvidence: json['totalEvidence'] as int? ?? 0,
            totalImages: json['totalImages'] as int? ?? 0,
            totalVideos: json['totalVideos'] as int? ?? 0,
            totalDocuments: json['totalDocuments'] as int? ?? 0,
            totalDistanceTravelled:
                (json['totalDistanceTravelled'] as num?)?.toDouble() ?? 0,
            totalTimeInField: Duration.zero,
            firstCheckIn: DateTime.now(),
            lastCheckOut: DateTime.now(),
            averageGPSAccuracy: 0,
          );

    return StudentData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      reg: json['reg'] as String? ?? json['regNo'] as String? ?? '',
      programme: json['programme'] as String? ?? '',
      topic: json['topic'] as String? ?? json['researchTopic'] as String? ?? '',
      status: json['status'] as String? ?? fieldStatus.name,
      checkInStatus: json['checkInStatus'] as String? ?? '',
      lastActivity: json['lastActivity'] as String? ?? '',
      personalInfo: personalInfo,
      academicInfo: academicInfo,
      accountStatus: json['accountStatus'] != null
          ? AccountStatusJson.fromJson(
              json['accountStatus'] as Map<String, dynamic>,
            )
          : AccountStatus(
              active: true,
              accountVerified: true,
              profileCompleted: true,
              locationEnabled: true,
              notificationsEnabled: true,
            ),
      fieldStatus: fieldStatus,
      currentSession: CurrentFieldSessionJson.fromJson(
        json['currentSession'] as Map<String, dynamic>?,
      ),
      statistics: statistics,
      analytics: json['analytics'] != null
          ? StudentAnalyticsJson.fromJson(
              json['analytics'] as Map<String, dynamic>,
            )
          : StudentAnalytics(
              completionRate: 0,
              attendanceRate: 0,
              reviewScore: 0,
              averageActivitiesPerDay: 0,
              averageTimeInField: 0,
              gpsCompliance: 0,
            ),
      permissions: json['permissions'] != null
          ? StudentPermissionsJson.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : StudentPermissions(
              canSubmit: true,
              canCheckIn: true,
              canCheckOut: true,
              canUploadEvidence: true,
              canEditActivities: true,
            ),
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map(
                (e) => FieldActivityJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      dailyLogs:
          (json['dailyLogs'] as List<dynamic>?)
              ?.map(
                (e) => DailyFieldLogJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      evidence:
          (json['evidence'] as List<dynamic>?)
              ?.map((e) => EvidenceFileJson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reports:
          (json['reports'] as List<dynamic>?)
              ?.map(
                (e) => StudentReportJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map(
                (e) => SupervisorReviewJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      notifications:
          (json['notifications'] as List<dynamic>?)
              ?.map(
                (e) =>
                    StudentNotificationJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map(
                (e) => TimelineEventJson.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      gpsHistory:
          (json['gpsHistory'] as List<dynamic>?)
              ?.map((e) => GPSLocationJson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
