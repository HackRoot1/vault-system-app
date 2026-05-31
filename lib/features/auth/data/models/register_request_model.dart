class RegisterRequestModel {
  const RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.masterPassword,
    required this.masterPasswordConfirmation,
  });

  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String masterPassword;
  final String masterPasswordConfirmation;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
    'master_password': masterPassword,
    'master_password_confirmation': masterPasswordConfirmation,
  };
}
