# Notifications Inbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an authenticated unread-notifications inbox opened from the Home bell, with pagination, individual and bulk read actions, and a scrollable full-message detail sheet.

**Architecture:** Extend the existing notifications feature through domain, data, and presentation layers. A Riverpod `StateNotifier` owns pagination and mutation state; focused widgets render the inbox, cards, and modal detail while the existing unread-count provider remains the shared source for the Home indicator.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Dio, dartz, Equatable, intl, mocktail, flutter_test.

## Global Constraints

- `DESIGN_SYSTEM.md` remains the visual source of truth: `#F5F6FA` scaffold, white surfaces, `#F25C05` primary, Hanken Grotesk, 20 px item cards, 28 px sheet top radius.
- All touch targets are at least 48 dp; controls use explicit `Semantics` labels.
- Opening the inbox does not mark notifications read.
- Opening a card shows the full message immediately and starts `PATCH /api/me/notifications/:id/read` in parallel.
- The unread card is removed only after the backend confirms the mutation.
- No WebSocket, polling, read-history filter, contextual navigation, or backend change.
- Preserve unrelated dirty workspace files; only stage files named by each task.

---

## File Structure

### New domain/data files

- `lib/features/notifications/domain/entities/user_notification.dart`: persisted notification entity, distinct from ephemeral UI toasts.
- `lib/features/notifications/domain/repositories/notifications_repository.dart`: feature boundary returning `Either<Failure, T>`.
- `lib/features/notifications/domain/usecases/get_unread_notifications_usecase.dart`: paginated unread query.
- `lib/features/notifications/domain/usecases/mark_notification_read_usecase.dart`: individual mutation.
- `lib/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart`: bulk mutation.
- `lib/features/notifications/domain/usecases/get_unread_notifications_count_usecase.dart`: shared Home count query.
- `lib/features/notifications/data/models/user_notification_model.dart`: tolerant REST/WebSocket JSON parser.
- `lib/features/notifications/data/repositories/notifications_repository_impl.dart`: exception-to-failure mapping.

### New presentation files

- `lib/features/notifications/presentation/providers/notifications_state.dart`: immutable pagination and action state.
- `lib/features/notifications/presentation/widgets/notification_visual_style.dart`: one type-to-label/icon/color mapping reused by card and detail.
- `lib/features/notifications/presentation/widgets/notification_card.dart`: compact unread preview.
- `lib/features/notifications/presentation/widgets/notification_detail_sheet.dart`: full scrollable content.
- `lib/features/notifications/presentation/widgets/notification_card_skeleton.dart`: geometry-matched loading state.
- `lib/features/notifications/presentation/pages/notifications_page.dart`: header, states, refresh, pagination, mutations, detail orchestration.

### Existing files to modify

- `lib/core/network/api_endpoints.dart`: centralized list/read/read-all routes.
- `lib/features/notifications/data/datasources/notifications_remote_datasource.dart`: list and mutations in addition to count.
- `lib/features/notifications/presentation/providers/notifications_providers.dart`: repository, use cases, count, and inbox notifier wiring.
- `lib/core/router/route_names.dart`: `/notifications` name.
- `lib/core/router/app_router.dart`: authenticated notifications route.
- `lib/features/home/presentation/pages/home_page.dart`: bell uses `context.push`.

### Tests

- `test/features/notifications/data/models/user_notification_model_test.dart`
- `test/features/notifications/data/datasources/notifications_remote_datasource_test.dart`
- `test/features/notifications/data/repositories/notifications_repository_impl_test.dart`
- `test/features/notifications/presentation/providers/notifications_notifier_test.dart`
- `test/features/notifications/presentation/widgets/notification_detail_sheet_test.dart`
- `test/features/notifications/presentation/pages/notifications_page_test.dart`
- `test/features/home/presentation/pages/home_page_test.dart`

---

### Task 1: Persisted notification contract and parsing

**Files:**
- Create: `lib/features/notifications/domain/entities/user_notification.dart`
- Create: `lib/features/notifications/data/models/user_notification_model.dart`
- Modify: `lib/core/network/api_endpoints.dart`
- Test: `test/features/notifications/data/models/user_notification_model_test.dart`

