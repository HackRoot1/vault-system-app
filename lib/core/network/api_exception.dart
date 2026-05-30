import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  static ApiException fromDio(DioException error) {
    if (error.error is TokenExpiredException) {
      return const TokenExpiredException();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkApiException('Connection timed out.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ServerApiException(
          'Request failed${statusCode == null ? '' : ' with status $statusCode'}.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const NetworkApiException('Network connection unavailable.');
      case DioExceptionType.cancel:
        return const NetworkApiException('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkApiException('Unable to verify secure connection.');
    }
  }
}

class NetworkApiException extends ApiException {
  const NetworkApiException(super.message);
}

class ServerApiException extends ApiException {
  const ServerApiException(super.message, {this.statusCode});

  final int? statusCode;
}

class TokenExpiredException extends ApiException {
  const TokenExpiredException() : super('Session expired.');
}

class UnexpectedApiException extends ApiException {
  const UnexpectedApiException(super.message);
}
