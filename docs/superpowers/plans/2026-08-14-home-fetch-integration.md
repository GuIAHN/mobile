# Home Fetch Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cargar talleres y mecánicos destacados con una única petición de Home y alimentar el indicador de la campana con el conteo real de notificaciones no leídas.

**Architecture:** Un datasource de Home obtiene el payload agrupado y `HomeRepository` lo convierte a una entidad con ambas listas reutilizando `ProviderModel`. Un `FutureProvider` compartido ejecuta la petición una vez y dos providers derivados seleccionan talleres o mecánicos. El conteo de notificaciones usa un datasource pequeño y un provider independiente observado por `HomePage`.

**Tech Stack:** Flutter 3, Dart, Riverpod 2.5, Dio, dartz, mocktail, flutter_test.

## Global Constraints

- Ejecutar exactamente una petición a `home/top-providers` por carga del Home.
- Mantener al backend como fuente de verdad del orden y el máximo de cinco elementos.
- No cambiar la interfaz visual ni agregar dependencias.
- Reutilizar `ProviderModel` y el manejo de errores de `HomeRepositoryImpl`.
- Los errores de `unread-count` no deben bloquear el Home.
- Preservar los cambios locales existentes ajenos a esta integración.

---

## File Structure

- Create: `lib/features/home/data/datasources/home_remote_datasource.dart`
- Create: `lib/features/home/domain/entities/top_providers_result.dart`
- Create: `lib/features/home/domain/usecases/get_top_providers_usecase.dart`
- Modify: `lib/core/network/api_endpoints.dart`
- Modify: `lib/features/home/data/models/provider_model.dart`
- Modify: `lib/features/home/domain/repositories/home_repository.dart`
- Modify: `lib/features/home/data/repositories/home_repository_impl.dart`
- Modify: `lib/features/home/presentation/providers/home_providers.dart`
- Modify: `lib/features/home/presentation/widgets/sections/top_providers_section.dart`
- Create: `lib/features/notifications/data/datasources/notifications_remote_datasource.dart`
- Create: `lib/features/notifications/presentation/providers/notifications_providers.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Add/modify focused tests under `test/features/home` and `test/features/notifications`.

---

### Task 1: Parse and fetch the grouped top-providers contract

**Files:**
- Modify: `lib/core/network/api_endpoints.dart`
- Create: `lib/features/home/data/datasources/home_remote_datasource.dart`
- Modify: `lib/features/home/data/models/provider_model.dart`
- Test: `test/features/home/data/datasources/home_remote_datasource_test.dart`
- Test: `test/features/home/data/models/provider_model_test.dart`

**Interfaces:**
- Produces: `HomeRemoteDatasource.getTopProviders({double? lat, double? lng})` returning `Future<Map<String, dynamic>>`.
- Produces: `ProviderModel.fromJson(json, type)` compatible with search and Home contracts.

- [ ] **Step 1: Write failing HTTP and parser tests**

Test that the datasource calls `home/top-providers`, adds `lat/lng` only as a complete pair, and returns the grouped map. Add a model test using `name`, `description`, `ratingCount`, `distanceKm`, `specialties`, and `photo`.

- [ ] **Step 2: Verify RED**

```bash
flutter test test/features/home/data/datasources/home_remote_datasource_test.dart test/features/home/data/models/provider_model_test.dart
```

Expected: FAIL because the endpoint/datasource and English aliases do not exist.

- [ ] **Step 3: Implement minimal route, datasource, and aliases**

Add `ApiEndpoints.homeTopProviders = 'home/top-providers'` and `ApiEndpoints.notificationsUnreadCount = 'me/notifications/unread-count'`. Build query parameters with both coordinates only when both exist. Resolve aliases without adding a duplicate provider model.

- [ ] **Step 4: Verify GREEN and commit**

Run Step 2, then commit only Task 1 files with `feat: fetch grouped home providers`.

---

### Task 2: Share one request across both top sections

**Files:**
- Create: `lib/features/home/domain/entities/top_providers_result.dart`
- Create: `lib/features/home/domain/usecases/get_top_providers_usecase.dart`
- Modify: `lib/features/home/domain/repositories/home_repository.dart`
- Modify: `lib/features/home/data/repositories/home_repository_impl.dart`
- Modify: `lib/features/home/presentation/providers/home_providers.dart`
- Modify: `lib/features/home/presentation/widgets/sections/top_providers_section.dart`
- Modify: `test/features/home/presentation/providers/top_providers_provider_test.dart`

**Interfaces:**
- Produces: `TopProvidersResult({required workshops, required mechanics})`.
- Produces: `HomeRepository.getTopProviders({double? lat, double? lng})`.
- Produces: `homeTopProvidersProvider` returning `AsyncValue<TopProvidersResult>`.
- Preserves: `topProvidersProvider(ServiceType)` returning `AsyncValue<List<HomeItem>>`.

- [ ] **Step 1: Write failing shared-fetch tests**

Use a fake repository with a call counter. Observe workshop and mechanic providers, await both, and assert one repository call, correct list selection, preserved backend order, and no mobile-side truncation. Add cases for active coordinates and absent position.

- [ ] **Step 2: Verify RED**

```bash
flutter test test/features/home/presentation/providers/top_providers_provider_test.dart
```

Expected: FAIL because both tops still derive from general searches.

- [ ] **Step 3: Implement entity, repository, use case, and provider**

Map `workshops` and `mechanics` through `ProviderModel.fromJsonList`. `homeTopProvidersProvider` waits for `userLocationProvider` to leave its loading state when sharing is active, then calls the use case exactly once with the resulting coordinates; if sharing is inactive it calls once without coordinates. `topProvidersProvider` only selects a list. Remove local ranking/truncation. Retry invalidates `homeTopProvidersProvider`.

- [ ] **Step 4: Verify GREEN and commit**

```bash
flutter test test/features/home/presentation/providers/top_providers_provider_test.dart test/features/home/presentation/widgets/top_providers_section_test.dart
```

Commit Task 2 files with `feat: share home top providers request`.

---

### Task 3: Fetch unread notifications for the bell

**Files:**
- Create: `lib/features/notifications/data/datasources/notifications_remote_datasource.dart`
- Create: `lib/features/notifications/presentation/providers/notifications_providers.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Test: `test/features/notifications/data/datasources/notifications_remote_datasource_test.dart`
- Modify: `test/features/home/presentation/pages/home_page_test.dart`

