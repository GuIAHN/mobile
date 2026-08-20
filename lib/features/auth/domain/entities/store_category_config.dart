import 'package:equatable/equatable.dart';

/// Store category configuration in the spare parts catalog (pure domain entity).
class StoreCategoryConfig extends Equatable {
  final String categoryId;
  final bool servesAllBrands;
  final List<String> brandIds;
  final List<String> sparePartsTypes;

  const StoreCategoryConfig({
    required this.categoryId,
    this.servesAllBrands = false,
    required this.brandIds,
    required this.sparePartsTypes,
  });

  @override
  List<Object?> get props => [
        categoryId,
        servesAllBrands,
        brandIds,
        sparePartsTypes,
      ];
}
