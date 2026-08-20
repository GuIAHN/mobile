import 'package:equatable/equatable.dart';

/// Línea de catálogo configurada por la propia tienda: qué categoría vende,
/// para qué marcas y bajo qué tipos de repuesto (original, genérico, etc.).
class StoreCatalogLine extends Equatable {
  final String id;
  final String categoryName;
  final bool servesAllBrands;
  final List<String> brands;
  final List<String> sparePartsTypes;

  const StoreCatalogLine({
    required this.id,
    required this.categoryName,
    required this.servesAllBrands,
    this.brands = const [],
    this.sparePartsTypes = const [],
  });

  @override
  List<Object?> get props => [
        id,
        categoryName,
        servesAllBrands,
        brands,
        sparePartsTypes,
      ];
}
