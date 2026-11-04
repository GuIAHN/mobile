import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/entities/paged_result.dart';
import 'package:guiautomotriz_mobile/core/providers/paged_list_notifier.dart';

void main() {
  late ProviderContainer container;
  late AutoDisposeAsyncNotifierProviderFamily<PagedListNotifier<int, String>,
      PagedListState<int>, String> provider;
  late Future<PagedResult<int>> Function(int page, int size) fetch;
  final revision = StateProvider((ref) => 0);
  late List<int> requested;

  setUp(() {
    requested = [];
    fetch = (page, size) async => PagedResult(
        items:
            List.generate(page == 3 ? 3 : size, (i) => (page - 1) * size + i),
        page: page,
        pageSize: size,
        total: 43,
        counts: const {'all': 43});
    provider = AsyncNotifierProvider.autoDispose
        .family<PagedListNotifier<int, String>, PagedListState<int>, String>(
            () => PagedListNotifier(
                  firstPage: (ref, key) {
                    ref.watch(revision);
                    requested.add(1);
                    return fetch(1, 20);
                  },
                  nextPage: (ref, key, page, size) {
                    requested.add(page);
                    return fetch(page, size);
                  },
                  idOf: (item) => '$item',
                ));
    container = ProviderContainer();
  });
  Future<PagedListState<int>> start() {
    container.listen(provider('list'), (_, __) {});
    return container.read(provider('list').future);
  }

  tearDown(() => container.dispose());

  test('loads all 43 records across three pages and stops at the server total',
      () async {
    await start();
    final notifier = container.read(provider('list').notifier);
    await notifier.loadMore();
    await notifier.loadMore();
    await notifier.loadMore();
    final state = container.read(provider('list')).requireValue;
    expect(state.items, List.generate(43, (i) => i));
    expect(state.total, 43);
    expect(state.counts, {'all': 43});
    expect(state.hasMore, isFalse);
    expect(requested, [1, 2, 3]);
  });

  test(
      'honors the actual server page size and does not stop on a short page with a total',
      () async {
    fetch = (page, size) async =>
        PagedResult(items: [page], page: page, pageSize: 5, total: 11);
    await start();
    await container.read(provider('list').notifier).loadMore();
    expect(container.read(provider('list')).requireValue.hasMore, isTrue);
    await container.read(provider('list').notifier).loadMore();
    expect(container.read(provider('list')).requireValue.items, [1, 2, 3]);
    expect(container.read(provider('list')).requireValue.hasMore, isFalse);
  });

  test('keeps records and retries the same page after a failure', () async {
    await start();
    final defaultFetch = fetch;
    fetch = (_, __) async => throw Exception('offline');
    final notifier = container.read(provider('list').notifier);
    await notifier.loadMore();
    var state = container.read(provider('list')).requireValue;
    expect(state.items, hasLength(20));
    expect(state.page, 1);
    expect(state.loadMoreError, contains('offline'));
    fetch = defaultFetch;
    await notifier.loadMore();
    state = container.read(provider('list')).requireValue;
    expect(state.items, hasLength(40));
    expect(state.loadMoreError, isNull);
    expect(requested, [1, 2, 2]);
  });

  test(
      'prevents concurrent loads and updates duplicates without adding a second card',
      () async {
    await start();
    final pending = Completer<PagedResult<int>>();
    fetch = (_, __) => pending.future;
    final notifier = container.read(provider('list').notifier);
    final loading = notifier.loadMore();
    await notifier.loadMore();
    expect(requested, [1, 2]);
    pending
        .complete(const PagedResult(items: [19, 20, 21], page: 2, total: 22));
    await loading;
    expect(container.read(provider('list')).requireValue.items,
        List.generate(22, (i) => i));
  });

  test('discards pending pages after a filter/session revision', () async {
    await start();
    final pending = Completer<PagedResult<int>>();
    fetch = (_, __) => pending.future;
    final loading = container.read(provider('list').notifier).loadMore();
    fetch = (_, __) async => const PagedResult(items: [99], total: 1);
    container.read(revision.notifier).state++;
    await start();
    pending.complete(const PagedResult(items: [20], page: 2, total: 43));
    await loading;
    expect(container.read(provider('list')).requireValue.items, [99]);
    expect(container.read(provider('list')).requireValue.hasMore, isFalse);
  });

  test('discards pending pages after refresh', () async {
    await start();
    final pending = Completer<PagedResult<int>>();
    fetch = (_, __) => pending.future;
    final loading = container.read(provider('list').notifier).loadMore();
    fetch = (_, __) async => const PagedResult(items: [88], total: 1);
    await container.refresh(provider('list').future);
    pending.complete(const PagedResult(items: [20], page: 2, total: 43));
    await loading;
    expect(container.read(provider('list')).requireValue.items, [88]);
  });

  test('ignores completion after disposal', () async {
    await start();
    final pending = Completer<PagedResult<int>>();
    fetch = (_, __) => pending.future;
    final loading = container.read(provider('list').notifier).loadMore();
    container.dispose();
    pending.complete(const PagedResult(items: [20], page: 2));
    await loading;
    container = ProviderContainer();
  });

  test('an empty final page terminates probing when total is absent', () async {
    fetch = (page, size) async => PagedResult(
        items: page == 1 ? List.generate(size, (i) => i) : [], page: page);
    await start();
    await container.read(provider('list').notifier).loadMore();
    await container.read(provider('list').notifier).loadMore();
    expect(container.read(provider('list')).requireValue.items, hasLength(20));
    expect(container.read(provider('list')).requireValue.hasMore, isFalse);
    expect(requested, [1, 2]);
  });
}
