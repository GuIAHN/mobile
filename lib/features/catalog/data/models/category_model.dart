import '../../domain/entities/category.dart';

/// Data model for Spare Parts Categories with JSON support.
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (parentId != null) 'parentId': parentId,
      };
}
