import '../../domain/entities/store_catalog.dart';
import 'store_catalog_line_model.dart';

/// Maps the store-level coverage returned by `GET /stores/me/coverage`.
class StoreCatalogModel extends StoreCatalog {
  const StoreCatalogModel({
    required super.servesAllBrands,
    super.brands = const [],
    super.sparePartsTypes = const [],
    super.subcategories = const [],
  });

  factory StoreCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'] as List<dynamic>? ?? const [];
    final rawTypes = json['sparePartsTypes'] as List<dynamic>? ?? const [];
    final rawSubcategories = json['subcategories'];
    if (rawSubcategories is! List) {
      throw const FormatException('Invalid store coverage subcategories');
    }

    return StoreCatalogModel(
      servesAllBrands: json['servesAllBrands'] as bool? ?? false,
      brands: rawBrands
          .map((brand) =>
              brand is Map ? brand['name'].toString() : brand.toString())
          .toList(growable: false),
      sparePartsTypes:
          rawTypes.map((type) => type.toString()).toList(growable: false),
      subcategories: rawSubcategories
          .map(
            (subcategory) => StoreCatalogLineModel.fromJson(
              Map<String, dynamic>.from(subcategory as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
