import 'package:dio/dio.dart';
import 'package:hrms_test/data/const/app_constant.dart';

class ApiClient {
  Dio? _dio;

  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final base = await AppConstant.getBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    return _dio!;
  }

  void resetClient() {
    _dio = null;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response =
        await (await _client).get(path, queryParameters: query);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await (await _client).post(path, data: body);
    return Map<String, dynamic>.from(response.data);
  }
}
