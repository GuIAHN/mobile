import '../../domain/entities/specialty.dart';

/// API representation of an automotive specialty.
class SpecialtyModel extends Specialty {
  const SpecialtyModel({required super.id, required super.name});

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
