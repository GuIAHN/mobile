# Home Marketplace Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved guIAutomotriz Home with an accessible orange header, three direct service actions, ranked workshops/mechanics, and a restrained raised center logo while preserving existing role behavior and user-authored navigation insets.

**Architecture:** Keep `HomePage` as the existing tab/scaffold coordinator and split the consumer Home into focused public widgets: header, selected vehicle, direct actions, and ranked provider sections. Reuse the existing Riverpod providers, routes, wizard, and role mapping; only add small seams for deterministic ranking, vehicle preselection, state rendering, and widget tests.

**Tech Stack:** Flutter, Dart, Riverpod 2, go_router, google_fonts, flutter_test, mocktail.

## Global Constraints

- `DESIGN_SYSTEM.md` remains the source of truth: Hanken Grotesk, `AppColors.background`, white cards, orange brand accents, 4/8 dp spacing, and rounded surfaces.
- White header copy must use `AppColors.primaryDark`, not `AppColors.primary`, to meet contrast.
- Preserve the user-authored `Scaffold.extendBody`, `bottomNavContentInset`, SnackBar margin, and content-padding changes already present in `home_page.dart` and `bottom_nav_bar.dart`.
- Do not touch the unrelated dirty files `android/gradle.properties`, `android/gradle/wrapper/gradle-wrapper.properties`, or `lib/core/config/env.dart`.
- Consumer Home order is header → `¿Qué necesitas hoy?` → three actions → `Talleres mejor valorados` → `Mecánicos mejor valorados`.
- Bottom navigation remains `Inicio`, `Chats`, centered official logo, `Compras`, `Perfil`; the logo returns Home and has no text label.
- All touch targets are at least 48×48 dp, semantics are explicit, text supports 1.3× and 2.0× scaling, safe areas are respected, and motion honors `MediaQuery.disableAnimations`.
- Ranked sections show up to three providers ordered by rating descending, reviews descending, then distance ascending.
- Loading, empty, error/retry, and data states must be visible; no raw exception strings.
- No new dependency and no backend endpoint change.
- Production changes use TDD: add a focused test, observe its expected failure, add minimal implementation, then rerun focused and regression tests.

---

### Task 1: Provider Ranking Contract and Parsing

**Files:**
- Modify: `lib/features/home/data/models/provider_model.dart`
- Modify: `lib/features/home/presentation/providers/home_providers.dart`
- Create: `test/features/home/data/models/provider_model_test.dart`
- Create: `test/features/home/presentation/providers/top_providers_provider_test.dart`

**Interfaces:**
- Consumes: `HomeItem`, `ProviderModel.fromJson(Map<String, dynamic>, ServiceType)`, `homeItemsProvider(ServiceType)`.
- Produces: `int providerRankComparison(HomeItem a, HomeItem b)` and `topProvidersProvider(ServiceType)` with exactly the approved ranking and a maximum of three items.

- [ ] **Step 1: Write failing parser tests**

Create `provider_model_test.dart` with tests that parse `ratingCount`, `rating_count`, and `reviews` into `HomeItem.reviews`, and assert a missing value becomes `0`. Use complete payloads containing `id`, `nombre`, `rating`, `distancia_km`, and `especialidades` so failures are specifically about review parsing.

- [ ] **Step 2: Verify parser tests fail for review counts**

Run: `flutter test test/features/home/data/models/provider_model_test.dart`

Expected: the nonzero review-count cases fail because production currently hardcodes `reviews: 0`.

- [ ] **Step 3: Implement tolerant review-count parsing**

In `ProviderModel.fromJson`, calculate:

```dart
final rawReviews = json['ratingCount'] ??
    json['rating_count'] ??
    json['reviews'];
final reviews = rawReviews is num
    ? rawReviews.toInt()
    : int.tryParse(rawReviews?.toString() ?? '') ?? 0;
```

and pass `reviews` to the model. Keep the zero fallback honest when the search endpoint omits or malforms the aggregate.

- [ ] **Step 4: Verify parser tests pass**

Run: `flutter test test/features/home/data/models/provider_model_test.dart`

Expected: all parser tests pass.

- [ ] **Step 5: Write failing ranking tests**

Create fixtures that prove, independently, rating wins first, review count breaks equal-rating ties, distance breaks equal-rating/equal-review ties, only three items remain, and the input list is not mutated. Override `homeItemsProvider` in a `ProviderContainer`, await `container.read(homeItemsProvider(ServiceType.workshops).future)`, then read `topProvidersProvider(ServiceType.workshops).requireValue`.

