import 'package:dio/dio.dart';

import '../../error/exceptions.dart';
import '../session_manager.dart';

final class AppInterceptor extends Interceptor {
  AppInterceptor(this._sessionManager);

  final SessionManager _sessionManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sessionManager.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(_mapException(err));
  }

  DioException _mapException(DioException error) {
    return switch (error.type) {
      DioExceptionType.badResponse => _mapStatusCode(error),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout => DeadlineExceededException(error),
      DioExceptionType.connectionError => NoInternetConnectionException(error),
      DioExceptionType.cancel => RequestCancelledException(error),
      DioExceptionType.badCertificate => BadCertificateException(error),
      DioExceptionType.unknown => UnknownDioException(error),
    };
  }

  DioException _mapStatusCode(DioException error) {
    final statusCode = error.response?.statusCode;
    return switch (statusCode) {
      400 => BadRequestException(error),
      401 => UnauthorizedException(error),
      403 => ForbiddenException(error),
      404 => NotFoundException(error),
      409 => ConflictException(error),
      int code when code >= 500 && code <= 599 => ServerException(error),
      _ => error,
    };
  }
}
