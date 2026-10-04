import '../../domain/entities/store_catalog_line.dart';

/// Data model for one category/subcategory pair in the store coverage.
class StoreCatalogLineModel extends StoreCatalogLine {
  const StoreCatalogLineModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.subcategoryName,
  });

  factory StoreCatalogLineModel.fromJson(Map<String, dynamic> json) {
    final subcategoryId = (json['subcategoryId'] ?? json['id']).toString();
    final subcategoryName =
        (json['name'] ?? json['subcategoryName'])?.toString() ?? 'Subcategoría';

    return StoreCatalogLineModel(
      id: subcategoryId,
      categoryId: (json['categoryId'] ?? subcategoryId).toString(),
      categoryName: json['categoryName']?.toString() ?? 'Otras categorías',
      subcategoryName: subcategoryName,
    );
  }
}
