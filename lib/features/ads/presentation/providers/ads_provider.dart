import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/ad.dart';
import '../../domain/repositories/ad_repository.dart';
import '../../domain/usecases/get_ads_usecase.dart';
import '../../domain/usecases/track_ad_click_usecase.dart';
import '../../domain/usecases/track_ad_impression_usecase.dart';
import '../../data/datasources/ad_remote_datasource.dart';
import '../../data/repositories/ad_repository_impl.dart';

// --- Data Layer ---

final adRemoteDataSourceProvider = Provider<AdRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AdRemoteDataSource(dioClient.dio);
});

final adRepositoryProvider = Provider<AdRepository>((ref) {
  final remoteDataSource = ref.watch(adRemoteDataSourceProvider);
  return AdRepositoryImpl(remoteDataSource);
});

// --- Domain Layer ---

final getAdsUseCaseProvider = Provider<GetAdsUseCase>((ref) {
  final repository = ref.watch(adRepositoryProvider);
  return GetAdsUseCase(repository);
});

final trackAdImpressionUseCaseProvider = Provider<TrackAdImpressionUseCase>((ref) {
  final repository = ref.watch(adRepositoryProvider);
  return TrackAdImpressionUseCase(repository);
});

final trackAdClickUseCaseProvider = Provider<TrackAdClickUseCase>((ref) {
  final repository = ref.watch(adRepositoryProvider);
  return TrackAdClickUseCase(repository);
});

// --- Presentation Layer ---

final adsFeedProvider = FutureProvider.autoDispose<List<Ad>>((ref) async {
  final positionAsync = ref.watch(userLocationProvider);
  final position = positionAsync.value;

  if (position == null) {
    // If we have no location yet, return an empty list or throw an error.
    // For now, we return empty list so the UI doesn't crash if location is not granted.
    return [];
  }

  final usecase = ref.watch(getAdsUseCaseProvider);
  final result = await usecase.call(position.latitude, position.longitude);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (ads) => ads,
  );
});
