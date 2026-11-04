import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/paged_result.dart';

class PagedListState<T> extends PagedResult<T> {
  const PagedListState({
    required super.items,
    super.counts,
    super.page,
    super.pageSize,
    super.total,
    required this.canLoadMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final bool canLoadMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  @override
  bool get hasMore => canLoadMore;
}

/// Shared by paged inboxes. Rebuilds invalidate pending requests, including
/// filter/session changes, refreshes, realtime revisions and disposal.
class PagedListNotifier<T, K>
    extends AutoDisposeFamilyAsyncNotifier<PagedListState<T>, K> {
  PagedListNotifier({
    required this.firstPage,
    required this.nextPage,
    required this.idOf,
    this.compare,
  });

  final Future<PagedResult<T>> Function(Ref ref, K key) firstPage;
  final Future<PagedResult<T>> Function(Ref ref, K key, int page, int pageSize)
      nextPage;
  final String Function(T item) idOf;
  final Comparator<T>? compare;
  int _generation = 0;
  bool _disposed = false;

  @override
  Future<PagedListState<T>> build(K arg) async {
    final generation = ++_generation;
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final page = await firstPage(ref, arg);
    if (_disposed || generation != _generation) {
      throw StateError('Page superseded');
    }
    return _merge(null, page);
  }

  PagedListState<T> _merge(PagedListState<T>? current, PagedResult<T> page) {
    final byId = <String, T>{
      for (final item in current?.items ?? <T>[]) idOf(item): item,
      for (final item in page.items) idOf(item): item,
    };
    final items = byId.values.toList();
    if (compare != null) items.sort(compare);
    return PagedListState(
      items: List.unmodifiable(items),
      counts: page.counts.isEmpty ? current?.counts ?? const {} : page.counts,
      page: page.page,
      pageSize: page.pageSize,
      total: page.total ?? current?.total,
      canLoadMore:
          page.hasMore && (current == null || page.page > current.page),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (_disposed ||
        state.isLoading ||
        current == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    final generation = _generation;
    PagedListState<T> retaining({bool loading = false, String? error}) =>
        PagedListState(
          items: current.items,
          counts: current.counts,
          page: current.page,
          pageSize: current.pageSize,
          total: current.total,
          canLoadMore: current.hasMore,
          isLoadingMore: loading,
          loadMoreError: error,
        );
    state = AsyncData(retaining(loading: true));
    try {
      final page = await nextPage(ref, arg, current.page + 1, current.pageSize);
      if (_disposed || generation != _generation) return;
      state = AsyncData(_merge(current, page));
    } catch (error) {
      if (_disposed || generation != _generation) return;
      state = AsyncData(retaining(error: error.toString()));
    }
  }
}
