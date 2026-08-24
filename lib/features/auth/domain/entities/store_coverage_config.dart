import 'package:equatable/equatable.dart';

/// Complete store-wide coverage sent during registration and replacement.
class StoreCoverageConfig extends Equatable {
  const StoreCoverageConfig({
    required this.servesAllBrands,
    required this.brandIds,
    required this.sparePartsTypes,
    required this.subcategoryIds,
  });

  final bool servesAllBrands;
  final List<String> brandIds;
  final List<String> sparePartsTypes;
  final List<String> subcategoryIds;

  @override
  List<Object?> get props => [
        servesAllBrands,
        brandIds,
        sparePartsTypes,
        subcategoryIds,
      ];
}
