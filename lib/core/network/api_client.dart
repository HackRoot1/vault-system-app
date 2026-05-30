import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'auth_token_store.dart';

class ApiClient {
  ApiClient({Dio? dio, AuthTokenStore? tokenStore})
    : _dio = dio ?? Dio(),
      _tokenStore = tokenStore ?? const InMemoryAuthTokenStore() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiConnectTimeout,
      receiveTimeout: AppConstants.apiReceiveTimeout,
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: const TokenExpiredException(),
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final AuthTokenStore _tokenStore;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parser,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse.success(
        parser(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(ApiException.fromDio(error));
    } catch (error) {
      return ApiResponse.failure(UnexpectedApiException(error.toString()));
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parser,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.success(
        parser(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(ApiException.fromDio(error));
    } catch (error) {
      return ApiResponse.failure(UnexpectedApiException(error.toString()));
    }
  }
}
