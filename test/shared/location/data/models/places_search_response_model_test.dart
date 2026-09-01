import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/location/data/models/places_search_response_model.dart';

void main() {
  test('maps the backend Places contract without leaking JSON into domain', () {
    final model = PlacesSearchResponseModel.fromJson(const {
      'results': [
        {
          'placeId': 'place-1',
          'name': 'Mall Multiplaza',
          'formattedAddress': 'Tegucigalpa, Honduras',
          'latitude': 14.0847,
          'longitude': -87.1842,
        },
      ],
      'attributions': ['Proveedor'],
    });

    expect(model.results.single.placeId, 'place-1');
    expect(model.results.single.latitude, 14.0847);
    expect(model.attributions, ['Proveedor']);
  });

  test('rejects malformed result fields at the data boundary', () {
    expect(
      () => PlacesSearchResponseModel.fromJson(const {
        'results': [
          {
            'placeId': 'place-1',
            'name': 'Lugar',
            'formattedAddress': 'Honduras',
            'latitude': 'not-a-number',
            'longitude': -87.1842,
          },
        ],
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
