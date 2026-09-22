# Request Location Map Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Permitir que una solicitud de repuesto use un punto elegido en un mapa de pantalla completa, sin modificar la ubicación global o habitual del usuario, y corregir la fuente de verdad del encabezado.

**Architecture:** El asistente conservará una selección de ubicación local e inmutable y abrirá un diálogo de pantalla completa que trabaja con un borrador hasta confirmar. El backend seguirá recibiendo lat/lon y usando PostGIS, pero validará el par y aceptará coordenadas cero. La ubicación global del encabezado se obtendrá una sola vez mediante userLocationProvider y el nombre se resolverá desde esa misma posición.

**Tech Stack:** Flutter 3 / Dart, Riverpod 2.5, flutter_map 7, latlong2, geolocator, geocoding, NestJS 11, class-validator, Jest 30, PostGIS.

## Global Constraints

- Mantener exactamente tres pasos en el asistente.
- La ubicación manual solo pertenece a la solicitud actual.
- No integrar Google Places, Google Maps, sectores, rutas ni navegación.
- No agregar dependencias nuevas.
- DESIGN_SYSTEM.md manda: Hanken Grotesk, fondo #F5F6FA, primario #F25C05, radios mínimos de 14 px y CTA pill.
- Acciones táctiles de al menos 48 dp en Android y 44 pt en iOS.
- Soportar texto ampliado, áreas seguras, teléfonos pequeños/grandes, paisaje y reducción de movimiento.
- La geocodificación inversa es informativa; las coordenadas siguen siendo válidas si falla.
- Preservar los cambios locales existentes en env.dart, providers_list_page.dart, error_view.dart, staggered_entrance.dart y providers_list_page_test.dart.

---

## File Structure

### Mobile

- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart — valor inmutable.
- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart — selector de pantalla completa.
- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart — tarjeta compacta.
- Modify: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart — estado, diálogo y payload.
- Modify: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step3.dart — integración de la tarjeta.
- Modify: lib/features/home/presentation/widgets/header/home_header_expanded.dart — una fuente de coordenadas.
- Create: test/features/home/presentation/widgets/request_location_picker_dialog_test.dart.
- Create: test/features/home/presentation/widgets/request_location_preview_test.dart.
- Modify: test/features/home/presentation/widgets/home_header_expanded_test.dart.

### Backend

- Modify: backend/src/modules/search/dto/create-search.dto.ts.
- Modify: backend/src/modules/search/search.service.ts.
- Create: backend/src/modules/search/dto/create-search.dto.spec.ts.
- Create: backend/src/modules/search/search.service.spec.ts.

---

### Task 1: Validate request coordinates in the backend

**Files:**
- Create: backend/src/modules/search/dto/create-search.dto.spec.ts
- Create: backend/src/modules/search/search.service.spec.ts
- Modify: backend/src/modules/search/dto/create-search.dto.ts
- Modify: backend/src/modules/search/search.service.ts:59-65

**Interfaces:**
- Consumes: CreateSearchDto.lat?: number and CreateSearchDto.lon?: number.
- Produces: a complete valid pair or a validation error; explicit request coordinates always win over the profile fallback.

- [ ] **Step 1: Write failing DTO validation tests**

~~~ts
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateSearchDto } from './create-search.dto';

const base = {
  userCarId: '11111111-1111-4111-8111-111111111111',
  subcategoryId: '22222222-2222-4222-8222-222222222222',
};

describe('CreateSearchDto coordinates', () => {
  it.each([
    { lat: 0, lon: 0 },
    { lat: -90, lon: -180 },
    { lat: 90, lon: 180 },
    { lat: 10.4806, lon: -66.9036 },
  ])('accepts a complete valid pair %#', async (coordinates) => {
    const dto = plainToInstance(CreateSearchDto, { ...base, ...coordinates });
    expect(await validate(dto)).toHaveLength(0);
  });

  it.each([
    { lat: 10.4 },
    { lon: -66.9 },
    { lat: 91, lon: 0 },
    { lat: 0, lon: 181 },
  ])('rejects incomplete or invalid coordinates %#', async (coordinates) => {
    const dto = plainToInstance(CreateSearchDto, { ...base, ...coordinates });
    expect(await validate(dto)).not.toHaveLength(0);
  });
});
~~~

- [ ] **Step 2: Run the DTO test and verify it fails**

