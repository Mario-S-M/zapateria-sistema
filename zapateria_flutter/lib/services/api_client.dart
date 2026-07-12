import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: kIsWeb ? '/api' : 'http://192.168.0.102:3000',
);

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('$obj'),
    ));
  }

  Dio get dio => _dio;
}

final apiClient = ApiClient();
