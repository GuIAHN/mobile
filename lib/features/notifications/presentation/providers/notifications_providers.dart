import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/session/session_generation_provider.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/get_unread_notifications_count_usecase.dart';
import '../../domain/usecases/get_unread_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'notifications_state.dart';

final notificationsRemoteDatasourceProvider =
    Provider<NotificationsRemoteDatasource>((ref) {
  return NotificationsRemoteDatasource(ref.watch(dioClientProvider));
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDatasourceProvider),
  );
});

final getUnreadNotificationsUseCaseProvider =
    Provider<GetUnreadNotificationsUseCase>((ref) {
  return GetUnreadNotificationsUseCase(
    ref.watch(notificationsRepositoryProvider),
  );
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(
    ref.watch(notificationsRepositoryProvider),
  );
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>((ref) {
  return MarkAllNotificationsReadUseCase(
    ref.watch(notificationsRepositoryProvider),
  );
});

final getUnreadNotificationsCountUseCaseProvider =
    Provider<GetUnreadNotificationsCountUseCase>((ref) {
  return GetUnreadNotificationsCountUseCase(
    ref.watch(notificationsRepositoryProvider),
  );
});

final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(sessionGenerationProvider);
  ref.cacheFor(const Duration(minutes: 2));
  final socketService = ref.watch(socketServiceProvider);
  Timer? refreshDebounce;
  void scheduleRefresh() {
    refreshDebounce?.cancel();
    refreshDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }

  final sub = socketService.onNotification.listen((_) {
    scheduleRefresh();
  });
  final reconnectSub = socketService.onReconnect.listen((_) {
    scheduleRefresh();
  });
  ref.onDispose(() {
    refreshDebounce?.cancel();
    sub.cancel();
    reconnectSub.cancel();
  });

  final result = await ref.watch(getUnreadNotificationsCountUseCaseProvider)();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (count) => count,
  );
});

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, NotificationsState>((ref) {
  ref.watch(sessionGenerationProvider);
  final notifier = NotificationsNotifier(
    getUnread: ref.watch(getUnreadNotificationsUseCaseProvider),
    markRead: ref.watch(markNotificationReadUseCaseProvider),
    markAllRead: ref.watch(markAllNotificationsReadUseCaseProvider),
    invalidateCount: () => ref.invalidate(unreadNotificationsCountProvider),
  );
  notifier.loadInitial();

  final socketService = ref.watch(socketServiceProvider);
  final sub = socketService.onNotification.listen((_) {
    notifier.refresh();
  });
  final reconnectSub = socketService.onReconnect.listen((_) {
    notifier.refresh();
  });
  ref.onDispose(() {
    sub.cancel();
    reconnectSub.cancel();
  });

  return notifier;
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier({
    required GetUnreadNotificationsUseCase getUnread,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required void Function() invalidateCount,
  })  : _getUnread = getUnread,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _invalidateCount = invalidateCount,
        super(const NotificationsState());

  static const int pageSize = 20;

  final GetUnreadNotificationsUseCase _getUnread;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final void Function() _invalidateCount;

  Future<void> loadInitial() => _loadFirstPage(showLoading: true);

  Future<void> refresh() => _loadFirstPage(showLoading: false);

  Future<void> _loadFirstPage({required bool showLoading}) async {
    if (showLoading) {
      state = state.copyWith(
        isInitialLoading: true,
        initialError: null,
        actionError: null,
      );
    }

    final result = await _getUnread(page: 1, limit: pageSize);
    result.fold(
      (failure) {
        if (showLoading) {
          state = state.copyWith(
            items: const [],
            isInitialLoading: false,
            initialError: 'No pudimos cargar tus notificaciones.',
            page: 0,
            hasMore: false,
          );
        } else {
          state = state.copyWith(
            actionError: 'No pudimos actualizar tus notificaciones.',
          );
        }
      },
      (items) {
        state = state.copyWith(
          items: List.unmodifiable(items),
          isInitialLoading: false,
          initialError: null,
          page: 1,
          hasMore: items.length == pageSize,
          isLoadingMore: false,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, actionError: null);
    final nextPage = state.page + 1;
    final result = await _getUnread(page: nextPage, limit: pageSize);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          actionError: 'No pudimos cargar más notificaciones.',
        );
      },
      (newItems) {
        final byId = {
          for (final item in state.items) item.id: item,
          for (final item in newItems) item.id: item,
        };
        state = state.copyWith(
          items: List.unmodifiable(byId.values),
          page: nextPage,
          hasMore: newItems.length == pageSize,
          isLoadingMore: false,
        );
      },
    );
  }

  Future<bool> markRead(String id) async {
    if (state.markingIds.contains(id) || state.isMarkingAll) return false;

    state = state.copyWith(
      markingIds: Set.unmodifiable({...state.markingIds, id}),
      actionError: null,
    );
    final result = await _markRead(id);

    return result.fold(
      (failure) {
        state = state.copyWith(
          markingIds: Set.unmodifiable({...state.markingIds}..remove(id)),
          actionError: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          markingIds: Set.unmodifiable({...state.markingIds}..remove(id)),
        );
        _invalidateCount();
        return true;
      },
    );
  }

  Future<bool> markAllRead() async {
    if (state.isMarkingAll || state.items.isEmpty) return false;

    state = state.copyWith(isMarkingAll: true, actionError: null);
    final result = await _markAllRead();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isMarkingAll: false,
          actionError: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          items: const [],
          isMarkingAll: false,
          page: 1,
          hasMore: false,
        );
        _invalidateCount();
        return true;
      },
    );
  }

  void clearActionError() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }
}
