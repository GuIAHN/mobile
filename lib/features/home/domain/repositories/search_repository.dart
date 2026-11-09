import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/part_type.dart';

abstract class SearchRepository {
  Future<Either<Failure, Map<String, dynamic>>> updateSearchRequest({
    required String requestId,
    required String details,
    required List<String> photoUrls,
  });

  Future<Either<Failure, Map<String, dynamic>>> createSearchRequest({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    int quantity = 1,
    List<String>? photoUrls,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  });
}
