import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../entities/provider_detail.dart';
import '../repositories/home_repository.dart';

/// Caso de uso: obtener el perfil público completo de un mecánico o taller.
class GetProviderDetailUseCase {
  final HomeRepository _repository;

  GetProviderDetailUseCase(this._repository);

  Future<Either<Failure, ProviderDetail>> call({
    required String id,
    required ServiceType type,
  }) {
    return _repository.getProviderDetail(id: id, type: type);
  }
}
