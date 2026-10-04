import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/config/env.dart';

void main() {
  group('Env.resolveEnvironment', () {
    test('defaults release artifacts to production', () {
      expect(
        Env.resolveEnvironment('', isRelease: true),
        AppEnvironment.production,
      );
    });

    test('defaults non-release artifacts to development', () {
      expect(
        Env.resolveEnvironment('', isRelease: false),
        AppEnvironment.development,
      );
    });

    test('honors every explicit supported environment', () {
      expect(
        Env.resolveEnvironment('production', isRelease: false),
        AppEnvironment.production,
      );
      expect(
        Env.resolveEnvironment('staging', isRelease: true),
        AppEnvironment.staging,
      );
      expect(
        Env.resolveEnvironment('development', isRelease: true),
        AppEnvironment.development,
      );
    });
  });
}