**Interfaces:**
- Produces: `UserNotification({id, type, title, body, data, isRead, createdAt})`.
- Produces: `UserNotificationModel.fromJson(Map<String, dynamic>)` accepting `id` or `_id`.
- Produces: `ApiEndpoints.notifications`, `notificationsReadAll`, and `notificationRead(String id)`.

- [ ] **Step 1: Write the failing entity/model tests**

```dart
test('parses REST _id and optional payload', () {
  final model = UserNotificationModel.fromJson({
    '_id': 'n-1',
    'tipo': 'offer.new',
    'titulo': 'Nueva oferta',
    'cuerpo': 'Mensaje completo',
    'data': {'offerId': 'o-1'},
    'leido': false,
    'createdAt': '2026-08-14T12:00:00.000Z',
  });

  expect(model.id, 'n-1');
  expect(model.type, 'offer.new');
  expect(model.data, {'offerId': 'o-1'});
  expect(model.isRead, isFalse);
  expect(model.createdAt, DateTime.utc(2026, 8, 14, 12));
});

test('accepts realtime id and safe defaults', () {
  final model = UserNotificationModel.fromJson({
    'id': 'n-2',
    'tipo': 'unknown.kind',
    'titulo': 'Aviso',
    'cuerpo': 'Contenido',
    'createdAt': 'invalid',
  });

  expect(model.id, 'n-2');
  expect(model.data, isEmpty);
  expect(model.isRead, isFalse);
  expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
});
```

- [ ] **Step 2: Run the model test and verify RED**

Run: `flutter test test/features/notifications/data/models/user_notification_model_test.dart`

Expected: FAIL because `UserNotificationModel` and `UserNotification` do not exist.

- [ ] **Step 3: Implement the entity, parser, and endpoints**

```dart
class UserNotification extends Equatable {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, title, body, data, isRead, createdAt];
}
```

The parser must copy loose `Map` payloads with `Map<String, dynamic>.from`, parse `leido == true`, and use the Unix epoch for malformed/missing dates so ordering is deterministic.

Add exact endpoint constants:

```dart
static const String notifications = 'me/notifications';
static const String notificationsReadAll = 'me/notifications/read-all';
static String notificationRead(String id) => 'me/notifications/$id/read';
```

- [ ] **Step 4: Run the model test and verify GREEN**

Run: `flutter test test/features/notifications/data/models/user_notification_model_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the contract**

```bash
git add lib/features/notifications/domain/entities/user_notification.dart lib/features/notifications/data/models/user_notification_model.dart lib/core/network/api_endpoints.dart test/features/notifications/data/models/user_notification_model_test.dart
git commit -m "feat: model persisted notifications"
```

---

### Task 2: Remote operations and clean repository boundary

**Files:**
- Modify: `lib/features/notifications/data/datasources/notifications_remote_datasource.dart`
- Create: `lib/features/notifications/domain/repositories/notifications_repository.dart`
- Create: `lib/features/notifications/data/repositories/notifications_repository_impl.dart`
- Create: `lib/features/notifications/domain/usecases/get_unread_notifications_usecase.dart`
- Create: `lib/features/notifications/domain/usecases/mark_notification_read_usecase.dart`
- Create: `lib/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart`
- Create: `lib/features/notifications/domain/usecases/get_unread_notifications_count_usecase.dart`
- Modify test: `test/features/notifications/data/datasources/notifications_remote_datasource_test.dart`
- Test: `test/features/notifications/data/repositories/notifications_repository_impl_test.dart`

**Interfaces:**
- Consumes: `UserNotificationModel.fromJson` and Task 1 endpoint constants.
- Produces: `getUnreadNotifications({int page = 1, int limit = 20})`.
- Produces: `markRead(String id)`, `markAllRead()`, and existing `getUnreadCount()`.
- Produces: repository/use cases returning `Either<Failure, ...>`.

- [ ] **Step 1: Extend datasource tests for query and PATCH paths**

```dart
when(() => client.get<List<dynamic>>(
  ApiEndpoints.notifications,
  queryParameters: const {'leido': false, 'page': 2, 'limit': 20},
)).thenAnswer((_) async => Response(
  requestOptions: RequestOptions(path: ApiEndpoints.notifications),
  data: const [
    {'_id': 'n-1', 'tipo': 'message.new', 'titulo': 'Mensaje', 'cuerpo': 'Hola', 'leido': false},
  ],
));

final items = await datasource.getUnreadNotifications(page: 2);
expect(items.single.id, 'n-1');