- [ ] **Step 6: Verify ranking tests fail for tie-break and limit**

Run: `flutter test test/features/home/presentation/providers/top_providers_provider_test.dart`

Expected: ordering by reviews and the three-item limit fail against the current provider.

- [ ] **Step 7: Implement the ranking comparator and limit**

Add a top-level pure comparator:

```dart
int providerRankComparison(HomeItem a, HomeItem b) {
  final byRating = b.rating.compareTo(a.rating);
  if (byRating != 0) return byRating;
  final byReviews = b.reviews.compareTo(a.reviews);
  if (byReviews != 0) return byReviews;
  final byDistance = a.distanceKm.compareTo(b.distanceKm);
  if (byDistance != 0) return byDistance;
  final byName = a.name.compareTo(b.name);
  if (byName != 0) return byName;
  return (a.id ?? '').compareTo(b.id ?? '');
}
```

Sort a copied list with this function and return `list.take(3).toList(growable: false)`.

- [ ] **Step 8: Verify Task 1 tests and regressions**

Run: `flutter test test/features/home/data/models/provider_model_test.dart test/features/home/presentation/providers/top_providers_provider_test.dart test/features/vehicles/vehicle_models_test.dart`

Expected: all selected tests pass.

- [ ] **Step 9: Commit Task 1**

```bash
git add lib/features/home/data/models/provider_model.dart lib/features/home/presentation/providers/home_providers.dart test/features/home/data/models/provider_model_test.dart test/features/home/presentation/providers/top_providers_provider_test.dart
git commit -m "feat: rank top automotive providers"
```

---

### Task 2: Ranked Provider Section States

**Files:**
- Modify: `lib/features/home/presentation/widgets/sections/top_providers_section.dart`
- Create: `test/features/home/presentation/widgets/top_providers_section_test.dart`

**Interfaces:**
- Consumes: `topProvidersProvider(ServiceType)`, `homeItemsProvider(ServiceType)`, `RouteNames.workshops`, `RouteNames.mechanics`.
- Produces: public `TopProvidersSection` rendering loading, empty, error/retry, and ranked data states.

- [ ] **Step 1: Write failing widget-state tests**

Mount `TopProvidersSection` in `ProviderScope` and `MaterialApp.router` with a tiny `GoRouter`. Override `topProvidersProvider` with:

```dart
const AsyncValue.loading()
const AsyncValue.data([])
AsyncValue.error(Exception('database secret'), StackTrace.empty)
AsyncValue.data([fixture])
```

Assert three skeleton keys in loading; `Todavía no hay talleres valorados` plus `Ver todos` in empty; `No pudimos cargar los talleres` and `Reintentar` in error with no `database secret`; and rank `1`, rating, reviews, distance, and `Abierto` in data. Also assert `Ver todos` reaches a route marker.

- [ ] **Step 2: Verify widget-state tests fail**

Run: `flutter test test/features/home/presentation/widgets/top_providers_section_test.dart`

Expected: empty/error/rank assertions fail because the section currently hides those states.

- [ ] **Step 3: Implement state UI and accessible actions**

Remove the early empty-section return. Keep the title in every state. Render keyed skeletons; a compact white empty card; and a compact white error card with human copy plus a 48 dp `TextButton.icon` that calls:

```dart
ref.invalidate(homeItemsProvider(serviceType));
```

Use `TextButton` for `Ver todos` with `minimumSize: const Size(48, 48)`. Add a rank badge to each `_ProviderCard`, pass `rank: index + 1`, and use `Material`/`InkWell` with semantics rather than a bare `GestureDetector`.

- [ ] **Step 4: Make live social proof honest**

When `item.reviews > 0`, render the count; otherwise render `Sin reseñas`. Keep rating visible because it is returned independently by the API.

- [ ] **Step 5: Verify Task 2 tests**

Run: `flutter test test/features/home/presentation/widgets/top_providers_section_test.dart test/features/home/presentation/providers/top_providers_provider_test.dart`

Expected: all selected tests pass.

- [ ] **Step 6: Commit Task 2**

```bash
git add lib/features/home/presentation/widgets/sections/top_providers_section.dart test/features/home/presentation/widgets/top_providers_section_test.dart
git commit -m "feat: add ranked provider home states"
```

---

### Task 3: Selected Vehicle Header and Wizard Preselection

