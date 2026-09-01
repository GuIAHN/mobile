import '../../domain/entities/places_search_response.dart';
import 'place_search_result_model.dart';

class PlacesSearchResponseModel extends PlacesSearchResponse {
  const PlacesSearchResponseModel({
    required super.results,
    super.attributions,
  });

  factory PlacesSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final rawAttributions = json['attributions'];
    return PlacesSearchResponseModel(
      results: rawResults is List
          ? rawResults
              .whereType<Map>()
              .map(
                (item) => PlaceSearchResultModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      attributions: rawAttributions is List
          ? rawAttributions.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}
