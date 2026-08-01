import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ad_model.dart';

class AdRemoteDataSource {
  final Dio dio;

  AdRemoteDataSource(this.dio);

  Future<List<AdModel>> getFeed(double lat, double lng, {int limit = 5}) async {
    final response = await dio.get(
      ApiEndpoints.adsFeed,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'limit': limit,
      },
    );

    // The backend wraps the response in { code, message, data }
    final data = response.data['data'] as List;
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
