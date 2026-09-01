import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/entities/place_search_result.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/entities/places_search_response.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/entities/request_location_selection.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/repositories/places_repository.dart';
import 'package:guiautomotriz_mobile/shared/location/presentation/providers/places_providers.dart';
import 'package:guiautomotriz_mobile/shared/location/presentation/widgets/request_location_picker_dialog.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService extends LocationService {
  _FakeLocationService({this.address});

  final String? address;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition() async => Position(
        longitude: -66.9036,
        latitude: 10.4806,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async =>
      address;
}

class _DeniedLocationService extends LocationService {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

class _FakePlacesRepository implements PlacesRepository {
  _FakePlacesRepository({
    this.response = const PlacesSearchResponse(results: []),
    this.failure,
  });

  final PlacesSearchResponse response;
  final Failure? failure;
  String? lastQuery;

  @override
  Future<Either<Failure, PlacesSearchResponse>> search(String query) async {
    lastQuery = query;
    if (failure != null) return Left(failure!);
    return Right(response);
  }
}

Widget _testApp({
  required ValueChanged<RequestLocationSelection?> onResult,
  RequestLocationSelection? initialSelection,
  LocationService? locationService,
  double textScale = 1,
  bool disableAnimations = false,
  ProviderContainer? container,
  PlacesRepository? placesRepository,
}) {
  final app = MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('open-location-picker'),
            onPressed: () async {
              final result = await showDialog<RequestLocationSelection>(
                context: context,
                barrierDismissible: false,
                builder: (_) => RequestLocationPickerDialog(
                  initialCenter: const LatLng(10.4806, -66.9036),
                  initialSelection: initialSelection,
                  mapBuilder: (context, selection, onMapTap, onMapError) =>
                      GestureDetector(
                    key: const Key('fake-location-map'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onMapTap(
                      const LatLng(10.5001, -66.9002),
                    ),
                    onLongPress: onMapError,
                    child: const SizedBox.expand(),
                  ),
                ),
              );
              onResult(result);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(
    overrides: [
      locationServiceProvider.overrideWithValue(
        locationService ?? _FakeLocationService(),
      ),
      placesRepositoryProvider.overrideWithValue(
        placesRepository ?? _FakePlacesRepository(),
      ),
    ],
    child: app,
  );
}

void main() {
  testWidgets('a Google Places result selects its coordinates and label',
      (tester) async {
    final places = _FakePlacesRepository(
      response: const PlacesSearchResponse(
        results: [
          PlaceSearchResult(
            placeId: 'place-1',
            name: 'Mall Multiplaza',
            formattedAddress: 'Tegucigalpa, Francisco Morazán, Honduras',
            latitude: 14.0847,
            longitude: -87.1842,
          ),
        ],
      ),
    );
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        placesRepository: places,
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.search), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const Key('submit-request-location-search')),
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.enterText(
      find.byKey(const Key('request-location-search')),
      'Multiplaza',
    );
    await tester.tap(
      find.byKey(const Key('submit-request-location-search')),
    );
    await tester.pumpAndSettle();

    expect(places.lastQuery, 'Multiplaza');
    expect(find.text('Mall Multiplaza'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);

    await tester.tap(find.text('Mall Multiplaza'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tegucigalpa, Francisco Morazán, Honduras'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.latitude, 14.0847);
    expect(result?.longitude, -87.1842);
    expect(result?.source, RequestLocationSource.search);
  });

  testWidgets('an empty Places response remains recoverable', (tester) async {
    await tester.pumpWidget(_testApp(onResult: (_) {}));

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('request-location-search')),
      'Lugar inexistente',
    );
    await tester.tap(
      find.byKey(const Key('submit-request-location-search')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos resultados. Prueba otra búsqueda.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('request-location-search')), findsOneWidget);
  });

  testWidgets('a Places failure exposes a retry action', (tester) async {
    await tester.pumpWidget(
      _testApp(
        placesRepository: _FakePlacesRepository(
          failure: const ServerFailure(message: 'Servicio no disponible.'),
        ),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('request-location-search')),
      'Tegucigalpa',
    );
    await tester.tap(
      find.byKey(const Key('submit-request-location-search')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servicio no disponible.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('a map tap updates the draft returned by confirmation',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
    );
    addTearDown(container.dispose);
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        container: container,
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-location-map')));
    await tester.pumpAndSettle();

    expect(find.text('10.5001, -66.9002'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.latitude, 10.5001);
    expect(result?.longitude, -66.9002);
    expect(result?.source, RequestLocationSource.mapTap);
    expect(container.read(isLocationSharedProvider), isFalse);
    expect(container.read(userLocationProvider).valueOrNull, isNull);
  });

  testWidgets('closing the dialog discards its draft', (tester) async {
    RequestLocationSelection? result;
    var completed = false;
    await tester.pumpWidget(
      _testApp(
        initialSelection: const RequestLocationSelection(
          latitude: 10.4,
          longitude: -66.9,
          source: RequestLocationSource.mapTap,
        ),
        onResult: (value) {
          completed = true;
          result = value;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-location-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('close-request-location')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('a saved profile location can be confirmed without map movement',
      (tester) async {
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        initialSelection: const RequestLocationSelection(
          latitude: 14.0723,
          longitude: -87.1921,
          source: RequestLocationSource.profile,
        ),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();

    expect(find.text('Última ubicación guardada'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm-request-location')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();
    expect(result?.source, RequestLocationSource.profile);
  });

  testWidgets('the current-location action returns a GPS selection',
      (tester) async {
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        locationService: _FakeLocationService(
          address: 'Sabana Grande, Caracas',
        ),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-current-request-location')));
    await tester.pumpAndSettle();

    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.source, RequestLocationSource.gps);
    expect(result?.latitude, 10.4806);
    expect(result?.longitude, -66.9036);
  });

  testWidgets('GPS denial keeps manual map selection available',
      (tester) async {
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        locationService: _DeniedLocationService(),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-current-request-location')));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'No pudimos acceder al GPS. Puedes elegir un punto en el mapa.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('fake-location-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.source, RequestLocationSource.mapTap);
  });

  testWidgets('a map failure shows a retryable notice', (tester) async {
    await tester.pumpWidget(_testApp(onResult: (_) {}));

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('fake-location-map')));
    await tester.pump();

    expect(find.text('No pudimos cargar el mapa.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry-request-location-map')));
    await tester.pump();

    expect(find.text('No pudimos cargar el mapa.'), findsNothing);
  });

  testWidgets('fits a small phone with enlarged text and 48dp actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        textScale: 2,
        disableAnimations: true,
        initialSelection: const RequestLocationSelection(
          latitude: 10.4806,
          longitude: -66.9036,
          label: 'Sabana Grande, Caracas, Distrito Capital',
          source: RequestLocationSource.mapTap,
        ),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const Key('use-current-request-location')))
          .shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('confirm-request-location'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('fits a large phone viewport', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        initialSelection: const RequestLocationSelection(
          latitude: 10.4806,
          longitude: -66.9036,
          source: RequestLocationSource.mapTap,
        ),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Elegir ubicación'), findsOneWidget);
    expect(find.text('Usar esta ubicación'), findsOneWidget);
  });

  testWidgets('fits a representative landscape viewport', (tester) async {
    tester.view.physicalSize = const Size(700, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        initialSelection: const RequestLocationSelection(
          latitude: 10.4806,
          longitude: -66.9036,
          source: RequestLocationSource.mapTap,
        ),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Usar esta ubicación'), findsOneWidget);
  });
}
