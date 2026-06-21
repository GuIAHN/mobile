import 'package:equatable/equatable.dart';

/// Store category configuration in the spare parts catalog (pure domain entity).
class StoreCategoryConfig extends Equatable {
  final String categoryId;
  final double minPrice;
  final bool servesAllBrands;
  final List<String> brandIds;

  const StoreCategoryConfig({
    required this.categoryId,
    this.minPrice = 1.0,
    this.servesAllBrands = false,
    required this.brandIds,
  });

  @override
  List<Object?> get props => [categoryId, minPrice, servesAllBrands, brandIds];
}
