/// A server page. A missing total falls back to probing the next full page.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.counts = const {},
    this.page = 1,
    this.pageSize = 20,
    this.total,
  });

  final List<T> items;
  final Map<String, int> counts;
  final int page;
  final int pageSize;
  final int? total;

  bool get hasMore =>
      items.isNotEmpty &&
      (total != null ? page * pageSize < total! : items.length >= pageSize);
}
