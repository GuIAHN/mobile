import 'package:equatable/equatable.dart';

/// Pure domain entity representing a category node in the hierarchical tree.
/// Unlike [Category], this entity includes [children] to support the full tree structure.
class CategoryNode extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
  });

  /// Whether this node is a leaf (has no children / is a subcategory).
  bool get isLeaf => children.isEmpty;

  @override
  List<Object?> get props => [id, name, parentId, children];
}
