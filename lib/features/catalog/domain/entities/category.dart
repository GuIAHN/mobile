import 'package:equatable/equatable.dart';

/// Pure domain entity representing a spare parts category.
class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;

  /// See [CategoryNode.isCatchAll]. Carried here so a selection made in the
  /// wizard keeps knowing it is the "no sé cuál exactamente" option, without
  /// re-deriving it from a hardcoded id or from the category's name.
  final bool isCatchAll;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.isCatchAll = false,
  });

  @override
  List<Object?> get props => [id, name, parentId, isCatchAll];
}
