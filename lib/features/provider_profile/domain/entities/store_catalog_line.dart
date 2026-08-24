import 'package:equatable/equatable.dart';

/// Subcategoría atendida por una tienda y su categoría principal.
class StoreCatalogLine extends Equatable {
  final String id;
  final String categoryId;
  final String categoryName;
  final String subcategoryName;

  const StoreCatalogLine({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryName,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        subcategoryName,
      ];
}
