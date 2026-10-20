import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider detail UI does not import other features', () {
    final entries = [
      File(
          'lib/features/home/presentation/widgets/service_provider_detail_view.dart'),
      File('lib/features/home/presentation/pages/mechanic_detail_page.dart'),
      File('lib/features/home/presentation/pages/store_detail_page.dart'),
    ];
    final visited = <String>{};
    final violations = <String>[];

    void inspect(File file) {
      final uri = file.absolute.uri.normalizePath();
      if (!visited.add(uri.path)) return;
      for (final match in RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
          .allMatches(file.readAsStringSync())) {
        final path = match.group(1)!;
        final target = path.startsWith('package:guiautomotriz_mobile/')
            ? Directory('lib')
                .absolute
                .uri
                .resolve(path.substring('package:guiautomotriz_mobile/'.length))
            : uri.resolve(path);
        final segments = target.pathSegments;
        final index = segments.indexOf('features');
        if (index >= 0 && segments[index + 1] != 'home') {
          violations.add('${file.path}: $path');
        } else if (target.scheme == 'file' &&
            (target.path.contains('/features/home/presentation/widgets/') ||
                target.path.contains('/shared/provider_feedback/'))) {
          inspect(File.fromUri(target));
        }
      }
    }

    for (final file in entries) {
      inspect(file);
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('shared provider feedback contract does not depend on features', () {
    final root = Directory('lib/shared/provider_feedback');
    expect(root.existsSync(), isTrue,
        reason:
            'Provider feedback must be composed through a shared contract.');
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
          .allMatches(file.readAsStringSync())) {
        final path = match.group(1)!;
        final target = path.startsWith('package:guiautomotriz_mobile/')
            ? Directory('lib')
                .absolute
                .uri
                .resolve(path.substring('package:guiautomotriz_mobile/'.length))
            : file.absolute.uri.resolve(path);
        expect(target.pathSegments, isNot(contains('features')),
            reason: '${file.path} must not hide a dependency on $path');
      }
    }
  });
}
