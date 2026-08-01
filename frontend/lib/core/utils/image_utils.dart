import '../constants/app_constants.dart';

class ImageUtils {
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    
    // Remove leading slash if it exists
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // Extract base URL (remove /api/v1)
    final baseUrl = AppConstants.apiUrl.replaceAll('/api/v1', '');
    
    // The backend serves media under the /storage route. 
    // If the DB path doesn't include it, prepend it.
    if (cleanPath.startsWith('storage/')) {
      return '$baseUrl/$cleanPath';
    } else {
      return '$baseUrl/storage/$cleanPath';
    }
  }
}
