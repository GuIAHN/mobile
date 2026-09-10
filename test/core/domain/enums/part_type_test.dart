import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/part_type.dart';

void main() {
  test('exposes USED as a selectable spare-part type', () {
    final used = PartType.values.singleWhere(
      (type) => type.apiValue == 'USED',
    );

    expect(used.label, 'Usado');
    expect(used.description, 'Repuesto previamente utilizado');
  });

  test('presents every backend spare-part type in Spanish', () {
    const expectedLabels = {
      'PERFORMANCE': 'Alto rendimiento',
      'ORIGINAL': 'OEM',
      'GENERIC': 'Genérico',
      'USED': 'Usado',
    };

    for (final entry in expectedLabels.entries) {
      expect(partTypeLabelFromApi(entry.key), entry.value);
    }
    expect(partTypeLabelFromApi('FUTURE_TYPE'), 'FUTURE_TYPE');
  });
}
