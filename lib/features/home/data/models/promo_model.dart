import '../../domain/entities/promo.dart';

class PromoModel extends Promo {
  const PromoModel({
    required super.title,
    required super.subtitle,
    required super.iconName,
    required super.gradientColors,
    super.imageUrl,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconName: json['iconName'] as String,
      gradientColors: List<int>.from(json['gradientColors'] as List),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'iconName': iconName,
        'gradientColors': gradientColors,
        'imageUrl': imageUrl,
      };
}