verify(() => client.patch<Map<String, dynamic>>(
  ApiEndpoints.notificationRead('n-1'),
)).called(1);
verify(() => client.patch<Map<String, dynamic>>(
  ApiEndpoints.notificationsReadAll,
)).called(1);
```

- [ ] **Step 2: Run datasource tests and verify RED**

Run: `flutter test test/features/notifications/data/datasources/notifications_remote_datasource_test.dart`

Expected: FAIL because the list and mutation methods do not exist.

- [ ] **Step 3: Implement datasource methods**

```dart
Future<List<UserNotificationModel>> getUnreadNotifications({
  int page = 1,
  int limit = 20,
}) async {
  final response = await _client.get<List<dynamic>>(
    ApiEndpoints.notifications,
    queryParameters: {'leido': false, 'page': page, 'limit': limit},
  );
  return (response.data ?? const <dynamic>[])
      .whereType<Map>()
      .map((json) => UserNotificationModel.fromJson(
            Map<String, dynamic>.from(json),
          ))
      .toList(growable: false);
}

Future<void> markRead(String id) async {
  await _client.patch<Map<String, dynamic>>(ApiEndpoints.notificationRead(id));
}

Future<void> markAllRead() async {
  await _client.patch<Map<String, dynamic>>(ApiEndpoints.notificationsReadAll);
}
```

- [ ] **Step 4: Add failing repository tests for success and mapped failure**

```dart
class _MockDatasource extends Mock implements NotificationsRemoteDatasource {}

test('returns unread notifications from the datasource', () async {
  final datasource = _MockDatasource();
  final fixture = UserNotificationModel.fromJson(const {
    '_id': 'n-1',
    'tipo': 'offer.new',
    'titulo': 'Nueva oferta',
    'cuerpo': 'Tienes una oferta',
  });
  when(() => datasource.getUnreadNotifications(page: 1, limit: 20))
      .thenAnswer((_) async => [fixture]);

  final result = await NotificationsRepositoryImpl(datasource)
      .getUnread(page: 1, limit: 20);

  expect(result, Right<Failure, List<UserNotification>>([fixture]));
});

test('maps a connection error to NetworkFailure', () async {
  final datasource = _MockDatasource();
  when(() => datasource.getUnreadNotifications(page: 1, limit: 20))
      .thenThrow(DioException(
        requestOptions: RequestOptions(path: 'me/notifications'),
        type: DioExceptionType.connectionError,
      ));

  final result = await NotificationsRepositoryImpl(datasource)
      .getUnread(page: 1, limit: 20);

  expect(result.fold((failure) => failure, (_) => null), isA<NetworkFailure>());
});

test('delegates individual and bulk read mutations', () async {
  final datasource = _MockDatasource();
  when(() => datasource.markRead('n-1')).thenAnswer((_) async {});
  when(datasource.markAllRead).thenAnswer((_) async {});
  final repository = NotificationsRepositoryImpl(datasource);

  expect(await repository.markRead('n-1'), const Right<Failure, void>(null));
  expect(await repository.markAllRead(), const Right<Failure, void>(null));
  verify(() => datasource.markRead('n-1')).called(1);
  verify(datasource.markAllRead).called(1);
});
```

- [ ] **Step 5: Run repository tests and verify RED**

Run: `flutter test test/features/notifications/data/repositories/notifications_repository_impl_test.dart`

Expected: FAIL because repository classes do not exist.

- [ ] **Step 6: Implement repository and four focused use cases**

```dart
abstract class NotificationsRepository {
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, void>> markRead(String id);
  Future<Either<Failure, void>> markAllRead();
  Future<Either<Failure, int>> getUnreadCount();
}
```

`NotificationsRepositoryImpl` wraps every datasource call in `try/catch` and returns `Left(ErrorMapper.map(error))`. Each use case has a single `call` method delegating to its repository method with identical argument defaults.

- [ ] **Step 7: Run datasource and repository tests and verify GREEN**

Run: `flutter test test/features/notifications/data/datasources/notifications_remote_datasource_test.dart test/features/notifications/data/repositories/notifications_repository_impl_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit remote and domain operations**

```bash
git add lib/features/notifications/data lib/features/notifications/domain test/features/notifications/data
git commit -m "feat: add notifications repository operations"
```