**Files:**
- Modify: `lib/features/home/presentation/widgets/header/home_header_expanded.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart`
- Create: `test/features/home/presentation/widgets/home_header_expanded_test.dart`
- Create: `test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

**Interfaces:**
- Consumes: `authProvider`, `userCarsProvider`, `searchVehicleProvider`, `searchVehicleVariantIdProvider`, `GarageVehicleSelectorSheet.show`.
- Produces: `HomeHeaderExpanded` with selected-vehicle UI and `SparePartWizardPage({UserCar? initialVehicle, String? initialVariantId, VoidCallback? onSubmitted})` plus matching `show` parameters.

- [ ] **Step 1: Write failing wizard-preselection test**

Mount `SparePartWizardPage(initialVehicle: fixtureCar, initialVariantId: 'variant-1')`, override `userCarsProvider` with a finite list, pump explicit frames, and assert the selected vehicle is present and the wizard starts with its vehicle state populated rather than requiring an empty selection. Step 1 renders before catalog data is requested, so no catalog override is needed.

- [ ] **Step 2: Verify wizard-preselection test fails to compile**

Run: `flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

Expected: failure because `initialVehicle` and `initialVariantId` do not exist.

- [ ] **Step 3: Add optional preselection to the wizard**

Add nullable fields and `show` parameters. Initialize `_selectedVehicle` and `_temporaryModelId` in `initState` from the widget. Keep `_currentStep = 1`; preselection reduces work but does not skip the visible vehicle-confirmation step.

- [ ] **Step 4: Verify wizard-preselection test passes**

Run: `flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

Expected: test passes.

- [ ] **Step 5: Write failing header tests**

Use a fake `LocationService` returning `LocationPermission.denied` and override authenticated user/garage providers. Assert `AppColors.primaryDark`, `Hola, Elio`, the first-car fallback `Audi 4000`, a minimum 48 dp location target, and absence of the notification button when `onNotificationsTap` is null. Add empty-garage coverage for `Seleccionar vehículo` and honest `Ubicación desactivada` copy.

- [ ] **Step 6: Verify header tests fail against the old header**

Run: `flutter test test/features/home/presentation/widgets/home_header_expanded_test.dart`

Expected: dark-orange, selected-vehicle, honest-location, and inert-bell assertions fail.

- [ ] **Step 7: Implement the approved header**

Patch the existing permission/dialog logic without deleting it. Use `AppColors.primaryDark`, fix greeting punctuation, replace the hard-coded street with state copy, hide an inert bell, and render a bordered translucent selected-vehicle control. On selection, update `searchVehicleProvider` and `searchVehicleVariantIdProvider`. The control and all icon buttons use 48 dp constraints and explicit semantics.

- [ ] **Step 8: Verify Task 3 tests**

Run: `flutter test test/features/home/presentation/widgets/home_header_expanded_test.dart test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

Expected: all selected tests pass.

- [ ] **Step 9: Commit Task 3**

```bash
git add lib/features/home/presentation/widgets/header/home_header_expanded.dart lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart test/features/home/presentation/widgets/home_header_expanded_test.dart test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
git commit -m "feat: add vehicle-aware orange home header"
```

---

### Task 4: Three Responsive Direct Actions

**Files:**
- Modify: `lib/features/home/presentation/widgets/navigation/category_grid.dart`
- Create: `test/features/home/presentation/widgets/category_grid_test.dart`

**Interfaces:**
- Consumes: current role's `allowedServiceTypes`, `searchVehicleProvider`, `searchVehicleVariantIdProvider`, `RouteNames.workshops`, `RouteNames.mechanics`, and the new wizard preselection parameters.
- Produces: public `CategoryGrid` with three equal direct actions for consumers and existing role restrictions for providers.

- [ ] **Step 1: Write failing layout and navigation tests**

Mount `CategoryGrid` under a consumer override and a minimal router. Assert exact labels `Solicitar repuesto`, `Buscar talleres`, and `Buscar mecánicos`; tap workshops/mechanics and assert route markers. Assert each semantic action has a button role and at least 48 dp bounds. Pump at widths 375 and 430 with text scales 1.0, 1.3, and 2.0 while capturing `FlutterError.onError`; assert no overflow exceptions.

- [ ] **Step 2: Verify action tests fail against current labels/layout**

Run: `flutter test test/features/home/presentation/widgets/category_grid_test.dart`

Expected: exact labels, semantics, and high-text-scale layout fail.

- [ ] **Step 3: Implement responsive equal-action cards**

Use `LayoutBuilder`, three `Expanded` cards, 8 dp gaps, 16–20 dp radii, white surfaces, fine borders, orange outline icons, two-line labels, and visible arrows. Use `Material`/`InkWell` plus `Semantics`. On spare-parts tap, call:

