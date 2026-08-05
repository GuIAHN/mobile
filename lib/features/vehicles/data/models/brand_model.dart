import '../../domain/entities/brand.dart';

/// Vehicle Brand data model with JSON support.
class BrandModel extends Brand {
  const BrandModel({
    required super.id,
    required super.name,
    required super.brandType,
    super.photoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brandType: json['brandType'] as String? ?? json['brand_type'] as String? ?? 'OTRO',
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brandType': brandType,
        'photoUrl': photoUrl,
      };
}
