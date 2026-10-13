import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadFrontendEnv() async {
  // On web builds we don't bundle a .env file — the production API URL is
  // baked directly into AppConstants.apiUrl. Attempting to load it causes
  // a 403/404 because nginx correctly blocks .env files from being served.
  if (kIsWeb) return;

  final candidates = <String>[
    '.env',
    'frontend/.env',
    '../frontend/.env',
    '../../frontend/.env',
  ];

  for (final candidate in candidates) {
    try {
      await dotenv.load(fileName: candidate);
      return;
    } catch (_) {
      // Ignore and try the next candidate.
    }
  }

  // If none of the candidate paths work, do not fail on startup.
}