```dart
SparePartWizardPage.show(
  context,
  initialVehicle: ref.read(searchVehicleProvider),
  initialVariantId: ref.read(searchVehicleVariantIdProvider),
);
```

Use 150–200 ms press feedback only when animations are enabled. Preserve `allowedServiceTypes` filtering and store-dashboard behavior.

- [ ] **Step 4: Add spare-parts navigation assertion**

Provide a selected fixture car, tap `Solicitar repuesto`, and assert the wizard route contains that vehicle. This proves the Header → shared provider → direct action → wizard data flow.

- [ ] **Step 5: Verify Task 4 tests**

Run: `flutter test test/features/home/presentation/widgets/category_grid_test.dart test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

Expected: all selected tests pass without overflows.

- [ ] **Step 6: Commit Task 4**

```bash
git add lib/features/home/presentation/widgets/navigation/category_grid.dart test/features/home/presentation/widgets/category_grid_test.dart
git commit -m "feat: add direct home service actions"
```

---

### Task 5: Bottom Navigation Geometry and Accessibility

**Files:**
- Modify: `lib/features/home/presentation/widgets/navigation/bottom_nav_bar.dart`
- Create: `test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

**Interfaces:**
- Consumes: `homeTabProvider`, `currentRoleProvider`, `assets/images/logo_icon.png`, `bottomNavContentInset(BuildContext)`.
- Produces: unchanged tab indices with consumer labels `Inicio`, `Chats`, `Compras`, `Perfil` and a 64 dp raised center-logo action.

- [ ] **Step 1: Write failing nav tests**

Mount `BottomNavBar` with a consumer provider container and controlled `MediaQuery`. Assert four text labels, center asset presence, semantic label `Volver al inicio, logo guIAutomotriz`, 64 dp logo bounds, and five visual positions. Set `homeTabProvider` to 1, tap `Compras`, then `Perfil`, then the logo and assert indices `2`, `3`, and `0`. Add a store test that preserves its current index mapping and omits purchases.

- [ ] **Step 2: Verify geometry/semantics tests fail**

Run: `flutter test test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

Expected: the current 88 dp logo and generic `Inicio` semantics fail.

- [ ] **Step 3: Refine the existing user-authored nav without reverting it**

Keep `kBottomNavOverhang`, `kBottomNavBarHeight`, `bottomNavContentInset`, the bar Stack, and role index logic. Change the visual logo size to 64 dp, reserve the appropriate center gap, and position it 10–12 dp higher than the prior mockup while keeping the hit target at least 64 dp. Use the official asset unchanged. Replace bare nav `GestureDetector`s with `InkResponse`/`InkWell`, add selected semantics, and disable scale animation when reduced motion is enabled. Display `Compras`, not `Mis Compras`, for the approved consumer copy.

- [ ] **Step 4: Verify Task 5 tests**

Run: `flutter test test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

Expected: consumer/store mapping, geometry, and semantics pass.

- [ ] **Step 5: Commit Task 5 without including unrelated dirty files**

```bash
git add lib/features/home/presentation/widgets/navigation/bottom_nav_bar.dart test/features/home/presentation/widgets/bottom_nav_bar_test.dart
git commit -m "feat: refine branded bottom navigation"
```

---

### Task 6: Integrate the Approved Consumer Home

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Replace: `test/home_filters_test.dart`
- Create: `test/features/home/presentation/pages/home_page_test.dart`

**Interfaces:**
- Consumes: `HomeHeaderExpanded`, `CategoryGrid`, `TopProvidersSection`, `BottomNavBar`, role state, existing tab pages, and existing bottom-nav inset helpers.
- Produces: the approved consumer Home composition while leaving store dashboard and non-Home tabs working.

- [ ] **Step 1: Replace the stale failing Home test**

The existing `test/home_filters_test.dart` asserts the removed pre-hub inline form and currently times out while loading ads. Replace its body with a focused `HomeFilters.toQueryParams` test that verifies the existing contract (`radiusKm`, `minRating`, `specialtyIds`, `orderBy`, `lat`, `lng`) without mounting Home. Do not retain assertions for `CATEGORÍA DE REPUESTO *` on Home.

- [ ] **Step 2: Write failing Home composition tests**

Mount `HomePage` with a consumer user, finite garage/promo/provider overrides, fake location service, and a minimal router. Assert the first-occurrence order of `¿Qué necesitas hoy?`, `Solicitar repuesto`, promo copy, `Talleres mejor valorados`, and `Mecánicos mejor valorados`. Assert `Mi garage` is absent, while the promotional banner, `Chats`, `Compras`, and the center logo remain. Test loading, empty, error, and data provider variants through overrides.

