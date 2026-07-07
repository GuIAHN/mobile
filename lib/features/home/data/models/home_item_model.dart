import '../../domain/entities/home_item.dart';
import '../../../../core/domain/enums/service_type.dart';

class HomeItemModel extends HomeItem {
  const HomeItemModel({
    required super.name,
    required super.detail,
    required super.rating,
    required super.reviews,
    required super.distanceKm,
    required super.isOpen,
    required super.iconName,
    required super.type,
    super.gradientColors,
  });

  factory HomeItemModel.fromJson(Map<String, dynamic> json) {
    return HomeItemModel(
      name: json['name'] as String,
      detail: json['detail'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isOpen: json['isOpen'] as bool,
      iconName: json['iconName'] as String,
      type: ServiceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ServiceType.spareParts,
      ),
      gradientColors: json['gradientColors'] != null
          ? List<int>.from(json['gradientColors'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'detail': detail,
        'rating': rating,
        'reviews': reviews,
        'distanceKm': distanceKm,
        'isOpen': isOpen,
        'iconName': iconName,
        'type': type.name,
        if (gradientColors != null) 'gradientColors': gradientColors,
      };
}
