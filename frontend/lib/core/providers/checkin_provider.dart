import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/error_handler.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import '../utils/toast_service.dart';

class CheckInState {
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final String? sessionId;
  // ignore: unnecessary_question_mark
  final bool? _isLoading;

  /// Safe getter — returns false even if object was created before isLoading existed.
  bool get isLoading => _isLoading ?? false;

  CheckInState({
    required this.isCheckedIn,
    this.checkInTime,
    this.sessionId,
    bool isLoading = false,
  }) : _isLoading = isLoading;

  CheckInState copyWith({
    bool? isCheckedIn,
    DateTime? checkInTime,
    String? sessionId,
    bool? isLoading,
  }) {
    return CheckInState(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CheckInNotifier extends StateNotifier<CheckInState> {
  final Ref _ref;
  final ApiClient _apiClient = ApiClient();

  CheckInNotifier(this._ref) : super(CheckInState(isCheckedIn: false)) {
    _fetchActiveSession();
  }

  Future<void> _fetchActiveSession() async {
    final user = _ref.read(authProvider).user;
    if (user == null || user.role != 'STUDENT') return;

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.sessionActive,
        queryParameters: {'studentId': user.id},
      );
      if (response.data['session'] != null) {
        state = state.copyWith(
          isCheckedIn: true,
          checkInTime: DateTime.parse(response.data['session']['checkInTime']),
          sessionId: response.data['session']['id'],
        );
      }
    } catch (e) {
      // Ignore the session lookup failure and fall back to the default state.
    }
  }

  Future<bool> checkIn() async {
    final user = _ref.read(authProvider).user;
    final location = _ref.read(locationProvider);

    if (user == null) {
      ToastService.showError('User not authenticated');
      return false;
    }

    if (location.isLocating || location.latitude == 0.0) {
      ToastService.showError('Waiting for GPS location. Please try again.');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sessionCheckIn,
        data: {
          'studentId': user.id,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
      );

      state = state.copyWith(
        isCheckedIn: true,
        checkInTime: DateTime.now(),
        sessionId: response.data['id'],
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastService.showError('An unexpected error occurred');
      return false;
    }
  }

  Future<bool> checkOut() async {
    final user = _ref.read(authProvider).user;
    final location = _ref.read(locationProvider);

    if (user == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      await _apiClient.dio.patch(
        ApiEndpoints.sessionCheckOut,
        data: {
          'studentId': user.id,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
      );

      state = CheckInState(
        isCheckedIn: false,
        checkInTime: null,
        sessionId: null,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastService.showError('An unexpected error occurred');
      return false;
    }
  }
}

final checkInProvider = StateNotifierProvider<CheckInNotifier, CheckInState>((
  ref,
) {
  return CheckInNotifier(ref);
});
