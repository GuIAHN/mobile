import 'package:equatable/equatable.dart';

class Promo extends Equatable {
  final String title;
  final String subtitle;
  final String iconName;
  final List<int> gradientColors;
  final String? imageUrl;

  const Promo({
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.gradientColors,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [title, subtitle, iconName, gradientColors, imageUrl];
}
