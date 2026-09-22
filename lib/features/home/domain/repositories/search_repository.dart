import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/part_type.dart';

abstract class SearchRepository {
  Future<Either<Failure, Map<String, dynamic>>> createSearchRequest({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  });
}
