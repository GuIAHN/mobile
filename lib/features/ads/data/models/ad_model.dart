import '../../domain/entities/ad.dart';

class AdModel extends Ad {
  const AdModel({
    required super.id,
    required super.brandName,
    required super.type,
    required super.title,
    super.description,
    required super.mediaUrl,
    super.ctaUrl,
    super.ctaLabel,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String,
      brandName: json['brandName'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaUrl: json['mediaUrl'] as String,
      ctaUrl: json['ctaUrl'] as String?,
      ctaLabel: json['ctaLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'type': type,
      'title': title,
      if (description != null) 'description': description,
      'mediaUrl': mediaUrl,
      if (ctaUrl != null) 'ctaUrl': ctaUrl,
      if (ctaLabel != null) 'ctaLabel': ctaLabel,
    };
  }
}
