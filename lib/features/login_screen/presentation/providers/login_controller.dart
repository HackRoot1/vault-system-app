import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/app_providers.dart';
import '../../data/models/login_credentials.dart';
import '../../data/repositories/login_repository.dart';
import '../../data/services/login_service.dart';
import 'login_state.dart';

final loginServiceProvider = Provider<LoginService>((ref) {
  return LoginService(ref.watch(apiClientProvider));
});

final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  return LoginRepository(ref.watch(loginServiceProvider));
});

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState(
      email: 'user@example.com',
      password: 'MySecure@Pass123',
    );
  }

  void emailChanged(String value) {
    state = state.copyWith(
      email: value,
      status: LoginStatus.idle,
      clearError: true,
    );
  }

  void passwordChanged(String value) {
    state = state.copyWith(
      password: value,
      status: LoginStatus.idle,
      clearError: true,
    );
  }

  void rememberMeChanged(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submit() async {
    if (state.isLoading) {
      return;
    }

    final email = state.email.trim();
    final password = state.password;

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Email and password are required.',
      );
      return;
    }

    state = state.copyWith(status: LoginStatus.loading, clearError: true);

    try {
      await ref
          .read(loginRepositoryProvider)
          .login(LoginCredentials(email: email, password: password));
      state = state.copyWith(status: LoginStatus.success, clearError: true);
    } on ApiException catch (error) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Unable to unlock vault.',
      );
    }
  }
}
