import 'package:dio/dio.dart';

/// Interceptor that automatically unwraps responses structured with the
/// standard NestJS response envelope containing the 'data' key.
class ResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final responseData = response.data;
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      response.data = responseData['data'];
    }
    super.onResponse(response, handler);
  }
}
