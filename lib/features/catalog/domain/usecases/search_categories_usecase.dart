import '../../../../shared/utils/search_text_normalizer.dart';
import '../entities/category_node.dart';
import '../entities/category_search_result.dart';

/// Use case that performs an in-memory DFS search over the category tree.
///
/// The search is entirely local — no network calls per keystroke.
/// The tree must have been loaded upfront via [GetCategoryTreeUseCase].
///
/// Returns a flat list of [CategorySearchResult], each with its full breadcrumb,
/// ordered by depth-first traversal (parents before children).
class SearchCategoriesUseCase {
  const SearchCategoriesUseCase();

  /// Returns nodes whose name contains [query], ignoring case and diacritics.
  /// Requires at least [minLength] characters (default 2) to optimize performance.
  /// Returns an empty list if [query] is shorter than [minLength].
  List<CategorySearchResult> call(
    List<CategoryNode> tree,
    String query, {
    int minLength = 2,
  }) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.length < minLength) return [];
    return _search(tree, normalizedQuery, []);
  }

  List<CategorySearchResult> _search(
    List<CategoryNode> nodes,
    String query,
    List<String> path,
  ) {
    final results = <CategorySearchResult>[];
    for (final node in nodes) {
      final trail = [...path, node.name];
      if (normalizeSearchText(node.name).contains(query)) {
        results.add(CategorySearchResult(node: node, breadcrumb: trail));
      }
      // Always recurse — a child may match even when the parent doesn't.
      results.addAll(_search(node.children, query, trail));
    }
    return results;
  }
}
