import '../../domain/entities/place_search_result.dart';

class PlaceSearchResultModel extends PlaceSearchResult {
  const PlaceSearchResultModel({
    required super.placeId,
    required super.name,
    required super.formattedAddress,
    required super.latitude,
    required super.longitude,
  });

  factory PlaceSearchResultModel.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResultModel(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      formattedAddress: json['formattedAddress'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
