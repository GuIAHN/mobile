import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/places_search_response.dart';

abstract class PlacesRepository {
  Future<Either<Failure, PlacesSearchResponse>> search(String query);
}
