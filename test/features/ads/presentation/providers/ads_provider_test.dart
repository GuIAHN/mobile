import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/ads/domain/entities/ad.dart';
import 'package:guiautomotriz_mobile/features/ads/domain/repositories/ad_repository.dart';
import 'package:guiautomotriz_mobile/features/ads/domain/usecases/get_ads_usecase.dart';
import 'package:guiautomotriz_mobile/features/ads/presentation/providers/ads_provider.dart';

class _FailingAdRepository implements AdRepository {
  @override
  Future<Either<Failure, List<Ad>>> getFeed(
    double? lat,
    double? lng, {
    int limit = 5,
  }) async =>
      const Left(NetworkFailure());

  @override
  Future<Either<Failure, void>> trackClick(
    String id,
    double lat,
    double lng,
  ) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> trackImpression(
    String id,
    double lat,
    double lng,
  ) =>
      throw UnimplementedError();
}

void main() {
  test('empty backend advertising never falls back to mock promotions',
      () async {
    final container = ProviderContainer(
      overrides: [
        adsFeedProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    final promos = await container.read(
      adsAsPromosProvider(ServiceType.spareParts).future,
    );

    expect(promos, isEmpty);
  });

  test('backend advertising failures remain retryable errors', () async {
    final container = ProviderContainer(
      overrides: [
        getAdsUseCaseProvider.overrideWithValue(
          GetAdsUseCase(_FailingAdRepository()),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(
        adsAsPromosProvider(ServiceType.spareParts).future,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
