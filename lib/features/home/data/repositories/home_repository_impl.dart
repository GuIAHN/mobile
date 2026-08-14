import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/provider_detail.dart';
import '../../domain/entities/top_providers_result.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../datasources/search_remote_datasource.dart';
import '../models/home_item_model.dart';
import '../models/promo_model.dart';
import '../models/provider_model.dart';
import '../models/provider_detail_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final SearchRemoteDatasource _searchRemoteDatasource;
  final HomeRemoteDatasource _homeRemoteDatasource;

  HomeRepositoryImpl(
    this._searchRemoteDatasource,
    this._homeRemoteDatasource,
  );

  // ── Promos (datos locales) ────────────────────────────────────────────────

  static const Map<ServiceType, List<PromoModel>> _mockPromos = {
    ServiceType.mechanic: [
      PromoModel(
        title: 'Mecánicos certificados',
        subtitle: 'Verificados y con garantía escrita',
        iconName: 'verified_outlined',
        gradientColors: [0xFFF25C05, 0xFFF25C05],
        imageUrl:
            'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Servicio a domicilio',
        subtitle: 'Tu mecánico certificado donde estés',
        iconName: 'home_repair_service_outlined',
        gradientColors: [0xFF2E7D4F, 0xFF6FCF97],
        imageUrl:
            'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    ServiceType.spareParts: [
      PromoModel(
        title: 'Toyota Original',
        subtitle: 'Hasta 20% en piezas seleccionadas',
        iconName: 'local_offer_outlined',
        gradientColors: [0xFFF25C05, 0xFFF25C05],
        imageUrl:
            'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Bosch & Denso',
        subtitle: 'Componentes Premium · Envío nacional gratis',
        iconName: 'bolt_outlined',
        gradientColors: [0xFF3A86FF, 0xFF6FA8FF],
        imageUrl:
            'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Combo Mantenimiento',
        subtitle: 'Filtros + aceite sintético desde \$25',
        iconName: 'oil_barrel_outlined',
        gradientColors: [0xFF1A1C1E, 0xFF6B7280],
        imageUrl:
            'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    ServiceType.workshops: [
      PromoModel(
        title: 'Talleres aliados',
        subtitle: 'Diagnóstico por computadora gratis',
        iconName: 'handyman_outlined',
        gradientColors: [0xFFF25C05, 0xFFFDE8DA],
        imageUrl:
            'https://images.unsplash.com/photo-1504222490345-c075b6008014?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Latonería y pintura',
        subtitle: 'Presupuesto digital en menos de 24h',
        iconName: 'format_paint_outlined',
        gradientColors: [0xFFE53935, 0xFFEF4444],
        imageUrl:
            'https://images.unsplash.com/photo-1597762137435-fcb1a210c64d?auto=format&fit=crop&w=600&q=80',
      ),
    ],
  };

  // ── Mocks de spareParts (sin backend por ahora) ───────────────────────────

  static const List<HomeItemModel> _mockSpareParts = [
    HomeItemModel(
      name: 'Repuestos El Motor',
      detail: 'Distribuidor autorizado: Toyota · Chevrolet · Ford',
      rating: 4.8,
      reviews: 340,
      distanceKm: 0.5,
      isOpen: true,
      iconName: 'settings_outlined',
      type: ServiceType.spareParts,
    ),
    HomeItemModel(
      name: 'AutoPartes Centro',
      detail: 'Multimarca · Repuestos originales e importados',
      rating: 4.6,
      reviews: 198,
      distanceKm: 1.2,
      isOpen: true,
      iconName: 'settings_outlined',
      type: ServiceType.spareParts,
    ),
    HomeItemModel(
      name: 'La Casa del Filtro',
      detail: 'Filtros · Aceites · Lubricantes de alto rendimiento',
      rating: 4.4,
      reviews: 76,
      distanceKm: 1.9,
      isOpen: true,
      iconName: 'settings_outlined',
      type: ServiceType.spareParts,
    ),
  ];

  // ── HomeRepository impl ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, TopProvidersResult>> getTopProviders({
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _homeRemoteDatasource.getTopProviders(
        lat: lat,
        lng: lng,
      );
      final workshops = ProviderModel.fromJsonList(
        response['workshops'] as List<dynamic>? ?? const [],
        ServiceType.workshops,
      );
      final mechanics = ProviderModel.fromJsonList(
        response['mechanics'] as List<dynamic>? ?? const [],
        ServiceType.mechanic,
      );
      return Right(
        TopProvidersResult(workshops: workshops, mechanics: mechanics),
      );
    } on DioException catch (error) {
      return Left(_mapDioError(error));
    } catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Promo>>> getPromos(ServiceType type) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return Right(_mockPromos[type] ?? []);
    } catch (e) {
      return const Left(
          UnexpectedFailure(message: 'Error al cargar promociones'));
    }
  }

  @override
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type) async {
    // spareParts usa mocks; mechanics y workshops usan backend vía searchProviders
    if (type == ServiceType.spareParts) {
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        return const Right(_mockSpareParts);
      } catch (e) {
        return const Left(
            UnexpectedFailure(message: 'Error al cargar repuestos'));
      }
    }
    // Para mecánicos y talleres, delegar a searchProviders con filtros por defecto
    return searchProviders(type: type, filters: const HomeFilters());
  }

  @override
  Future<Either<Failure, List<HomeItem>>> searchProviders({
    required ServiceType type,
    required HomeFilters filters,
    int page = 1,
  }) async {
    try {
      final params = {
        ...filters.toQueryParams(),
        'page': page,
        'pageSize': 20,
      };

      final Map<String, dynamic> response;
      if (type == ServiceType.mechanic) {
        response = await _searchRemoteDatasource.searchMechanics(params);
      } else {
        response = await _searchRemoteDatasource.searchWorkshops(params);
      }

      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      final providers = ProviderModel.fromJsonList(data, type);
      return Right(providers);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProviderDetail>> getProviderDetail({
    required String id,
    required ServiceType type,
  }) async {
    try {
      final Map<String, dynamic> json;
      if (type == ServiceType.mechanic || type == ServiceType.workshops) {
        json = await _searchRemoteDatasource.getMechanicDetail(id);
        return Right(ProviderDetailModel.fromMechanicJson(json));
      } else {
        json = await _searchRemoteDatasource.getStoreDetail(id);
        return Right(ProviderDetailModel.fromStoreJson(json));
      }
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  // ── Mapeo de errores Dio → Failure ────────────────────────────────────────

  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      default:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) return const UnauthorizedFailure();
        if (statusCode == 403) return const ForbiddenFailure();
        if (statusCode == 404) return const NotFoundFailure();
        final msg =
            e.response?.data?['message']?.toString() ?? 'Error del servidor';
        return ServerFailure(message: msg, code: statusCode);
    }
  }
}