---

### Task 3: Riverpod inbox state, pagination, and mutations

**Files:**
- Create: `lib/features/notifications/presentation/providers/notifications_state.dart`
- Modify: `lib/features/notifications/presentation/providers/notifications_providers.dart`
- Test: `test/features/notifications/presentation/providers/notifications_notifier_test.dart`

**Interfaces:**
- Consumes: four Task 2 use cases.
- Produces: `NotificationsState` with `items`, `isInitialLoading`, `initialError`, `page`, `hasMore`, `isLoadingMore`, `markingIds`, `isMarkingAll`, and `actionError`.
- Produces: `NotificationsNotifier.loadInitial`, `refresh`, `loadMore`, `markRead`, `markAllRead`, and `clearActionError`.
- Produces: `notificationsProvider` and keeps `unreadNotificationsCountProvider` compatible with existing Home consumers.

- [ ] **Step 1: Write failing notifier tests**

Use a deterministic fake repository and real use cases:

```dart
class _FakeNotificationsRepository implements NotificationsRepository {
  final unreadResults = <Either<Failure, List<UserNotification>>>[];
  Either<Failure, void> markReadResult = const Right(null);
  Either<Failure, void> markAllResult = const Right(null);
  final requestedPages = <int>[];

  @override
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  }) async {
    requestedPages.add(page);
    return unreadResults.removeAt(0);
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async => markReadResult;

  @override
  Future<Either<Failure, void>> markAllRead() async => markAllResult;

  @override
  Future<Either<Failure, int>> getUnreadCount() async => const Right(0);
}

UserNotification fixture(int index) => UserNotification(
  id: 'n-$index',
  type: 'offer.new',
  title: 'Oferta $index',
  body: 'Mensaje $index',
  data: const {},
  isRead: false,
  createdAt: DateTime.utc(2026, 8, 14, 12, index),
);

NotificationsNotifier subject(
  _FakeNotificationsRepository repository,
  void Function() invalidate,
) => NotificationsNotifier(
  getUnread: GetUnreadNotificationsUseCase(repository),
  markRead: MarkNotificationReadUseCase(repository),
  markAllRead: MarkAllNotificationsReadUseCase(repository),
  invalidateCount: invalidate,
);
```

Cover exact state transitions:

```dart
test('initial load requests unread page one and exposes more pages', () async {
  final repository = _FakeNotificationsRepository()
    ..unreadResults.add(Right(List.generate(20, fixture)));
  final notifier = subject(repository, () {});
  await notifier.loadInitial();
  expect(notifier.state.items, hasLength(20));
  expect(notifier.state.page, 1);
  expect(notifier.state.hasMore, isTrue);
  expect(repository.requestedPages, [1]);
});

test('loadMore appends unique second-page items', () async {
  final repository = _FakeNotificationsRepository()
    ..unreadResults.addAll([
      Right(List.generate(20, (index) => fixture(index + 1))),
      Right([fixture(20), fixture(21)]),
    ]);
  final notifier = subject(repository, () {});
  await notifier.loadInitial();
  await notifier.loadMore();
  expect(notifier.state.items, hasLength(21));
  expect(notifier.state.items.last.id, 'n-21');
  expect(notifier.state.page, 2);
});

test('successful markRead invalidates count and returns true', () async {
  var invalidations = 0;
  final repository = _FakeNotificationsRepository();
  final notifier = subject(repository, () => invalidations++);
  final result = await notifier.markRead('n-1');
  expect(result, isTrue);
  expect(notifier.state.markingIds, isEmpty);
  expect(invalidations, 1);
});

test('failed markRead keeps item and exposes friendly action error', () async {
  final repository = _FakeNotificationsRepository()
    ..unreadResults.add(Right([fixture(1)]))
    ..markReadResult = const Left(NetworkFailure());
  final notifier = subject(repository, () {});
  await notifier.loadInitial();
  expect(await notifier.markRead('n-1'), isFalse);
  expect(notifier.state.items.single.id, 'n-1');
  expect(notifier.state.actionError, isNotNull);
});

test('markAllRead empties list only on success', () async {
  var invalidations = 0;
  final repository = _FakeNotificationsRepository()
    ..unreadResults.add(Right([fixture(1)]));
  final notifier = subject(repository, () => invalidations++);
  await notifier.loadInitial();
  expect(await notifier.markAllRead(), isTrue);
  expect(notifier.state.items, isEmpty);
  expect(invalidations, 1);
});
```

