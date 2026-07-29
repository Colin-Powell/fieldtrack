import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:fieldtrack/core/network/api_client.dart';

class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String? department;
  final String? faculty;
  final String? specialization;
  final String? office;
  final bool twoFactorEnabled;
  final bool loginAlertsEnabled;

  UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.department,
    this.faculty,
    this.specialization,
    this.office,
    this.twoFactorEnabled = false,
    this.loginAlertsEnabled = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final sup = json['supervisorProfile'] ?? {};
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: sup['phone'],
      department: sup['department'],
      faculty: sup['faculty'],
      specialization: sup['specialization'],
      office: sup['office'],
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      loginAlertsEnabled: json['loginAlertsEnabled'] ?? true,
    );
  }
}

class SettingsState {
  final bool isLoading;
  final String? error;
  final UserProfile? profile;

  SettingsState({this.isLoading = false, this.error, this.profile});

  SettingsState copyWith({bool? isLoading, String? error, UserProfile? profile}) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().dio.get('/settings/profile');
      final profile = UserProfile.fromJson(response.data['profile']);
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      String errorMessage = 'Failed to load profile';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().dio.put('/settings/profile', data: data);
      final profile = UserProfile.fromJson(response.data['profile']);
      state = state.copyWith(isLoading: false, profile: profile);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to update profile';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient().dio.put('/settings/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to update password';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> updateSecurity(bool twoFactor, bool loginAlerts) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient().dio.put('/settings/security', data: {
        'twoFactorEnabled': twoFactor,
        'loginAlertsEnabled': loginAlerts,
      });
      if (state.profile != null) {
        final newProfile = UserProfile(
          name: state.profile!.name,
          email: state.profile!.email,
          phone: state.profile!.phone,
          department: state.profile!.department,
          faculty: state.profile!.faculty,
          specialization: state.profile!.specialization,
          office: state.profile!.office,
          twoFactorEnabled: twoFactor,
          loginAlertsEnabled: loginAlerts,
        );
        state = state.copyWith(isLoading: false, profile: newProfile);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      String errorMessage = 'Failed to update security settings';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> logoutOtherSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient().dio.post('/settings/logout-others');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to log out other sessions';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> deactivateAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient().dio.delete('/settings/deactivate');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to deactivate account';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
