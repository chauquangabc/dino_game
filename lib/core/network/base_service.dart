import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract class BaseService {
  BaseService(this.dio);

  final Dio dio;
  late final Logger? _logger = kDebugMode ? Logger() : null;

  Future<Either<HttpException, T>> handleResponse<T>(
    Future<Response<T>> futureResponse,
  ) async {
    try {
      final response = await futureResponse;
      _logger?.d('Response: ${response.requestOptions.uri}');

      final data = response.data;
      if (data == null) {
        return Left(HttpException('Phản hồi từ máy chủ không có dữ liệu.'));
      }
      return Right(data);
    } on DioException catch (error) {
      final endpoint = error.requestOptions.uri.toString();
      _logger?.e(
        'DioException: [$endpoint] '
        'status=${error.response?.statusCode} message=${error.message}',
      );
      return Left(HttpException(error.message ?? error.toString()));
    } catch (error) {
      _logger?.e('Unexpected error: $error');
      return Left(HttpException('Đã xảy ra lỗi không xác định.'));
    }
  }
}
