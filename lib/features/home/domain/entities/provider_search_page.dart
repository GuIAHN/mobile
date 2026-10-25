import 'home_item.dart';

/// A page from the directory, including the server's pagination metadata.
class ProviderSearchPage {
  final List<HomeItem> items;
  final int? total;
  final int page;
  final int pageSize;

  const ProviderSearchPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore =>
      items.isNotEmpty &&
      (total != null ? page * pageSize < total! : items.length >= pageSize);
}
