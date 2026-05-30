enum LoginStatus { idle, loading, success, failure }

class LoginState {
  const LoginState({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.obscurePassword = true,
    this.status = LoginStatus.idle,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool obscurePassword;
  final LoginStatus status;
  final String? errorMessage;

  bool get isLoading => status == LoginStatus.loading;
  bool get isAuthenticated => status == LoginStatus.success;

  LoginState copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? obscurePassword,
    LoginStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