Run from GuIA-HN-Backend/backend:

~~~bash
npm run test:unit -- --runInBand modules/search/dto/create-search.dto.spec.ts
~~~

Expected: FAIL because invalid or incomplete coordinates are accepted.

- [ ] **Step 3: Implement paired coordinate validation**

Add IsLatitude, IsLongitude and ValidateIf imports, then replace both properties with:

~~~ts
@ValidateIf((dto: CreateSearchDto) =>
  dto.lat !== undefined || dto.lon !== undefined,
)
@IsLatitude({ message: 'lat must be a valid latitude' })
lat?: number;

@ValidateIf((dto: CreateSearchDto) =>
  dto.lat !== undefined || dto.lon !== undefined,
)
@IsLongitude({ message: 'lon must be a valid longitude' })
lon?: number;
~~~

- [ ] **Step 4: Run the DTO test and verify it passes**

Run the command from Step 2. Expected: PASS.

- [ ] **Step 5: Write a failing service test for zero coordinates**

~~~ts
import { SearchService } from './search.service';

describe('SearchService location resolution', () => {
  it('uses explicit zero coordinates instead of profile fallback', async () => {
    const repository = {
      findUserCarById: jest.fn().mockResolvedValue({ userId: 'consumer-1' }),
      findCategoryById: jest.fn().mockResolvedValue({ parentId: 'root-1' }),
      findUserLocation: jest.fn().mockResolvedValue({ lat: 10, lon: 10 }),
      createSearchRequest: jest.fn().mockResolvedValue({ id: 'search-1' }),
      findById: jest.fn().mockResolvedValue({ id: 'search-1' }),
    };
    const service = new SearchService(
      repository as never,
      {} as never,
      {} as never,
      { get: jest.fn().mockReturnValue(48) } as never,
      {} as never,
    );

    await service.createSearchRequest('consumer-1', {
      userCarId: '11111111-1111-4111-8111-111111111111',
      subcategoryId: '22222222-2222-4222-8222-222222222222',
      radiusKm: 50,
      lat: 0,
      lon: 0,
    });

    expect(repository.findUserLocation).not.toHaveBeenCalled();
    expect(repository.createSearchRequest).toHaveBeenCalledWith(
      expect.objectContaining({ location: { lat: 0, lon: 0 } }),
    );
  });
});
~~~

- [ ] **Step 6: Run the service test and verify it fails**

~~~bash
npm run test:unit -- --runInBand modules/search/search.service.spec.ts
~~~

Expected: FAIL because the truthiness check falls back for zero.

- [ ] **Step 7: Use explicit presence checks**

~~~ts
if (dto.lat !== undefined && dto.lon !== undefined) {
  location = { lat: dto.lat, lon: dto.lon };
} else {
  location = await this.searchRepository.findUserLocation(consumerId);
}
~~~

- [ ] **Step 8: Run focused backend tests and commit**

~~~bash
npm run test:unit -- --runInBand modules/search/dto/create-search.dto.spec.ts modules/search/search.service.spec.ts
git add src/modules/search/dto/create-search.dto.ts src/modules/search/dto/create-search.dto.spec.ts src/modules/search/search.service.ts src/modules/search/search.service.spec.ts
git commit -m "fix: validate request search coordinates"
~~~

Expected: both suites PASS.

---

### Task 2: Build the request-local value and fullscreen picker

**Files:**
- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart
- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart
- Create: test/features/home/presentation/widgets/request_location_picker_dialog_test.dart

**Interfaces:**
- Consumes: LocationService.getCurrentPosition(), LocationService.getAddressFromCoordinates(), optional initial selection and center.
- Produces: Future<RequestLocationSelection?> RequestLocationPickerDialog.show(...).

- [ ] **Step 1: Define the immutable selection**

~~~dart
enum RequestLocationSource { gps, mapTap }

class RequestLocationSelection {
  final double latitude;
  final double longitude;
  final String? label;
  final RequestLocationSource source;

  const RequestLocationSelection({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.label,
  });