- [ ] **Step 2: Run notifier tests and verify RED**

Run: `flutter test test/features/notifications/presentation/providers/notifications_notifier_test.dart`

Expected: FAIL because state and notifier do not exist.

- [ ] **Step 3: Implement immutable state and notifier**

Use a page size constant of 20. Initial failures set `initialError = 'No pudimos cargar tus notificaciones.'`; action failures use the mapped failure message. `loadMore` must deduplicate by `id`, refuse concurrent calls, and set `hasMore` from `received.length == 20`.

`markRead` must not remove the item; it only returns success so the page can coordinate sheet closure, then call `refresh()`. `markAllRead` clears items only after a `Right` result.

Wire dependencies:

```dart
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDatasourceProvider),
  );
});

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, NotificationsState>((ref) {
  final notifier = NotificationsNotifier(
    getUnread: ref.watch(getUnreadNotificationsUseCaseProvider),
    markRead: ref.watch(markNotificationReadUseCaseProvider),
    markAllRead: ref.watch(markAllNotificationsReadUseCaseProvider),
    invalidateCount: () => ref.invalidate(unreadNotificationsCountProvider),
  );
  notifier.loadInitial();
  return notifier;
});
```

Change `unreadNotificationsCountProvider` to fold the count use case and throw the mapped `Failure.message` on `Left`, preserving the existing `FutureProvider.autoDispose<int>` public type.

- [ ] **Step 4: Run notifier and existing Home count tests and verify GREEN**

Run: `flutter test test/features/notifications/presentation/providers/notifications_notifier_test.dart test/features/home/presentation/pages/home_page_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit state management**

```bash
git add lib/features/notifications/presentation/providers test/features/notifications/presentation/providers test/features/home/presentation/pages/home_page_test.dart
git commit -m "feat: manage unread notifications state"
```

---

### Task 4: Notification card and long-message detail sheet

**Files:**
- Create: `lib/features/notifications/presentation/widgets/notification_visual_style.dart`
- Create: `lib/features/notifications/presentation/widgets/notification_card.dart`
- Create: `lib/features/notifications/presentation/widgets/notification_detail_sheet.dart`
- Create: `lib/features/notifications/presentation/widgets/notification_card_skeleton.dart`
- Test: `test/features/notifications/presentation/widgets/notification_detail_sheet_test.dart`

**Interfaces:**
- Consumes: `UserNotification` and project design tokens.
- Produces: `NotificationVisualStyle.forType(String type)`.
- Produces: `NotificationCard(notification, isMarking, onTap)`.
- Produces: `showNotificationDetailSheet(context, notification: ...)`.
- Produces: `NotificationCardSkeleton`.

- [ ] **Step 1: Write failing visual and detail tests**

Test all type families resolve to a non-null Material icon and a human label:

```dart
for (final entry in const {
  'offer.new': 'Oferta',
  'message.new': 'Mensaje',
  'search.matched': 'Solicitud',
  'user.approved': 'Cuenta',
  'settlement.approved': 'Pago',
  'custom.kind': 'Notificación',
}.entries) {
  final style = NotificationVisualStyle.forType(entry.key);
  expect(style.label, entry.value);
  expect(style.icon, isA<IconData>());
}
```

Pump a button that invokes the sheet with a 1,000-character body and assert:

```dart
final longBody = List.filled(1000, 'x').join();
expect(find.text('Mensaje completo de prueba'), findsOneWidget);
expect(find.text(longBody), findsOneWidget);
expect(find.bySemanticsLabel('Cerrar detalle de notificación'), findsOneWidget);
expect(tester.takeException(), isNull);
```

Add a second widget test that sets `tester.view.physicalSize = const Size(320, 700)`, `devicePixelRatio = 1`, and `MediaQuery.textScaler = TextScaler.linear(2)`. Open the sheet, call `tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500))`, and assert the close action is visible with no exception. Pump `NotificationCard`, then assert `find.bySemanticsLabel('Abrir y marcar como leída: Nueva oferta')` and a card render height of at least 80 dp.

- [ ] **Step 2: Run widget tests and verify RED**

Run: `flutter test test/features/notifications/presentation/widgets/notification_detail_sheet_test.dart`

Expected: FAIL because the widgets do not exist.

- [ ] **Step 3: Implement shared visual mapping**

Map prefixes without importing domain concerns:

```dart
if (type.startsWith('offer.')) return offerStyle;
if (type.startsWith('message.')) return messageStyle;
if (type.startsWith('search.')) return searchStyle;
if (type.startsWith('user.')) return accountStyle;
if (type.startsWith('settlement.')) return paymentStyle;
return notificationStyle;
```

Use Material outline icons. Use `AppColors.primaryMuted/primaryInk`, `tertiaryMuted/info`, `celesteMuted/celesteInk`, and accessible semantic ink colors; do not use emoji.

- [ ] **Step 4: Implement card, skeleton, and adaptive sheet**

The card uses a white `Material`, 20 px radius, `AppDecorations.soft`, 4 px orange rail, 48 × 48 icon box, `AppTypography.title/bodySm/meta`, three-line preview, relative time via `Formatters.relativeDate`, and a 48 dp minimum InkWell region.

The detail helper uses:

```dart
return showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: 0.48),
  builder: (_) => NotificationDetailSheet(notification: notification),
);
```

Inside the sheet, constrain height to `MediaQuery.sizeOf(context).height * .88`, use `AppDecorations.sheet`, a `Flexible` `SingleChildScrollView`, full untruncated title/body, `Formatters.dateTime(notification.createdAt.toLocal())`, bottom safe-area padding, and a 48 dp text action. Avoid fixed content height.

The skeleton matches the card rail, icon, title, preview, and metadata geometry and suppresses shimmer when `MediaQuery.disableAnimationsOf(context)` is true.

- [ ] **Step 5: Run detail/card tests and verify GREEN**

Run: `flutter test test/features/notifications/presentation/widgets/notification_detail_sheet_test.dart`

Expected: PASS with no overflow exceptions.

- [ ] **Step 6: Commit notification visuals**

```bash
git add lib/features/notifications/presentation/widgets test/features/notifications/presentation/widgets
git commit -m "feat: add notification detail experience"
```

---

### Task 5: Inbox page, Home navigation, and authenticated route

**Files:**
- Create: `lib/features/notifications/presentation/pages/notifications_page.dart`
- Modify: `lib/core/router/route_names.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Test: `test/features/notifications/presentation/pages/notifications_page_test.dart`
- Modify test: `test/features/home/presentation/pages/home_page_test.dart`

