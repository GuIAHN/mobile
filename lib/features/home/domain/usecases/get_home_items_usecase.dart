import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/home_item.dart';
import '../entities/service_type.dart';
import '../repositories/home_repository.dart';

class GetHomeItemsUseCase {
  final HomeRepository repository;

  GetHomeItemsUseCase(this.repository);

  Future<Either<Failure, List<HomeItem>>> call(ServiceType type) {
    return repository.getHomeItems(type);
  }
}
