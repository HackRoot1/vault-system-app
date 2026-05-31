import '../../../../core/network/api_client.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final _service = AuthService();

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      return await _service.login(request);
    } on ApiException catch (e) {
      throw ApiException(
        message: _mapError(e.message),
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw const ApiException(
        message: 'Unexpected error. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    try {
      return await _service.register(request);
    } on ApiException catch (e) {
      throw ApiException(
        message: _mapError(e.message),
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw const ApiException(
        message: 'Unexpected error. Please try again.',
        statusCode: 0,
      );
    }
  }

  String _mapError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('unauthorized')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email has already been taken')) {
      return 'This email is already registered. Try signing in.';
    }
    if (lower.contains('validation')) {
      return 'Please check your inputs and try again.';
    }
    return raw;
  }
}