**Interfaces:**
- Produces: `NotificationsRemoteDatasource.getUnreadCount()` returning `Future<int>`.
- Produces: `unreadNotificationsCountProvider` returning `AsyncValue<int>`.

- [ ] **Step 1: Write failing datasource and Home tests**

Assert the exact endpoint, numeric/string parsing, and zero when `count` is absent. Override the provider with `7` and assert `HomeHeaderExpanded.hasUnreadNotifications == true`; override with an error and assert false without a build exception.

- [ ] **Step 2: Verify RED**

```bash
flutter test test/features/notifications/data/datasources/notifications_remote_datasource_test.dart test/features/home/presentation/pages/home_page_test.dart --plain-name "notification"
```

Expected: FAIL because the datasource/provider do not exist and Home uses chat state.

- [ ] **Step 3: Implement datasource, provider, and Home wiring**

Parse `count` with `num.toInt()` or `int.tryParse`, defaulting to zero. Home derives the dot from `unreadNotificationsCountProvider.valueOrNull`; an AsyncError therefore leaves the dot hidden and the rest of Home operational. Preserve the existing tap action.

- [ ] **Step 4: Verify GREEN and commit**

Run Step 2, then commit Task 3 files with `feat: connect unread notifications count`.

---

### Task 4: Final verification

- [ ] **Step 1: Run all focused Home and notifications tests**

```bash
flutter test test/features/home/data/datasources/home_remote_datasource_test.dart test/features/home/data/models/provider_model_test.dart test/features/home/presentation/providers/top_providers_provider_test.dart test/features/home/presentation/widgets/top_providers_section_test.dart test/features/notifications/data/datasources/notifications_remote_datasource_test.dart test/features/home/presentation/pages/home_page_test.dart
```

- [ ] **Step 2: Analyze every changed Dart file**

Run `dart analyze` with the explicit changed-file list and require `No issues found`.

- [ ] **Step 3: Run `flutter test` and record unrelated failures separately**

- [ ] **Step 4: Run `git diff --check` and confirm unrelated dirty files remain untouched**