**Interfaces:**
- Consumes: `notificationsProvider`, card, skeleton, detail sheet, shared `EmptyState` and `ErrorView`.
- Produces: authenticated `/notifications` page.
- Changes: Home bell from chat-tab mutation to `context.push(RouteNames.notifications)`.

- [ ] **Step 1: Write failing page-state tests**

Create `_TestNotificationsNotifier extends NotificationsNotifier` with queued `Completer<bool>` results and counters for `loadInitial`, `refresh`, `loadMore`, `markRead`, and `markAllRead`. Override `notificationsProvider` with it and implement these concrete assertions:

- loading renders four `NotificationCardSkeleton` widgets;
- initial error renders `No pudimos cargar tus notificaciones` and a 48 dp `Reintentar` action;
- empty renders `Estás al día` and `No tienes notificaciones sin leer.` inside an always-scrollable refresh view;
- data renders the pending count, cards, and `Marcar todas`;
- tapping a card opens the full detail before a delayed `markRead` future completes;
- successful completion followed by sheet close calls refresh and removes the card;
- failure followed by close preserves the card and emits the friendly global toast;
- bulk action shows progress, disables itself, then empties only on success;
- scroll near the end calls `loadMore` once;
- `Size(320, 700)` and `Size(430, 932)` at text scale 2 produce no overflow and all header actions are at least 48 dp.

The data-state test must include:

```dart
final longBody = List.filled(80, 'mensaje').join(' ');
await tester.pumpWidget(subject(NotificationsState(
  items: [notificationFixture(body: longBody)],
  hasMore: true,
)));

expect(find.text('1 pendiente'), findsOneWidget);
expect(find.text('Marcar todas'), findsOneWidget);
await tester.tap(find.bySemanticsLabel(
  'Abrir y marcar como leída: Nueva oferta',
));
await tester.pumpAndSettle();
expect(find.text(longBody), findsOneWidget);
expect(testNotifier.markReadIds, ['n-1']);
```

