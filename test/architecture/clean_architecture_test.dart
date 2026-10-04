import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final featureRoot = Directory('lib/features');

  test('domain stays independent from Flutter, HTTP, JSON and other features',
      () {
    final violations = <String>[];
    for (final feature in featureRoot.listSync().whereType<Directory>()) {
      final domain = Directory('${feature.path}/domain');
      if (!domain.existsSync()) continue;
      final featureName =
          feature.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
      for (final file in domain.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();
        if (source.contains("package:flutter") ||
            source.contains("package:dio") ||
            source.contains('fromJson(') ||
            source.contains('toJson(')) {
          violations.add('${file.path}: infrastructure concern in domain');
        }
        for (final match
            in RegExp(r'''import\s+['"]([^'"]+)['"]''').allMatches(source)) {
          final import = match.group(1)!;
          final target = File('${file.parent.path}/$import').absolute;
          final segments = target.uri.normalizePath().pathSegments;
          final featuresIndex = segments.indexOf('features');
          if (featuresIndex < 0 || featuresIndex + 1 >= segments.length) {
            continue;
          }
          final importedFeature = segments[featuresIndex + 1];
          if (importedFeature != featureName) {
            violations.add(
              '${file.path}: domain imports feature $importedFeature',
            );
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('press feedback has one shared implementation', () {
    final declarations = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => RegExp(r'class\s+_?PressableScale\b')
            .hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(declarations, ['lib/shared/widgets/pressable_scale.dart']);
  });
}
