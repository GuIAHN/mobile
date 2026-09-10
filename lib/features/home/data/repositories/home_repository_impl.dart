import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/provider_detail.dart';
import '../../domain/entities/top_providers_result.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../datasources/search_remote_datasource.dart';
import '../models/home_item_model.dart';
import '../models/provider_model.dart';
import '../models/provider_detail_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final SearchRemoteDatasource _searchRemoteDatasource;
  final HomeRemoteDatasource _homeRemoteDatasource;
  final bool _useLiveStores;

  HomeRepositoryImpl(
    this._searchRemoteDatasource,
    this._homeRemoteDatasource, {
    bool? useLiveStores,
  }) : _useLiveStores = useLiveStores ?? Env.isProd;

  // ── Mocks de spareParts (solo fuera de producción) ───────────────────

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
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type) async {
    if (type == ServiceType.spareParts) {
      if (_useLiveStores) {
        return searchProviders(type: type, filters: const HomeFilters());
      }
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

      final Map<String, dynamic> response = switch (type) {
        ServiceType.mechanic =>
          await _searchRemoteDatasource.searchMechanics(params),
        ServiceType.workshops =>
          await _searchRemoteDatasource.searchWorkshops(params),
        ServiceType.spareParts =>
          await _searchRemoteDatasource.searchStores(params),
        ServiceType.storeDashboard =>
          throw StateError('El dashboard no admite búsqueda de proveedores'),
      };

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
