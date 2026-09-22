import '../../domain/entities/user_notification.dart';

const Object _unsetNotificationStateValue = Object();

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isInitialLoading = true,
    this.initialError,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.markingIds = const {},
    this.isMarkingAll = false,
    this.actionError,
  });

  final List<UserNotification> items;
  final bool isInitialLoading;
  final String? initialError;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<String> markingIds;
  final bool isMarkingAll;
  final String? actionError;

  NotificationsState copyWith({
    List<UserNotification>? items,
    bool? isInitialLoading,
    Object? initialError = _unsetNotificationStateValue,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Set<String>? markingIds,
    bool? isMarkingAll,
    Object? actionError = _unsetNotificationStateValue,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      initialError: identical(initialError, _unsetNotificationStateValue)
          ? this.initialError
          : initialError as String?,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      markingIds: markingIds ?? this.markingIds,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      actionError: identical(actionError, _unsetNotificationStateValue)
          ? this.actionError
          : actionError as String?,
    );
  }
}
