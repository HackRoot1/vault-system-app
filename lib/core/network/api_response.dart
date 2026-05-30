import 'api_exception.dart';

sealed class ApiResponse<T> {
  const ApiResponse();

  const factory ApiResponse.success(T data, {int? statusCode}) = ApiSuccess<T>;

  const factory ApiResponse.failure(ApiException exception) = ApiFailure<T>;
}

class ApiSuccess<T> extends ApiResponse<T> {
  const ApiSuccess(this.data, {this.statusCode});

  final T data;
  final int? statusCode;
}

class ApiFailure<T> extends ApiResponse<T> {
  const ApiFailure(this.exception);

  final ApiException exception;
}
