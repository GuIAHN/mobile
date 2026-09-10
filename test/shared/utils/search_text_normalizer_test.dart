import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/utils/search_text_normalizer.dart';

void main() {
  test('normalizes case and common Latin diacritics for search', () {
    expect(
      normalizeSearchText('  ÁRBOL Éxito Ítem Óxido Útil Ünico  '),
      'arbol exito item oxido util unico',
    );
  });

  test('removes combining accent marks without changing ñ', () {
    expect(normalizeSearchText('Suspensio\u0301n'), 'suspension');
    expect(normalizeSearchText('Niño'), 'niño');
    expect(normalizeSearchText('Nin\u0303o'), 'niño');
    expect(normalizeSearchText('Niño'), isNot(normalizeSearchText('Nino')));
  });
}
