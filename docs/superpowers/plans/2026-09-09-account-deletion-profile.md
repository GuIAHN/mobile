# Account Deletion Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate account deletion scheduling and account restoration into the authenticated Flutter profile using the backend's new endpoints.

**Architecture:** Extend the authenticated user domain model with deletion lifecycle data, expose the two REST operations through the existing datasource/repository/notifier stack, and render one focused profile section for both active and pending states. A pending-deletion socket rejection stops reconnection without destroying the access token needed by the restore endpoint; successful restoration clears the stale session and lets the existing auth router require a fresh login.

**Tech Stack:** Flutter, Dart, Riverpod StateNotifier, Dio, dartz, flutter_test, mocktail.

**Spec:** Approved conversation design from 2026-09-09; project rules in `AGENTS.md` and `DESIGN_SYSTEM.md`.

## Global Constraints

- Use `Hanken Grotesk`, semantic `AppColors`, `AppSpacing`, and `AppLineIcon`/`AppIcons` from `DESIGN_SYSTEM.md`.
- Preserve the light-theme visual language and existing profile layout.
- All interactive targets must be at least 48 dp high.
- Support safe areas, text scaling, reduced motion, and representative small and large phone widths.
- Display explicit loading, error, active-data, and pending/deletion-date-unavailable states.
- Do not modify or discard unrelated local worktree changes.

---

### Task 1: Account lifecycle model and HTTP contract

**Files:**
- Create: `lib/core/domain/enums/account_status.dart`
- Modify: `lib/core/network/api_endpoints.dart`
- Modify: `lib/features/auth/domain/entities/user.dart`
- Modify: `lib/features/auth/data/models/user_model.dart`
- Modify: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Test: `test/features/auth/data/models/user_model_test.dart`
- Test: `test/features/auth/data/datasources/auth_remote_datasource_test.dart`

**Interfaces:**
- Produces: `AccountStatus`, `User.isPendingDeletion`, `User.requiresDeletionPassword`, `requestAccountDeletion({String? password})`, and `restoreAccount()`.
- Consumes: backend `DELETE users/me` with `{confirm: 'DELETE', password?}` and `POST users/me/restore`.

- [x] **Step 1: Write failing model and datasource contract tests**

```dart
expect(user.accountStatus, AccountStatus.pendingDeletion);
expect(user.deletionScheduledAt, DateTime.parse('2026-10-09T12:00:00.000Z'));
expect(user.requiresDeletionPassword, isFalse);

final purgeAt = await datasource.requestAccountDeletion(password: 'secret');
expect(purgeAt, DateTime.parse('2026-10-09T12:00:00.000Z'));
await datasource.restoreAccount();
```

- [x] **Step 2: Run tests and confirm missing lifecycle symbols fail**

Run: `flutter test test/features/auth/data/models/user_model_test.dart test/features/auth/data/datasources/auth_remote_datasource_test.dart`

- [x] **Step 3: Implement lifecycle parsing and exact REST payloads**

```dart
enum AccountStatus { active, pendingDeletion, inactive, deleted, unknown }

Future<DateTime> requestAccountDeletion({String? password});
Future<void> restoreAccount();
```

- [x] **Step 4: Run the two tests and confirm they pass**

Run: `flutter test test/features/auth/data/models/user_model_test.dart test/features/auth/data/datasources/auth_remote_datasource_test.dart`

### Task 2: Session state and socket behavior

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_notifier.dart`
- Modify: `lib/core/services/socket_service.dart`
- Test: `test/features/auth/presentation/providers/auth_notifier_test.dart`
- Test: relevant socket-service test discovered in `test/core/services/`

**Interfaces:**
- Consumes: repository operations from Task 1.
- Produces: `AuthNotifier.requestAccountDeletion({String? password})` and `AuthNotifier.restoreAccount()` returning `Failure?`.

- [x] **Step 1: Write failing notifier and socket tests**

```dart
final failure = await notifier.requestAccountDeletion(password: 'secret');
expect(failure, isNull);
expect(notifier.state.user!.isPendingDeletion, isTrue);

final restoreFailure = await notifier.restoreAccount();
expect(restoreFailure, isNull);
expect(notifier.state.status, AuthStatus.unauthenticated);
```

- [x] **Step 2: Run targeted tests and confirm the missing behavior fails**

Run: `flutter test test/features/auth/presentation/providers/auth_notifier_test.dart test/core/services/socket_service_test.dart`

- [x] **Step 3: Implement state transitions and preserve restore-capable pending sessions**

```dart
case 'ACCOUNT_PENDING_DELETION':
  _shouldReconnect = false;
  return;
```

On deletion success, disconnect sockets and replace the in-memory user with pending status and purge date. On restoration success, run the existing logout path so the stale pending-status JWT is cleared.

- [x] **Step 4: Run targeted state and socket tests**

Run: `flutter test test/features/auth/presentation/providers/auth_notifier_test.dart test/core/services/socket_service_test.dart`

### Task 3: Profile privacy and recovery UI

**Files:**
- Create: `lib/features/auth/presentation/widgets/account_deletion_section.dart`
- Modify: `lib/features/auth/presentation/pages/profile_tab.dart`
- Test: `test/features/auth/presentation/widgets/account_deletion_section_test.dart`
- Test: `test/features/auth/presentation/pages/profile_tab_test.dart`

**Interfaces:**
- Consumes: `User.requiresDeletionPassword`, `User.deletionScheduledAt`, and the Task 2 notifier operations.
- Produces: active privacy action, destructive confirmation sheet, pending warning card, and restore action.

- [x] **Step 1: Write failing widget tests for active, social, loading, error, pending, small-width, and text-scaled states**

```dart
expect(find.text('PRIVACIDAD'), findsOneWidget);
await tester.tap(find.byKey(const Key('request-account-deletion')));
expect(find.byKey(const Key('delete-account-password-field')), findsOneWidget);
expect(find.byKey(const Key('delete-account-confirmation-field')), findsOneWidget);
```

- [x] **Step 2: Run widget tests and confirm the section is absent**

Run: `flutter test test/features/auth/presentation/widgets/account_deletion_section_test.dart test/features/auth/presentation/pages/profile_tab_test.dart`

- [x] **Step 3: Implement the design-system-compliant profile states**

Use a safe-area modal sheet, exact `DELETE` confirmation, conditional password field, 48 dp actions, inline live-region errors, disabled/loading submit states, localized purge date, and a pending profile that hides operational sections while keeping identity and logout available.

- [x] **Step 4: Run widget tests and confirm all states pass without overflow**

Run: `flutter test test/features/auth/presentation/widgets/account_deletion_section_test.dart test/features/auth/presentation/pages/profile_tab_test.dart`

### Task 4: Regression verification

**Files:**
- Verify all files changed in Tasks 1-3.

**Interfaces:**
- Consumes: completed feature.
- Produces: formatted, analyzed, regression-tested mobile integration.

- [x] **Step 1: Format only touched Dart files**

Run: `dart format <touched Dart files>`

- [x] **Step 2: Analyze the application**

Run: `flutter analyze`

- [x] **Step 3: Run the complete test suite**

Run: `flutter test`

- [x] **Step 4: Review the final diff for unrelated changes**

Run: `git diff --check` and `git diff -- <touched files>`
