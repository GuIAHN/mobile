import 'package:equatable/equatable.dart';
import 'category_node.dart';

/// Value object returned by [SearchCategoriesUseCase].
/// Contains the matching node and its full path from the root.
class CategorySearchResult extends Equatable {
  /// The matching category node.
  final CategoryNode node;

  /// Full path from root to this node, e.g. ['Frenos', 'Disco y Pastillas', 'Pastillas cerámicas'].
  /// Useful for rendering breadcrumbs in the UI.
  final List<String> breadcrumb;

  const CategorySearchResult({
    required this.node,
    required this.breadcrumb,
  });

  /// Human-readable breadcrumb string, e.g. "Frenos / Pastillas".
  /// Excludes the node's own name (already shown as the primary label).
  String get breadcrumbLabel {
    if (breadcrumb.length <= 1) return '';
    return breadcrumb.sublist(0, breadcrumb.length - 1).join(' / ');
  }

  @override
  List<Object?> get props => [node, breadcrumb];
}
