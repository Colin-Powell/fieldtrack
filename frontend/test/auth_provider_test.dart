import 'package:flutter_test/flutter_test.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('uses a top-level avatar when the auth payload provides one', () {
      final user = AuthUser.fromJson({
        'id': 'user-1',
        'name': 'Ada Lovelace',
        'email': 'ada@example.com',
        'role': 'STUDENT',
        'avatar': '/storage/avatars/ada.webp',
      });

      expect(user.avatarUrl, '/storage/avatars/ada.webp');
    });

    test(
      'uses the nested studentProfile avatar when no top-level avatar exists',
      () {
        final user = AuthUser.fromJson({
          'id': 'user-2',
          'name': 'Grace Hopper',
          'email': 'grace@example.com',
          'role': 'STUDENT',
          'studentProfile': {'avatar': '/storage/avatars/grace.webp'},
        });

        expect(user.avatarUrl, '/storage/avatars/grace.webp');
      },
    );
  });
}
