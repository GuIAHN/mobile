import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/data/models/specialty_model.dart';
import '../models/store_catalog_model.dart';

class ProviderProfileRemoteDataSource {
  final DioClient _client;

  const ProviderProfileRemoteDataSource(this._client);

  Future<List<SpecialtyModel>> getOwnSpecialties() async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.mechanicSpecialties,
    );
    final data = response.data;
    if (data == null) throw const ParseException();
    return _parseSpecialties(data);
  }

  Future<List<SpecialtyModel>> updateOwnSpecialties(
    List<String> specialtyIds,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.mechanicProfile,
      data: {'specialtyIds': specialtyIds},
    );
    final data = response.data;
    final specialties = data?['specialties'];
    if (specialties is! List) throw const ParseException();
    return _parseSpecialties(specialties);
  }

  List<SpecialtyModel> _parseSpecialties(List<dynamic> data) {
    return data
        .map(
          (json) => SpecialtyModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<StoreCatalogModel> getOwnCatalog() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.storeOwnCoverage,
    );
    final data = response.data;
    if (data == null) throw const ParseException();
    if (data['subcategories'] is! List) throw const ParseException();
    return StoreCatalogModel.fromJson(data);
  }
}
