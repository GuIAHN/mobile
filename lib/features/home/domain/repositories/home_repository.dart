import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../entities/home_filters.dart';
import '../entities/home_item.dart';
import '../entities/promo.dart';
import '../entities/provider_detail.dart';
import '../entities/top_providers_result.dart';

abstract class HomeRepository {
  /// Talleres y mecánicos destacados obtenidos en una sola petición.
  Future<Either<Failure, TopProvidersResult>> getTopProviders({
    double? lat,
    double? lng,
  });

  /// Promos/banners por tipo de servicio (datos locales por ahora).
  Future<Either<Failure, List<Promo>>> getPromos(ServiceType type);

  /// En producción todos los tipos usan backend; fuera de producción las
  /// tiendas de repuestos conservan datos locales de apoyo.
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type);

  /// Búsqueda real de mecánicos o talleres contra el backend.
  /// [type] debe ser [ServiceType.mechanic] o [ServiceType.workshops].
  Future<Either<Failure, List<HomeItem>>> searchProviders({
    required ServiceType type,
    required HomeFilters filters,
    int page = 1,
  });

  /// Perfil público completo de un mecánico o taller.
  Future<Either<Failure, ProviderDetail>> getProviderDetail({
    required String id,
    required ServiceType type,
  });
}
