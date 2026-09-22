import '../../../catalog/domain/entities/category.dart';
import '../../../vehicles/domain/entities/brand.dart';

class LineaCatalogo {
  LineaCatalogo({
    required this.category,
    required this.parentCategory,
    required this.brands,
    required this.sparePartsTypes,
  });

  final Category category;
  final Category parentCategory;
  Set<Brand> brands;
  Set<String> sparePartsTypes;
}
