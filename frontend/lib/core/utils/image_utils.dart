import '../constants/app_constants.dart';

class ImageUtils {
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    
    // Convert gs:// bucket URLs to HTTPS download URLs
    if (path.startsWith('gs://')) {
      final uri = Uri.parse(path);
      final bucket = uri.authority;
      final filePath = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      final encodedPath = Uri.encodeComponent(filePath);
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
    }

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
