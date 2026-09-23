import 'package:dio/dio.dart';

String parseErrorMessage(Response<dynamic>? response, String fallback) {
  try {
    final data = response?.data;
    if (data == null) return fallback;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is List && data.isNotEmpty) return data.first.toString();
  } catch (_) {
    // Dữ liệu lỗi từ server không đúng cấu trúc mong đợi; dùng fallback.
  }
  return fallback;
}

abstract class AppDioException extends DioException {
  AppDioException(DioException source)
    : super(
        requestOptions: source.requestOptions,
        response: source.response,
        type: source.type,
        error: source.error,
        stackTrace: source.stackTrace,
      );

  String get fallbackMessage;

  @override
  String get message => parseErrorMessage(response, fallbackMessage);

  @override
  String toString() => message;
}

class BadRequestException extends AppDioException {
  BadRequestException(super.source);

  @override
  String get fallbackMessage => 'Yêu cầu không hợp lệ (lỗi 400).';
}

class UnauthorizedException extends AppDioException {
  UnauthorizedException(super.source);

  @override
  String get fallbackMessage =>
      'Hết phiên đăng nhập hoặc không có quyền truy cập.';
}

class ForbiddenException extends AppDioException {
  ForbiddenException(super.source);

  @override
  String get fallbackMessage => 'Bạn không có quyền thực hiện thao tác này.';
}

class NotFoundException extends AppDioException {
  NotFoundException(super.source);

  @override
  String get fallbackMessage => 'Không tìm thấy dữ liệu yêu cầu (lỗi 404).';
}

class ConflictException extends AppDioException {
  ConflictException(super.source);

  @override
  String get fallbackMessage => 'Dữ liệu bị xung đột (lỗi 409).';
}

class ServerException extends AppDioException {
  ServerException(super.source);

  @override
  String get fallbackMessage => 'Lỗi máy chủ, vui lòng thử lại sau.';
}

class NoInternetConnectionException extends AppDioException {
  NoInternetConnectionException(super.source);

  @override
  String get fallbackMessage => 'Không có kết nối mạng. Vui lòng kiểm tra lại!';
}

class DeadlineExceededException extends AppDioException {
  DeadlineExceededException(super.source);

  @override
  String get fallbackMessage => 'Kết nối quá hạn. Vui lòng thử lại!';
}

class RequestCancelledException extends AppDioException {
  RequestCancelledException(super.source);

  @override
  String get fallbackMessage => 'Yêu cầu đã bị hủy.';
}

class BadCertificateException extends AppDioException {
  BadCertificateException(super.source);

  @override
  String get fallbackMessage => 'Chứng chỉ bảo mật của máy chủ không hợp lệ.';
}

class UnknownDioException extends AppDioException {
  UnknownDioException(super.source);

  @override
  String get fallbackMessage =>
      error?.toString() ?? 'Đã xảy ra lỗi không xác định.';
}
