import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../home/domain/entities/promo.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/session/session_generation_provider.dart';
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

final trackAdImpressionUseCaseProvider =
    Provider<TrackAdImpressionUseCase>((ref) {
  final repository = ref.watch(adRepositoryProvider);
  return TrackAdImpressionUseCase(repository);
});

final trackAdClickUseCaseProvider = Provider<TrackAdClickUseCase>((ref) {
  final repository = ref.watch(adRepositoryProvider);
  return TrackAdClickUseCase(repository);
});

// --- Presentation Layer ---

final adsFeedProvider = FutureProvider.autoDispose<List<Ad>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final positionAsync = ref.watch(userLocationProvider);
  final position = positionAsync.value;

  final usecase = ref.watch(getAdsUseCaseProvider);
  final result = await usecase.call(position?.latitude, position?.longitude);

  return result.fold(
    (failure) =>
        [], // Silencioso: si hay error (red, 500, etc) retornamos lista vacía
    (ads) => ads,
  );
});

/// Adaptador que toma los Ads del backend y los convierte en Promos para la UI.
/// Si el backend no devuelve ads (o falla silenciosamente), usa el fallback local.
final adsAsPromosProvider = FutureProvider.family
    .autoDispose<List<Promo>, ServiceType>((ref, type) async {
  ref.cacheFor(const Duration(minutes: 5));

  try {
    // 1. Intentar obtener los ads reales del backend
    final ads = await ref.watch(adsFeedProvider.future);

    if (ads.isNotEmpty) {
      // Mapear Ad -> Promo
      return ads.map((ad) {
        return Promo(
          id: ad.id,
          title: ad.title,
          subtitle: ad.description ?? ad.brandName,
          iconName: 'local_offer_outlined', // Icono genérico por defecto
          gradientColors: const [0xFFF25C05, 0xFFF25C05], // Naranja por defecto
          imageUrl: ad.mediaUrl,
          ctaUrl: ad.ctaUrl,
        );
      }).toList();
    }
  } catch (_) {
    // Si falla la petición de ads, ignoramos el error y continuamos al fallback.
  }

  // 2. Si está vacío o falló, caer al fallback de mocks locales
  // Al usar .future, Riverpod espera a que cargue automáticamente
  final fallbackPromos = await ref.watch(promosProvider(type).future);
  return fallbackPromos;
});

// --- Tracking State ---

class AdTrackerNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(sessionGenerationProvider);
    return {};
  }

  void trackImpression(String? adId) {
    if (adId == null || state.contains(adId)) return;

    // Add to tracked set immediately to prevent duplicates
    state = {...state, adId};

    // Fire and forget
    _executeImpression(adId);
  }

  Future<void> _executeImpression(String adId) async {
    try {
      final positionAsync = ref.read(userLocationProvider);
      final position = positionAsync.value;

      final usecase = ref.read(trackAdImpressionUseCaseProvider);
      await usecase.call(
          adId, position?.latitude ?? 0.0, position?.longitude ?? 0.0);
    } catch (e) {
      // Ignorar errores silenciosamente para no afectar la UI
    }
  }

  // Conjunto local privado para deduplicar clics en la misma sesión
  // (No lo exponemos en el state porque la UI no necesita redibujarse cuando se hace clic)
  final Set<String> _trackedClicks = {};

  void trackClick(String? adId) {
    if (adId == null || _trackedClicks.contains(adId)) return;

    // Add to local set to prevent duplicate clicks per session
    _trackedClicks.add(adId);

    // Fire and forget
    _executeClick(adId);
  }

  Future<void> _executeClick(String adId) async {
    try {
      final positionAsync = ref.read(userLocationProvider);
      final position = positionAsync.value;

      final usecase = ref.read(trackAdClickUseCaseProvider);
      await usecase.call(
          adId, position?.latitude ?? 0.0, position?.longitude ?? 0.0);
    } catch (e) {
      // Ignorar errores silenciosamente
    }
  }
}

final adTrackerProvider = NotifierProvider<AdTrackerNotifier, Set<String>>(
  AdTrackerNotifier.new,
);
