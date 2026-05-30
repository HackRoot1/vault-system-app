import '../../../../core/network/api_response.dart';
import '../models/login_credentials.dart';
import '../models/login_response.dart';
import '../services/login_service.dart';

class LoginRepository {
  const LoginRepository(this._service);

  final LoginService _service;

  Future<LoginResponse> login(LoginCredentials credentials) async {
    final response = await _service.login(credentials);
    return switch (response) {
      ApiSuccess<LoginResponse>(:final data) => data,
      ApiFailure<LoginResponse>(:final exception) => throw exception,
    };
  }
}
