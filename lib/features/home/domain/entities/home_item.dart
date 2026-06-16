import 'package:equatable/equatable.dart';
import 'service_type.dart';

class HomeItem extends Equatable {
  final String name;
  final String detail;
  final double rating;
  final int reviews;
  final double distanceKm;
  final bool isOpen;
  final String iconName;
  final ServiceType type;
  final List<int>? gradientColors;

  const HomeItem({
    required this.name,
    required this.detail,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.isOpen,
    required this.iconName,
    required this.type,
    this.gradientColors,
  });

  @override
  List<Object?> get props => [
        name,
        detail,
        rating,
        reviews,
        distanceKm,
        isOpen,
        iconName,
        type,
        gradientColors,
      ];
}
