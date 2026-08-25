import '../../domain/entities/specialty.dart';

/// Data model for Specialties with JSON support.
class SpecialtyModel extends Specialty {
  const SpecialtyModel({
    required super.id,
    required super.name,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
