import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';
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

  /// Fetches the list of root (main) categories.
  Future<List<CategoryModel>> getRootCategories() async {
    try {
      final response = await _client.get<List<dynamic>>('/categories');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
