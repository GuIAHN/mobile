import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/error_mapper.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';

void main() {
  test(
      'maps edit conflicts and unavailable photos from standard error envelopes',
      () {
    Failure failure(int status, Map<String, dynamic> body) {
      final request = RequestOptions(path: '/search/r');
      return ErrorMapper.map(DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(
              requestOptions: request, statusCode: status, data: body)));
    }

    expect(failure(409, {'reason': 'SEARCH_REQUEST_NOT_EDITABLE'}),
        isA<RequestNotEditableFailure>());
    expect(
        failure(422, {
          'data': {'reason': 'PHOTOS_NOT_AVAILABLE'}
        }),
        isA<RequestPhotosUnavailableFailure>());
  });
}
