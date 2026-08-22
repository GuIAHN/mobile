import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ad_model.dart';

class AdRemoteDataSource {
  final Dio dio;

  AdRemoteDataSource(this.dio);

  Future<List<AdModel>> getFeed(double? lat, double? lng,
      {int limit = 5}) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
    };
    if (lat != null) queryParameters['lat'] = lat;
    if (lng != null) queryParameters['lng'] = lng;

    final response = await dio.get(
      ApiEndpoints.adsFeed,
      queryParameters: queryParameters,
    );

    // ResponseUnwrapInterceptor already extracts the backend's `data` field.
    final data = response.data as List<dynamic>;
    return data
        .map((json) => AdModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> trackImpression(String id, double lat, double lng) async {
    await dio.post(
      ApiEndpoints.trackAdImpression(id),
      data: {
        'lat': lat,
        'lng': lng,
      },
    );
  }

  Future<void> trackClick(String id, double lat, double lng) async {
    await dio.post(
      ApiEndpoints.trackAdClick(id),
      data: {
        'lat': lat,
        'lng': lng,
      },
    );
  }
}
