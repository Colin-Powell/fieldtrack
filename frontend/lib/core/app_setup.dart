import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadFrontendEnv() async {
  final candidates = <String>['.env', 'assets/.env'];

  if (!kIsWeb) {
    candidates.addAll(<String>[
      'frontend/.env',
      '../frontend/.env',
      '../../frontend/.env',
    ]);
  }

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
