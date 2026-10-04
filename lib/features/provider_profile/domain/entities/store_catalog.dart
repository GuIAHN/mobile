import 'package:equatable/equatable.dart';

import 'store_catalog_line.dart';

/// Cobertura comercial global de una tienda.
///
/// Las marcas y los tipos de repuesto pertenecen a la tienda completa; las
/// subcategorías se conservan aparte para poder presentarlas bajo su categoría
/// principal sin repetir la cobertura global en cada fila.
class StoreCatalog extends Equatable {
  final bool servesAllBrands;
  final List<String> brands;
  final List<String> sparePartsTypes;
  final List<StoreCatalogLine> subcategories;

  const StoreCatalog({
    required this.servesAllBrands,
    this.brands = const [],
    this.sparePartsTypes = const [],
    this.subcategories = const [],
  });

  @override
  List<Object?> get props => [
        servesAllBrands,
        brands,
        sparePartsTypes,
        subcategories,
      ];
}
