import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../repositories/search_repository.dart';

class CreateSearchRequestUseCase {
  final SearchRepository repository;

  CreateSearchRequestUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  }) {
    return repository.createSearchRequest(
      userCarId: userCarId,
      subcategoryId: subcategoryId,
      details: details,
      fotoUrl: fotoUrl,
      partType: partType,
      radioKm: radioKm,
      lat: lat,
      lon: lon,
    );
  }
}
