import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/utils/subcategory_presentation.dart';

void main() {
  test('catch-all presentation depends on the flag, not the stored name', () {
    expect(
      presentSubcategoryName(
        name: 'Nombre administrado',
        isCatchAll: true,
        audience: SubcategoryPresentationAudience.requester,
      ),
      'No sé cuál exactamente',
    );
    expect(
      presentSubcategoryName(
        name: 'Otro',
        isCatchAll: false,
        audience: SubcategoryPresentationAudience.requester,
      ),
      'Otro',
    );
  });

  test('normal subcategories keep their copy and gain the root path', () {
    expect(
      presentSubcategoryPath(
        categoryName: 'Frenos',
        subcategoryName: 'Pastillas',
        isCatchAll: false,
        audience: SubcategoryPresentationAudience.store,
      ),
      'Frenos › Pastillas',
    );
  });
}
