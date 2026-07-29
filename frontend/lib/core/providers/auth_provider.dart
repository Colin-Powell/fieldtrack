import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

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
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final studentProf = json['studentProfile'] as Map<String, dynamic>?;
    final supervisorUser = studentProf?['supervisor']?['user'] as Map<String, dynamic>?;
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
      phone: studentProf?['phone'],
      topic: studentProf?['topic'],
      supervisorName: supervisorUser?['name'],
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

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  // Restore session using the stored token and GET /api/v1/auth/me
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _secureStorage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final response = await _apiClient.dio.get('/auth/me');
      final user = AuthUser.fromJson(response.data['user']);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } on DioException catch (e) {
      await _secureStorage.delete(key: 'jwt_token');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.response?.data?['error'] ?? 'Session expired',
      );
    }
  }

  // Login handler
  Future<bool> login({String? email, String? registrationNo, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        if (email != null) 'email': email,
        if (registrationNo != null) 'registrationNo': registrationNo,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final refreshToken = response.data['refreshToken'];
        final userJson = response.data['user'];
        
        final user = AuthUser.fromJson(userJson);

        await _secureStorage.write(key: 'jwt_token', value: token);
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error'] ?? 'Login failed',
        );
        return false;
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = 'Login failed: ${e.message}';
      if (errorData is Map<String, dynamic> && errorData['error'] != null) {
        errorMsg = errorData['error'];
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  // Logout handler
  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'refresh_token');
    state = state.copyWith(
      isAuthenticated: false,
      user: null,
      error: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
