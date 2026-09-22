import 'package:equatable/equatable.dart';

/// Pure domain entity representing a category node in the hierarchical tree.
/// Unlike [Category], this entity includes [children] to support the full tree structure.
class CategoryNode extends Equatable {
  final String id;
  final String name;
  final String? parentId;

  /// True for the one child per root that means "I know the system, not the
  /// part" ("Frenos > Otro"). A requester picks it explicitly; a store never
  /// does - the backend derives it from the subcategories the store already
  /// covers - so store-facing pickers must hide these nodes.
  final bool isCatchAll;

  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    required this.name,
    this.parentId,
    this.isCatchAll = false,
    this.children = const [],
  });

  @override
  List<Object?> get props => [id, name, parentId, isCatchAll, children];
}
