import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/error_handler.dart';
import '../services/notification_service.dart';

// Represents the authenticated user
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;
  final String? programme;
  final String? department;
  final String? faculty;
  final String? registrationNo;
  final String? phone;
  final String? topic;
  final String? supervisorName;

  // Supervisor specific
  final String? staffNumber;
  final String? supervisorDepartment;
  final String? specialization;
  final String? office;
  final int? studentCapacity;
  final String? avatarUrl;

  static String? _extractAvatarUrl(Map<String, dynamic>? payload) {
    if (payload == null) return null;

    for (final key in [
      'avatar',
      'avatarUrl',
      'profileImage',
      'profileImageUrl',
    ]) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mustChangePassword = false,
    this.programme,
    this.department,
    this.faculty,
    this.registrationNo,
    this.phone,
    this.topic,
    this.supervisorName,
    this.staffNumber,
    this.supervisorDepartment,
    this.specialization,
    this.office,
    this.studentCapacity,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final studentProf = json['studentProfile'] as Map<String, dynamic>?;
    final supervisorUser =
        studentProf?['supervisor']?['user'] as Map<String, dynamic>?;
    final supervisorProf = json['supervisorProfile'] as Map<String, dynamic>?;
    final avatarUrl =
        _extractAvatarUrl(json) ??
        _extractAvatarUrl(studentProf) ??
        _extractAvatarUrl(supervisorProf);

    return AuthUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      mustChangePassword: json['mustChangePassword'] ?? false,
      programme: studentProf?['programme'],
      department: studentProf?['department'],
      faculty: studentProf?['faculty'],
      registrationNo: studentProf?['registrationNo'],
      phone: studentProf?['phone'] ?? supervisorProf?['phone'],
      topic: studentProf?['topic'],
      supervisorName: supervisorUser?['name'],
      staffNumber: supervisorProf?['staffNumber'],
      supervisorDepartment: supervisorProf?['department'],
      specialization: supervisorProf?['specialization'],
      office: supervisorProf?['office'],
      studentCapacity: supervisorProf?['studentCapacity'],
      avatarUrl: avatarUrl,
    );
  }
}

// Represents the overall authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AuthUser? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthUser? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer? _profilePollingTimer;

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  @override
  void dispose() {
    _profilePollingTimer?.cancel();
    super.dispose();
  }

  void _startProfilePolling() {
    // Polling disabled as per user request to avoid flickering and jumping.
  }

  void _stopProfilePolling() {
    // Polling disabled as per user request to avoid flickering and jumping.
  }

  // Restore session using the stored token and GET /api/v1/auth/me
  Future<void> checkAuthStatus({bool isPolling = false}) async {
    if (!isPolling) {
      state = state.copyWith(isLoading: true);
    }
    final token = await _secureStorage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      if (!isPolling) {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
      _stopProfilePolling();
      return;
    }

    try {
      final response = await _apiClient.dio.get('/auth/me');
      final userJson = response.data['user'];
      final user = AuthUser.fromJson(userJson);
      
      await _secureStorage.write(key: 'cached_user', value: jsonEncode(userJson));

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await NotificationService().syncTokenWithBackend(
            fcmToken,
            force: true,
            auth: true,
          );
        }
      } catch (e) {
        debugPrint('FCM getToken failed: $e');
      }

      if (!isPolling) {
        _startProfilePolling();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError || e.type == DioExceptionType.receiveTimeout) {
        // Offline: Try to load from cache
        final cachedUserStr = await _secureStorage.read(key: 'cached_user');
        if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
          final user = AuthUser.fromJson(jsonDecode(cachedUserStr));
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
          return;
        }
      }

      await _secureStorage.delete(key: 'jwt_token');
      await _secureStorage.delete(key: 'cached_user');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      _stopProfilePolling();
    }
  }

  // Login handler
  Future<bool> login({
    String? email,
    String? registrationNo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = <String, dynamic>{'password': password};
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim();
      }
      if (registrationNo != null && registrationNo.trim().isNotEmpty) {
        data['registrationNo'] = registrationNo.trim();
      }

      final response = await _apiClient.dio.post('/auth/login', data: data);

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final refreshToken = response.data['refreshToken'];
        final userJson = response.data['user'];

        final user = AuthUser.fromJson(userJson);

        await _secureStorage.write(key: 'jwt_token', value: token);
        await _secureStorage.write(key: 'cached_user', value: jsonEncode(userJson));
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );

        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await NotificationService().syncTokenWithBackend(
              fcmToken,
              force: true,
              auth: true,
            );
          }
        } catch (e) {
          debugPrint('FCM getToken failed on login: $e');
        }

        await checkAuthStatus(isPolling: false);
        _startProfilePolling();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: ErrorHandler.getFriendlyErrorMessage(response.data),
        );
        return false;
      }
    } on DioException catch (e) {
      final errorMsg = ErrorHandler.getFriendlyErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${ErrorHandler.getFriendlyErrorMessage(e)}',
      );
      return false;
    }
  }

  // Avatar Upload Handler
  Future<bool> uploadAvatar(File imageFile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.avatarUpload,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Fetch fresh profile to get the new avatarUrl
        await checkAuthStatus(isPolling: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload avatar',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Upload failed: ${ErrorHandler.getFriendlyErrorMessage(e)}',
      );
      return false;
    }
  }

  // Update profile (email + phone)
  Future<bool> updateProfile({
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.dio.patch(
        '/settings/profile',
        data: {'email': email, 'phone': phone},
      );
      // Refresh the auth state so the UI reflects new data
      await checkAuthStatus(isPolling: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  // Logout handler
  Future<void> logout() async {
    _stopProfilePolling();
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'refresh_token');
    state = state.copyWith(isAuthenticated: false, user: null, error: null);
  }

  // Forgot Password API Calls
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      state = state.copyWith(isLoading: false);
      return response.data['success'] == true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Request failed');
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      if (response.data['success'] == true) {
        final token = response.data['token'];
        await _secureStorage.write(
          key: 'jwt_token',
          value: token,
        ); // Store temp token for reset
        state = state.copyWith(isLoading: false);
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/auth/reset-password',
        data: {'newPassword': newPassword},
      );
      if (response.data['success'] == true) {
        state = state.copyWith(isLoading: false);
        // Clear temp token so they have to log in normally
        await _secureStorage.delete(key: 'jwt_token');
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Reset failed');
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
