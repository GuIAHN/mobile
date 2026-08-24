import '../../domain/entities/store_catalog_line.dart';

/// Data model for [StoreCatalogLine] with JSON support.
/// Maps one subcategory from `GET /stores/me/coverage` while reusing the
/// store-wide brands and spare-part types in the existing presentation model.
class StoreCatalogLineModel extends StoreCatalogLine {
  const StoreCatalogLineModel({
    required super.id,
    required super.categoryName,
    required super.servesAllBrands,
    super.brands = const [],
    super.sparePartsTypes = const [],
  });

  factory StoreCatalogLineModel.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'] as List<dynamic>? ?? const [];
    final rawTypes = json['sparePartsTypes'] as List<dynamic>? ?? const [];

    return StoreCatalogLineModel(
      id: (json['subcategoryId'] ?? json['id']).toString(),
      categoryName:
          (json['name'] ?? json['categoryName'])?.toString() ?? 'Subcategoría',
      servesAllBrands: json['servesAllBrands'] as bool? ?? false,
      brands: rawBrands
          .map((b) => b is Map ? b['name'].toString() : b.toString())
          .toList(growable: false),
      sparePartsTypes:
          rawTypes.map((t) => t.toString()).toList(growable: false),
    );
  }
}
