import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'interceptors/app_interceptor.dart';
import 'session_manager.dart';

final class DioClient {
  DioClient(this._sessionManager);

  final SessionManager _sessionManager;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const {Headers.acceptHeader: 'application/json'},
      ),
    );

    dio.interceptors.add(AppInterceptor(_sessionManager));

    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }
    return dio;
  }
}
