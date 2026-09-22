import '../../domain/entities/category_node.dart';

/// Data model for a category tree node with recursive JSON deserialization.
class CategoryNodeModel extends CategoryNode {
  const CategoryNodeModel({
    required super.id,
    required super.name,
    super.parentId,
    super.isCatchAll,
    super.children,
  });

  factory CategoryNodeModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = (rawChildren is List)
        ? rawChildren
            .map((c) => CategoryNodeModel.fromJson(c as Map<String, dynamic>))
            .toList()
        : <CategoryNodeModel>[];

    return CategoryNodeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      isCatchAll:
          json['isCatchAll'] as bool? ?? json['is_catch_all'] as bool? ?? false,
      children: children,
    );
  }
}
