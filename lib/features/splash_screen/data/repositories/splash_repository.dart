import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_response.dart';
import '../../../../routes/app_routes.dart';
import '../models/splash_bootstrap.dart';
import '../services/splash_service.dart';

class SplashRepository {
  const SplashRepository(this._service);

  final SplashService _service;

  Future<SplashBootstrap> initialize() async {
    final startedAt = DateTime.now();

    final bootstrap =
        AppConstants.apiBaseUrl.isEmpty || !AppConstants.splashBootstrapEnabled
        ? const SplashBootstrap(
            nextRoute: AppRoutes.login,
            statusMessage: 'Decrypting local vault...',
          )
        : await _fetchBootstrap();

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = AppConstants.splashMinimumDuration - elapsed;
    if (!remaining.isNegative) {
      await Future<void>.delayed(remaining);
    }

    return bootstrap;
  }

  Future<SplashBootstrap> _fetchBootstrap() async {
    final response = await _service.bootstrap();
    return switch (response) {
      ApiSuccess<SplashBootstrap>(:final data) => data,
      ApiFailure<SplashBootstrap>() => const SplashBootstrap(
        nextRoute: AppRoutes.login,
        statusMessage: 'Decrypting local vault...',
      ),
    };
  }
}
