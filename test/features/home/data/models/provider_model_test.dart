import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/home/data/models/provider_model.dart';

void main() {
  Map<String, dynamic> providerJson(Map<String, dynamic> reviewCount) => {
        'id': 'provider-1',
        'nombre': 'Taller Central',
        'rating': 4.8,
        'distancia_km': 1.2,
        'especialidades': ['Motor'],
        ...reviewCount,
      };

  test('parses ratingCount into reviews', () {
    final provider = ProviderModel.fromJson(
      providerJson({'ratingCount': 87}),
      ServiceType.workshops,
    );

    expect(provider.reviews, 87);
  });

  test('parses rating_count into reviews', () {
    final provider = ProviderModel.fromJson(
      providerJson({'rating_count': 54}),
      ServiceType.workshops,
    );

    expect(provider.reviews, 54);
  });

  test('parses reviews into reviews', () {
    final provider = ProviderModel.fromJson(
      providerJson({'reviews': '32'}),
      ServiceType.workshops,
    );

    expect(provider.reviews, 32);
  });

  test('uses zero reviews when the aggregate is missing', () {
    final provider = ProviderModel.fromJson(
      providerJson({}),
      ServiceType.workshops,
    );

    expect(provider.reviews, 0);
  });

  test('uses zero reviews when the aggregate is malformed', () {
    final invalidString = ProviderModel.fromJson(
      providerJson({'ratingCount': 'invalid'}),
      ServiceType.workshops,
    );
    final nonScalar = ProviderModel.fromJson(
      providerJson({'reviews': []}),
      ServiceType.workshops,
    );

    expect(invalidString.reviews, 0);
    expect(nonScalar.reviews, 0);
  });

  test('preserves a missing distance as unknown', () {
    final json = providerJson({})..remove('distancia_km');

    final provider = ProviderModel.fromJson(
      json,
      ServiceType.workshops,
    );

    expect(provider.distanceKm, isNull);
  });

  test('preserves a missing open status as unknown', () {
    final provider = ProviderModel.fromJson(
      providerJson({}),
      ServiceType.workshops,
    );

    expect(provider.isOpen, isNull);
  });

  test('parses explicit open status without changing known payloads', () {
    final provider = ProviderModel.fromJson(
      providerJson({'isOpen': false}),
      ServiceType.workshops,
    );

    expect(provider.isOpen, isFalse);
  });
}
