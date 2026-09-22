import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_node_model.dart';
import '../models/specialty_model.dart';

/// Remote data source to fetch global catalog data from the API.
class CatalogRemoteDataSource {
  final DioClient _client;

  CatalogRemoteDataSource(this._client);

  /// Fetches the complete list of specialties.
  Future<List<SpecialtyModel>> getSpecialties() async {
    try {
      final response = await _client.get<List<dynamic>>('/specialties');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => SpecialtyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the complete category tree (roots + all nested subcategories).
  ///
  /// The backend caches this response in Redis for 24 hours, so this call
  /// is near-instant after the first request. The nested [children] field
  /// is deserialized recursively by [CategoryNodeModel.fromJson].
  Future<List<CategoryNodeModel>> getCategoryTree() async {
    try {
      final response = await _client.get<List<dynamic>>('/categories/tree');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) =>
              CategoryNodeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