- [ ] **Step 3: Verify Home composition tests fail**

Run: `flutter test test/features/home/presentation/pages/home_page_test.dart`

Expected: the missing question, misplaced primary flow, and mechanic-before-workshop order fail.

- [ ] **Step 4: Patch `_buildHomeHub` narrowly**

Preserve the existing welcome Snackbar, `extendBody`, tab switching, non-Home padding, approval overlay, scroll controller, bottom inset, and promotional banner. Remove only the expanded garage section from the consumer flow. Compose:

```dart
const HomeHeaderExpanded(),
const Padding(..., child: Text('¿Qué necesitas hoy?')),
const Padding(..., child: CategoryGrid()),
PromoCarousel(...),
TopProvidersSection(workshops, 'Talleres mejor valorados'),
TopProvidersSection(mechanic, 'Mecánicos mejor valorados'),
```

Keep `StoreDashboardView` and role-allowed sections intact for provider/store accounts. Use `AppColors.background`, Hanken Grotesk 24/700 for the Home question, and existing 20/24 dp gutters.

- [ ] **Step 5: Honor reduced motion in Home tab switching**

When `MediaQuery.disableAnimations` is true, use `Duration.zero` for the `AnimatedSwitcher`; otherwise keep a restrained 200–250 ms transition.

- [ ] **Step 6: Verify Home layout matrix**

Run: `flutter test test/features/home/presentation/pages/home_page_test.dart test/features/home/presentation/widgets/category_grid_test.dart test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

Expected: tests pass at 375/430 widths and 1.0/1.3/2.0 text scales with no overflow or safe-area exceptions.

- [ ] **Step 7: Commit Task 6**

```bash
git add lib/features/home/presentation/pages/home_page.dart test/home_filters_test.dart test/features/home/presentation/pages/home_page_test.dart
git commit -m "feat: implement marketplace home redesign"
```

---

### Task 7: Full Quality Gate and Visual Verification

**Files:**
- Modify only files required to correct findings from the commands below.

**Interfaces:**
- Consumes: all Task 1–6 output.
- Produces: formatted, analyzed, tested implementation with a visually inspected Home.

- [ ] **Step 1: Format only changed Dart files**

Run `dart format` with the exact modified/created Dart paths from Tasks 1–6. Do not run a bulk rewrite across unrelated files.

- [ ] **Step 2: Run focused Home suite**

Run:

```bash
flutter test \
  test/features/home/data/models/provider_model_test.dart \
  test/features/home/presentation/providers/top_providers_provider_test.dart \
  test/features/home/presentation/widgets/top_providers_section_test.dart \
  test/features/home/presentation/widgets/home_header_expanded_test.dart \
  test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart \
  test/features/home/presentation/widgets/category_grid_test.dart \
  test/features/home/presentation/widgets/bottom_nav_bar_test.dart \
  test/features/home/presentation/pages/home_page_test.dart
```

Expected: all focused tests pass with zero failures.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`

Expected: no new analyzer errors or warnings in changed files. If the repository has pre-existing findings, record exact output and prove the changed-file subset is clean.

- [ ] **Step 4: Run the complete regression suite**

Run: `flutter test`

Expected: all tests pass, including the replacement for the stale Home test.

- [ ] **Step 5: Render and inspect representative screenshots**

Run the available Flutter target or golden harness at 375×812 and 430×932, inspect both screenshots, and compare them to the approved mockup. Verify header color, three above-fold actions, workshop-before-mechanic order, elevated logo, no clipped text, and content clearance above the nav. If no device target is available, use deterministic widget screenshots/goldens under `test/` and inspect the PNGs.

- [ ] **Step 6: Run UI/UX validation search and checklist**

Run:

```bash
python3 /Users/eliocolmenares/.agents/skills/ui-ux-pro-max/scripts/search.py "animation accessibility z-index loading touch targets text scaling safe areas" --domain ux -n 12
```

Check every applicable result plus `AGENTS.md`: loading/error/empty/data, contrast, 48 dp targets, text scaling, safe areas, reduced motion, 375/430 widths.

- [ ] **Step 7: Inspect scope and whitespace**

Run:

```bash
git diff --check
git status --short
git diff --stat HEAD~6..HEAD
```

Expected: no whitespace errors, no unrelated dirty file included in feature commits, and only the approved Home scope changed.

- [ ] **Step 8: Commit any quality-gate corrections**

If Step 1–7 required code fixes, stage only those files and commit:

```bash
git commit -m "fix: polish marketplace home accessibility"
```

If no correction was required, do not create an empty commit.
