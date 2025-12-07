import 'package:dio/dio.dart';

class CloudflareInterceptor extends Interceptor {

  final Dio dio;

  CloudflareInterceptor(this.dio);

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.resolve(response);
  }
}
