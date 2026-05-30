import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/login_credentials.dart';
import '../models/login_response.dart';

class LoginService {
  const LoginService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResponse<LoginResponse>> login(LoginCredentials credentials) {
    return _apiClient.post<LoginResponse>(
      AppConstants.loginEndpoint,
      data: credentials.toJson(),
      parser: LoginResponse.fromJson,
    );
  }
}
