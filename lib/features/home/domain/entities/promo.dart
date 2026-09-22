import 'package:equatable/equatable.dart';

class Promo extends Equatable {
  final String title;
  final String subtitle;
  final String iconName;
  final List<int> gradientColors;
  final String? imageUrl;
  final String? ctaUrl;
  final String? id;

  const Promo({
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.gradientColors,
    this.imageUrl,
    this.ctaUrl,
    this.id,
  });

  @override
  List<Object?> get props => [title, subtitle, iconName, gradientColors, imageUrl, ctaUrl, id];
}
