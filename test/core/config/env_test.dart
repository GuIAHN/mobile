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

  group('Env.resolveCartoBasemapUrl', () {
    test('keeps the base URL when the API key is absent', () {
      expect(
        Env.resolveCartoBasemapUrl(''),
        'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      );
    });

    test('adds an encoded API key to the tile URL', () {
      expect(
        Env.resolveCartoBasemapUrl(' test key+value '),
        'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png'
        '?key=test+key%2Bvalue',
      );
    });
  });
}
