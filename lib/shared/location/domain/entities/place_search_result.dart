import 'package:equatable/equatable.dart';

class PlaceSearchResult extends Equatable {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
        placeId,
        name,
        formattedAddress,
        latitude,
        longitude,
      ];
}