  String get displayLabel {
    return label ??
        '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
~~~

- [ ] **Step 2: Write failing picker tests**

Provide a mapBuilder seam so tests do not load network tiles:

~~~dart
testWidgets('tap updates the draft and confirm returns it', (tester) async {
  RequestLocationSelection? result;
  await tester.pumpWidget(testApp(
    onResult: (value) => result = value,
    mapBuilder: (context, selection, onMapTap) => GestureDetector(
      key: const Key('fake-location-map'),
      onTap: () => onMapTap(const LatLng(10.4806, -66.9036)),
      child: const SizedBox.expand(),
    ),
  ));

  await tester.tap(find.byKey(const Key('fake-location-map')));
  await tester.pump();
  expect(find.text('10.4806, -66.9036'), findsOneWidget);

  await tester.tap(find.byKey(const Key('confirm-request-location')));
  await tester.pumpAndSettle();
  expect(result?.latitude, 10.4806);
  expect(result?.source, RequestLocationSource.mapTap);
});
~~~

Add the cancellation and GPS cases explicitly:

~~~dart
testWidgets('close discards the draft', (tester) async {
  RequestLocationSelection? result;
  var completed = false;
  await tester.pumpWidget(testApp(
    initialSelection: const RequestLocationSelection(
      latitude: 10.4,
      longitude: -66.9,
      source: RequestLocationSource.mapTap,
    ),
    onResult: (value) {
      completed = true;
      result = value;
    },
  ));
  await tester.tap(find.byKey(const Key('close-request-location')));
  await tester.pumpAndSettle();
  expect(completed, isTrue);
  expect(result, isNull);
});

testWidgets('Mi ubicación creates a GPS draft', (tester) async {
  RequestLocationSelection? result;
  await tester.pumpWidget(testApp(
    locationService: FakeLocationService.at(10.4806, -66.9036),
    onResult: (value) => result = value,
  ));
  await tester.tap(find.byKey(const Key('use-current-request-location')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-request-location')));
  await tester.pumpAndSettle();
  expect(result?.source, RequestLocationSource.gps);
  expect(result?.latitude, 10.4806);
});
~~~

- [ ] **Step 3: Run picker tests and verify failure**

~~~bash
flutter test test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
~~~

Expected: FAIL because the dialog and value do not exist.

- [ ] **Step 4: Implement the dialog interfaces**

~~~dart
typedef RequestLocationMapBuilder = Widget Function(
  BuildContext context,
  RequestLocationSelection? selection,
  ValueChanged<LatLng> onMapTap,
);

class RequestLocationPickerDialog extends ConsumerStatefulWidget {
  final RequestLocationSelection? initialSelection;
  final LatLng initialCenter;
  final RequestLocationMapBuilder? mapBuilder;

  const RequestLocationPickerDialog({
    super.key,
    required this.initialCenter,
    this.initialSelection,
    this.mapBuilder,
  });

  static Future<RequestLocationSelection?> show(
    BuildContext context, {
    required LatLng initialCenter,
    RequestLocationSelection? initialSelection,
  });
}
~~~

Implementation requirements:

- Dialog.fullscreen with SafeArea and AppColors.background.
- FlutterMap using the existing Carto tile URL and package user agent.
- MapOptions.onTap creates a mapTap draft.
- Marker appears only when a draft exists.
- Keys: close-request-location, use-current-request-location, confirm-request-location.
- Close and GPS controls have 48 dp targets and semantic labels.
- GPS reads LocationService directly and never writes global providers.
- Reverse geocoding ignores stale responses by comparing coordinates.
- Coordinates remain visible and valid when reverse geocoding fails.
- Bottom confirmation stays disabled until a draft exists.
- All styling comes from AppColors, AppSpacing, AppTypography and Hanken Grotesk.

- [ ] **Step 5: Format, run tests and commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
flutter test test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
git add lib/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
git commit -m "feat: add fullscreen request location picker"
~~~

Expected: PASS.

---

### Task 3: Integrate the compact card into the three-step wizard

**Files:**
- Create: lib/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart
- Create: test/features/home/presentation/widgets/request_location_preview_test.dart
- Modify: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart
- Modify: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step3.dart

**Interfaces:**
- Consumes: RequestLocationSelection and RequestLocationPickerDialog.show().
- Produces: request-local _requestLocation; submission uses only that value.

- [ ] **Step 1: Write failing preview tests**

~~~dart
testWidgets('empty card invites selection and is at least 96 dp', (tester) async {
  await tester.pumpWidget(materialApp(
    RequestLocationPreview(selection: null, onTap: () {}),
  ));
  expect(find.text('Elegir ubicación'), findsOneWidget);
  expect(
    tester.getSize(find.byKey(const Key('request-location-preview'))).height,
    greaterThanOrEqualTo(96),
  );
  expect(
    find.bySemanticsLabel('Elegir ubicación para esta solicitud'),
    findsOneWidget,
  );
});

testWidgets('selected card shows label and change action', (tester) async {
  await tester.pumpWidget(materialApp(
    RequestLocationPreview(
      selection: const RequestLocationSelection(
        latitude: 10.4806,
        longitude: -66.9036,
        label: 'Sabana Grande, Caracas',
        source: RequestLocationSource.mapTap,
      ),
      onTap: () {},
    ),
  ));
  expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
  expect(find.text('Cambiar'), findsOneWidget);
});
~~~

- [ ] **Step 2: Run preview tests and verify failure**

~~~bash
flutter test test/features/home/presentation/widgets/request_location_preview_test.dart
~~~

Expected: FAIL because RequestLocationPreview does not exist.

- [ ] **Step 3: Implement the compact card**

~~~dart
class RequestLocationPreview extends StatelessWidget {
  final RequestLocationSelection? selection;
  final VoidCallback onTap;

  const RequestLocationPreview({
    super.key,
    required this.selection,
    required this.onTap,
  });
}
~~~

Use Semantics(button: true), Material/InkWell, minimum height 96, radius 20, border token, a 48x48 primary-muted leading icon, wrapping text and a trailing Elegir ubicación/Cambiar action. Do not render GuiaMap.

- [ ] **Step 4: Add local state and modal orchestration**

In _SparePartWizardPageState add:

~~~dart
RequestLocationSelection? _requestLocation;

Future<void> _openRequestLocationPicker() async {
  final shared = ref.read(isLocationSharedProvider);
  final current = ref.read(userLocationProvider).valueOrNull;
  final initialSelection = _requestLocation ??
      (shared && current != null
          ? RequestLocationSelection(
              latitude: current.latitude,
              longitude: current.longitude,
              source: RequestLocationSource.gps,
            )
          : null);

  final result = await RequestLocationPickerDialog.show(
    context,
    initialSelection: initialSelection,
    initialCenter: LatLng(
      initialSelection?.latitude ?? 14.0723,
      initialSelection?.longitude ?? -87.1921,
    ),
  );
  if (result != null && mounted) {
    setState(() => _requestLocation = result);
  }
}
~~~

Pass requestLocation and onLocationTap to step 3. In _submit, require _requestLocation and send its latitude/longitude. Do not read isLocationSharedProvider or userLocationProvider during submission.

- [ ] **Step 5: Replace the inline map in step 3**

Add these inputs:

~~~dart
final RequestLocationSelection? requestLocation;
final VoidCallback onLocationTap;
~~~

Set hasLocation = requestLocation != null, use the blocked message Elige una ubicación para continuar, render RequestLocationPreview, and delete _buildLocationMap plus unused global location watches/imports.

- [ ] **Step 6: Run focused tests and analyzer**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard test/features/home/presentation/widgets/request_location_preview_test.dart
flutter test test/features/home/presentation/widgets/request_location_preview_test.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
flutter analyze lib/features/home/presentation/widgets/spare_part_wizard test/features/home/presentation/widgets/request_location_preview_test.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
~~~

Expected: tests PASS and no scoped analyzer issues.

- [ ] **Step 7: Commit wizard integration**

~~~bash
git add lib/features/home/presentation/widgets/spare_part_wizard test/features/home/presentation/widgets/request_location_preview_test.dart
git commit -m "feat: select request location from map"
~~~

---

### Task 4: Make the home header use one location source

**Files:**
- Modify: test/features/home/presentation/widgets/home_header_expanded_test.dart
- Modify: lib/features/home/presentation/widgets/header/home_header_expanded.dart

**Interfaces:**
- Consumes: UserLocationNotifier.updateLocation() and its stored Position.
- Produces: label and searches based on the same Position; disabling clears active coordinates.

- [ ] **Step 1: Add failing activation/deactivation tests**

Extend _EnabledLocationService with requestPermission() returning whileInUse and record address coordinates. Add a test that taps home-location-control, then asserts:

~~~dart
final position = container.read(userLocationProvider).valueOrNull;
expect(position?.latitude, 10.4806);
expect(container.read(isLocationSharedProvider), isTrue);
expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
expect(service.lastAddressLatitude, 10.4806);
expect(service.lastAddressLongitude, -66.9036);
~~~

Add the deactivation case:

~~~dart
testWidgets('deactivation clears the active search position', (tester) async {
  final service = _EnabledLocationService();
  final container = containerWithLocationService(service);
  addTearDown(container.dispose);
  await pumpHeader(tester, container);

  await tester.tap(find.byKey(const Key('home-location-control')));
  await tester.pumpAndSettle();
  expect(container.read(userLocationProvider).valueOrNull, isNotNull);

  await tester.tap(find.byKey(const Key('home-location-control')));
  await tester.pumpAndSettle();
  expect(container.read(isLocationSharedProvider), isFalse);
  expect(container.read(userLocationProvider).valueOrNull, isNull);
});
~~~

- [ ] **Step 2: Run header tests and verify failure**

~~~bash
flutter test test/features/home/presentation/widgets/home_header_expanded_test.dart
~~~

Expected: FAIL because activation invalidates state and separately reads GPS; deactivation does not clear it.

- [ ] **Step 3: Resolve the name from the notifier Position**

~~~dart
Future<void> _resolveLocationName(Position position) async {
  final service = ref.read(locationServiceProvider);
  final placeName = await service.getAddressFromCoordinates(
    position.latitude,
    position.longitude,
  );
  if (!mounted) return;
  setState(() => _resolvedLocationName = placeName);
}
~~~

Activation must await userLocationProvider.notifier.updateLocation(), set sharing true only after success, read the stored Position and pass it to _resolveLocationName. Failure keeps sharing false and preserves denied/deniedForever recovery. Deactivation calls userLocationProvider.notifier.clear(). Initial restoration resolves an already stored position, or updates once if sharing is true and no position exists.

- [ ] **Step 4: Run header and dependent tests**

~~~bash
dart format lib/features/home/presentation/widgets/header/home_header_expanded.dart test/features/home/presentation/widgets/home_header_expanded_test.dart
flutter test test/features/home/presentation/widgets/home_header_expanded_test.dart test/features/home/presentation/providers/top_providers_provider_test.dart test/features/home/presentation/pages/home_page_test.dart
~~~

Expected: PASS.

- [ ] **Step 5: Commit header fix**

~~~bash
git add lib/features/home/presentation/widgets/header/home_header_expanded.dart test/features/home/presentation/widgets/home_header_expanded_test.dart
git commit -m "fix: share one home location source"
~~~

---

### Task 5: Complete cross-project verification

**Files:**
- Modify only if verification reveals a defect in files already listed above.

**Interfaces:**
- Consumes: deliverables from Tasks 1-4.
- Produces: verified picker, header behavior and coordinate contract.

- [ ] **Step 1: Run focused Flutter tests**

~~~bash
flutter test test/features/home/presentation/widgets/request_location_picker_dialog_test.dart test/features/home/presentation/widgets/request_location_preview_test.dart test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart test/features/home/presentation/widgets/home_header_expanded_test.dart test/features/home/presentation/pages/home_page_test.dart
~~~

Expected: PASS.

- [ ] **Step 2: Run full Flutter analysis and tests**

~~~bash
flutter analyze
flutter test
~~~

Expected: no new analyzer errors and full suite PASS. Record unrelated pre-existing failures without changing unrelated files.

- [ ] **Step 3: Run backend focused tests and build**

From GuIA-HN-Backend/backend:

~~~bash
npm run test:unit -- --runInBand modules/search/dto/create-search.dto.spec.ts modules/search/search.service.spec.ts
npm run build
~~~

Expected: PASS and successful Nest build.

- [ ] **Step 4: Verify UI quality**

Verify empty/selected cards, disabled/enabled submit, fullscreen map, tap marker, current-GPS loading/error/success, close/back preservation, coordinate fallback, 2x text, small/large phones, landscape, safe areas, reduced motion, 48 dp controls and semantics.

- [ ] **Step 5: Review final scope**

~~~bash
git status --short
git diff --check
git diff --stat HEAD~4
~~~

Confirm no API keys, generated files, env.dart or unrelated working-tree changes were included.

- [ ] **Step 6: Commit any verification-only correction**

Only when a correction was required, stage only files named by this plan and commit with:

~~~bash
git commit -m "test: verify request location picker"
~~~
