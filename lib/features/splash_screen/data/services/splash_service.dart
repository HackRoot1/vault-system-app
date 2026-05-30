import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/splash_bootstrap.dart';

class SplashService {
  const SplashService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResponse<SplashBootstrap>> bootstrap() {
    return _apiClient.get<SplashBootstrap>(
      AppConstants.splashBootstrapEndpoint,
      parser: SplashBootstrap.fromJson,
    );
  }
}
