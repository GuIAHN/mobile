import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/sort_option.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_search_page.dart';
import 'package:guiautomotriz_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements HomeRepository {}

ProviderSearchPage _page(int page, ServiceType type, {int total = 43}) =>
    ProviderSearchPage(
      items: List.generate(page == 3 ? 3 : 20, (index) {
        final id = (page - 1) * 20 + index;
        return HomeItem(
            id: '$id',
            name: 'Proveedor $id',
            detail: 'Frenos',
            rating: 4,
            reviews: 1,
            distanceKm: 1,
            isOpen: true,
            iconName: 'build_outlined',
            type: type);
      }),
      total: total,
      page: page,
      pageSize: 20,
    );

void main() {
  setUpAll(() => registerFallbackValue(const HomeFilters()));
  for (final type in [ServiceType.workshops, ServiceType.mechanic]) {
    test('loads all 43 ${type.name} in order and stops at the server total',
        () async {
      final repository = _Repository();
      final requests = <int>[];
      when(() => repository.searchProvidersPage(
          type: type,
          filters: any(named: 'filters'),
          page: any(named: 'page'))).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        requests.add(page);
        return Right(_page(page, type));
      });
      final container = ProviderContainer(overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        providerSearchFiltersProvider
            .overrideWith((ref) async => const HomeFilters()),
      ]);
      addTearDown(container.dispose);
      final provider = paginatedProvidersProvider(type);
      container.listen(provider, (_, __) {});
      expect((await container.read(provider.future)).items.length, 20);
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).requireValue.items.length, 40);
      await container.read(provider.notifier).loadMore();
      await container.read(provider.notifier).loadMore();
      final state = container.read(provider).requireValue;
      expect(
          state.items.map((item) => item.id), List.generate(43, (i) => '$i'));
      expect(state.hasMore, isFalse);
      expect(requests, [1, 2, 3]);
    });
  }

  test(
      'retains rows on failure, retries the same page and prevents parallel requests',
      () async {
    final repository = _Repository();
    const type = ServiceType.mechanic;
    final pending = Completer<Either<Failure, ProviderSearchPage>>();
    var calls = 0;
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      calls++;
      if (calls == 1) return Right(_page(1, type));
      if (calls == 2) return pending.future;
      return Right(_page(2, type));
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider
          .overrideWith((ref) async => const HomeFilters()),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedProvidersProvider(type);
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    final loading = container.read(provider.notifier).loadMore();
    await container.read(provider.notifier).loadMore();
    expect(calls, 2);
    pending.complete(const Left(NetworkFailure()));
    await loading;
    expect(container.read(provider).requireValue.items.length, 20);
    expect(container.read(provider).requireValue.loadMoreError, isNotNull);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).requireValue.items.length, 40);
    expect(container.read(provider).requireValue.loadMoreError, isNull);
  });
  test('ignores an old next-page response after filters change', () async {
    final repository = _Repository();
    final pending = Completer<Either<Failure, ProviderSearchPage>>();
    const type = ServiceType.workshops;
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      final filters = invocation.namedArguments[#filters] as HomeFilters;
      final page = invocation.namedArguments[#page] as int;
      if (page == 2) return pending.future;
      if (filters.minRating > 0) {
        return const Right(
            ProviderSearchPage(items: [], total: 0, page: 1, pageSize: 20));
      }
      return Right(_page(1, type));
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider
          .overrideWith((ref) async => ref.watch(homeFiltersProvider)),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedProvidersProvider(type);
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    final oldRequest = container.read(provider.notifier).loadMore();
    container.read(homeFiltersProvider.notifier).state =
        const HomeFilters(minRating: 5);
    await container.read(provider.future);
    pending.complete(Right(_page(2, type)));
    await oldRequest;
    expect(container.read(provider).requireValue.items, isEmpty);
    expect(container.read(provider).requireValue.page, 1);
  });

  test(
      'deduplicates providers across page boundaries and tolerates empty final pages',
      () async {
    final repository = _Repository();
    const type = ServiceType.mechanic;
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      return Right(page < 3
          ? ProviderSearchPage(
              items: _page(1, type).items, total: 60, page: page, pageSize: 20)
          : const ProviderSearchPage(
              items: [], total: 0, page: 3, pageSize: 20));
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider
          .overrideWith((ref) async => const HomeFilters()),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedProvidersProvider(type);
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).requireValue.items.length, 20);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).requireValue.items.length, 20);
    expect(container.read(provider).requireValue.hasMore, isFalse);
  });

  test('ignores a pending page when the directory is disposed', () async {
    final repository = _Repository();
    const type = ServiceType.mechanic;
    final pending = Completer<Either<Failure, ProviderSearchPage>>();
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      if (invocation.namedArguments[#page] == 1) return Right(_page(1, type));
      return pending.future;
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider
          .overrideWith((ref) async => const HomeFilters()),
    ]);
    final provider = paginatedProvidersProvider(type);
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    final request = container.read(provider.notifier).loadMore();
    container.dispose();
    pending.complete(Right(_page(2, type)));
    await expectLater(request, completes);
  });
  test('loads the full result before exposing local popularity sorting',
      () async {
    final repository = _Repository();
    const type = ServiceType.workshops;
    final requests = <int>[];
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      requests.add(page);
      return Right(_page(page, type));
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider.overrideWith(
          (ref) async => const HomeFilters(sortBy: SortOption.populares)),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedProvidersProvider(type);
    container.listen(provider, (_, __) {});
    final value = await container.read(provider.future);
    expect(value.items.length, 43);
    expect(value.hasMore, isFalse);
    expect(requests, [1, 2, 3]);
  });

  test('keeps the server order for tied ratings across appended pages',
      () async {
    final repository = _Repository();
    const type = ServiceType.mechanic;
    when(() => repository.searchProvidersPage(
            type: type,
            filters: any(named: 'filters'),
            page: any(named: 'page')))
        .thenAnswer((invocation) async =>
            Right(_page(invocation.namedArguments[#page] as int, type)));
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      providerSearchFiltersProvider
          .overrideWith((ref) async => const HomeFilters()),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedProvidersProvider(type);
    container.listen(filteredProvidersProvider(type), (_, __) {});
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();
    expect(
        container
            .read(filteredProvidersProvider(type))
            .requireValue
            .map((item) => item.id),
        List.generate(40, (index) => '$index'));
  });
  test('popularity sorts by review count across all pages', () async {
    final repository = _Repository();
    const type = ServiceType.mechanic;
    when(() => repository.searchProvidersPage(
        type: type,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      return Right(ProviderSearchPage(items: [
        HomeItem(
            id: '$page',
            name: 'Mecánico $page',
            detail: 'Frenos',
            rating: page == 1 ? 5 : 4,
            reviews: page == 1 ? 2 : 37,
            distanceKm: 1,
            isOpen: true,
            iconName: 'build_outlined',
            type: type)
      ], total: 2, page: page, pageSize: 1));
    });
    final container = ProviderContainer(overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      homeFiltersProvider.overrideWith(
          (ref) => const HomeFilters(sortBy: SortOption.populares)),
      providerSearchFiltersProvider
          .overrideWith((ref) async => ref.watch(homeFiltersProvider)),
    ]);
    addTearDown(container.dispose);
    container.listen(filteredProvidersProvider(type), (_, __) {});
    await container.read(paginatedProvidersProvider(type).future);
    final items = container.read(filteredProvidersProvider(type)).requireValue;
    expect(items.map((item) => item.id), ['2', '1']);
    expect(items.map((item) => item.reviews), [37, 2]);
  });
}
