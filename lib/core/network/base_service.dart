import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract class BaseService {
  late final _logger = kDebugMode ? Logger() : null;

  Future<Either<dynamic, HttpException>> handleResponse(
    Future<Response> futureResponse,
  ) async {
    try {
      final response = await futureResponse;
      _logger?.d('_handleResponse :: $response');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Left(response.data);
      } else {
        _logger?.e('DataExceptions :: ${response.data}');
        return Right(HttpException(response.data.toString()));
      }
    } on DioException catch (e) {
      final endpoint = e.requestOptions.uri.toString();
      _logger?.e(
        'DioError :: [$endpoint] :: Status: ${e.response?.statusCode} :: Data: ${e.response?.data}',
      );
      _logger?.e('DioException :: ${e.toString()}');
      return Right(HttpException(e.toString()));
    } catch (e) {
      _logger?.e('Unexpected error :: ${e.toString()}');
      return Right(HttpException('Đã xảy ra lỗi không xác định'));
    }
  }
}
