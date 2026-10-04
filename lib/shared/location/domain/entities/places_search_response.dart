import 'package:equatable/equatable.dart';

import 'place_search_result.dart';

class PlacesSearchResponse extends Equatable {
  final List<PlaceSearchResult> results;
  final List<String> attributions;

  const PlacesSearchResponse({
    required this.results,
    this.attributions = const [],
  });

  @override
  List<Object?> get props => [results, attributions];
}