- [ ] **Step 2: Add failing Home bell navigation test**

Add a `/notifications` test route to the existing Home test router, tap the bell, and assert `find.text('notifications-route')` appears. This must fail while Home still changes `homeTabProvider`.

- [ ] **Step 3: Run page and Home navigation tests and verify RED**

Run: `flutter test test/features/notifications/presentation/pages/notifications_page_test.dart test/features/home/presentation/pages/home_page_test.dart`

Expected: FAIL because the page/route do not exist and the bell still selects chats.

- [ ] **Step 4: Implement the inbox page**

Use a `ConsumerStatefulWidget` with a `ScrollController` that requests `loadMore` once `extentAfter < 240`. Structure:

```text
Scaffold(AppColors.background)
  SafeArea
    Column
      back/title row
      pending-count / mark-all row
      Expanded state body
```

Keep 24 px horizontal screen padding. Put “Marcar todas” beside the count rather than forcing it into the title row, preventing overflow on small devices. Use `RefreshIndicator` for data and empty states. Listen to `actionError`, call `NotificationService.error`, then clear it.

For a card tap:

```dart
final markFuture = notifier.markRead(notification.id);
await showNotificationDetailSheet(context, notification: notification);
final marked = await markFuture;
if (marked && mounted) await notifier.refresh();
```

This opens from local data immediately, supports closing before the PATCH settles, and refreshes only after both sheet closure and server success.

- [ ] **Step 5: Add route and change Home bell action**

```dart
static const String notifications = '/notifications';
```

Register `NotificationsPage` as a top-level authenticated `GoRoute`. Import `go_router` in `home_page.dart` and set:

```dart
onNotificationsTap: () => context.push(RouteNames.notifications),
```

- [ ] **Step 6: Run page and Home tests and verify GREEN**

Run: `flutter test test/features/notifications/presentation/pages/notifications_page_test.dart test/features/home/presentation/pages/home_page_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit the integrated inbox**

```bash
git add lib/features/notifications/presentation/pages lib/core/router lib/features/home/presentation/pages/home_page.dart test/features/notifications/presentation/pages test/features/home/presentation/pages/home_page_test.dart
git commit -m "feat: open unread notifications from home"
```

---

### Task 6: Focused regression and UI quality verification

**Files:**
- Modify only files from Tasks 1–5 if verification exposes a defect.

**Interfaces:**
- Verifies the completed feature; produces no new public API.

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib/core/network/api_endpoints.dart lib/core/router/route_names.dart lib/core/router/app_router.dart lib/features/home/presentation/pages/home_page.dart lib/features/notifications test/features/notifications test/features/home/presentation/pages/home_page_test.dart`

Expected: formatter completes without error and does not touch unrelated dirty files.

- [ ] **Step 2: Run all notifications and affected Home tests**

Run: `flutter test test/features/notifications test/features/home/presentation/pages/home_page_test.dart test/features/home/presentation/widgets/home_header_expanded_test.dart`

Expected: PASS.

- [ ] **Step 3: Analyze exact changed production files**

Run: `flutter analyze lib/core/network/api_endpoints.dart lib/core/router/route_names.dart lib/core/router/app_router.dart lib/features/home/presentation/pages/home_page.dart lib/features/notifications`

Expected: no errors or warnings in changed files.

- [ ] **Step 4: Run the full suite as a regression signal**

Run: `flutter test`

Expected: no new failures attributable to notifications. Record separately any pre-existing failures already present on the branch; do not modify unrelated features to hide them.

- [ ] **Step 5: Check the project UI requirements explicitly**

Confirm from widget tests and inspection:

- loading, error, empty, data, pagination, individual mutation, and bulk mutation states exist;
- 48 dp actions and semantic labels are asserted;
- long text scrolls at scale 2 without overflow;
- 320 × 700 and 430 × 932 layouts pass;
- safe areas are present;
- card/skeleton motion respects `disableAnimations`;
- colors and typography come from project tokens and maintain readable contrast.

- [ ] **Step 6: Inspect final diff and commit verification fixes if any**

Run: `git diff --check` and `git status --short`.

If verification required code changes, stage only those feature files and commit:

```bash
git commit -m "fix: harden notifications inbox states"
```

If no fixes were required, do not create an empty commit.
