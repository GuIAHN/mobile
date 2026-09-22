import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat does not render legacy bottom snackbars', () {
    final chatFiles = Directory('lib/features/chat')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final contactActionsFile = File(
      'lib/features/home/presentation/widgets/provider_detail_widgets.dart',
    );
    final offenders = [...chatFiles, contactActionsFile]
        .where((file) {
          final source = file.readAsStringSync();
          return source.contains('ScaffoldMessenger') ||
              RegExp(r'\bSnackBar\s*\(').hasMatch(source);
        })
        .map((file) => file.path)
        .toList()
      ..sort();

    expect(
      offenders,
      isEmpty,
      reason: 'Chat feedback must use the app notification host instead of '
          'legacy bottom SnackBars.',
    );
  });
}
