import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../entities/home_filters.dart';
import '../entities/home_item.dart';
import '../repositories/home_repository.dart';

/// Caso de uso: búsqueda paginada de mecánicos o talleres.
class SearchProvidersUseCase {
  final HomeRepository _repository;

  SearchProvidersUseCase(this._repository);

  Future<Either<Failure, List<HomeItem>>> call({
    required ServiceType type,
    required HomeFilters filters,
    int page = 1,
  }) {
    return _repository.searchProviders(
      type: type,
      filters: filters,
      page: page,
    );
  }
}
