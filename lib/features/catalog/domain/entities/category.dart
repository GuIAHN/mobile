import 'package:equatable/equatable.dart';

/// Pure domain entity representing a spare parts category.
class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, parentId];
}
