import '../../domain/entities/store_catalog_line.dart';

/// Data model for [StoreCatalogLine] with JSON support.
/// Parses the response of `GET /stores/me/categories`.
class StoreCatalogLineModel extends StoreCatalogLine {
  const StoreCatalogLineModel({
    required super.id,
    required super.categoryName,
    super.startingPrice,
    required super.servesAllBrands,
    super.brands = const [],
    super.sparePartsTypes = const [],
  });

  factory StoreCatalogLineModel.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'] as List<dynamic>? ?? const [];
    final rawTypes = json['sparePartsTypes'] as List<dynamic>? ?? const [];
    final rawPrice = json['startingPrice'];

    return StoreCatalogLineModel(
      id: json['id'] as String,
      categoryName: json['categoryName']?.toString() ?? 'Categoría',
      startingPrice: rawPrice == null
          ? null
          : (rawPrice as num).toDouble(),
      servesAllBrands: json['servesAllBrands'] as bool? ?? false,
      brands: rawBrands
          .map((b) => b is Map ? b['name'].toString() : b.toString())
          .toList(growable: false),
      sparePartsTypes:
          rawTypes.map((t) => t.toString()).toList(growable: false),
    );
  }
}
