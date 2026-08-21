import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> initialize({required String appArea}) async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.logEvent(
      name: 'app_initialized',
      parameters: <String, Object>{'app_area': appArea},
    );
  }
}
