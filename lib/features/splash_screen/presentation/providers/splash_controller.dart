import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/app_providers.dart';
import '../../data/models/splash_bootstrap.dart';
import '../../data/repositories/splash_repository.dart';
import '../../data/services/splash_service.dart';

final splashServiceProvider = Provider<SplashService>((ref) {
  return SplashService(ref.watch(apiClientProvider));
});

final splashRepositoryProvider = Provider<SplashRepository>((ref) {
  return SplashRepository(ref.watch(splashServiceProvider));
});

final splashControllerProvider =
    AsyncNotifierProvider<SplashController, SplashBootstrap>(
      SplashController.new,
    );

class SplashController extends AsyncNotifier<SplashBootstrap> {
  @override
  Future<SplashBootstrap> build() {
    return ref.watch(splashRepositoryProvider).initialize();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(splashRepositoryProvider).initialize(),
    );
  }
}
