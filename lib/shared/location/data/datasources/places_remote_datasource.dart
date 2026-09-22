import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/places_search_response_model.dart';

class PlacesRemoteDataSource {
  final DioClient _client;

  const PlacesRemoteDataSource(this._client);

  Future<PlacesSearchResponseModel> search(String query) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.placesSearch,
      queryParameters: {'query': query.trim()},
    );
    final data = response.data;
    if (data == null) {
      throw const ParseException(message: 'Empty Places response');
    }

    try {
      return PlacesSearchResponseModel.fromJson(data);
    } on TypeError {
      throw const ParseException(message: 'Invalid Places response');
    }
  }
}
