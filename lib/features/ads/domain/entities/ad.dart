import 'package:equatable/equatable.dart';

class Ad extends Equatable {
  final String id;
  final String brandName;
  final String type;
  final String title;
  final String? description;
  final String mediaUrl;
  final String? ctaUrl;
  final String? ctaLabel;

  const Ad({
    required this.id,
    required this.brandName,
    required this.type,
    required this.title,
    this.description,
    required this.mediaUrl,
    this.ctaUrl,
    this.ctaLabel,
  });

  @override
  List<Object?> get props => [
        id,
        brandName,
        type,
        title,
        description,
        mediaUrl,
        ctaUrl,
        ctaLabel,
      ];
}
