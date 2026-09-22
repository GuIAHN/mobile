import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/places_search_response.dart';
import '../repositories/places_repository.dart';

class SearchPlacesUseCase {
  final PlacesRepository _repository;

  const SearchPlacesUseCase(this._repository);

  Future<Either<Failure, PlacesSearchResponse>> call(String query) {
    return _repository.search(query);
  }
}
