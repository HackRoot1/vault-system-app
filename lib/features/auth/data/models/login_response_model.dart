import 'register_response_model.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
    required this.crypto,
  });

  final bool success;
  final String message;
  final String token;
  final LoginUserModel user;
  final CryptoModel crypto;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: data['token'] as String,
      user: LoginUserModel.fromJson(data['user'] as Map<String, dynamic>),
      crypto: CryptoModel.fromJson(data['crypto'] as Map<String, dynamic>),
    );
  }
}

class LoginUserModel {
  const LoginUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.encryptionSalt,
    required this.keyIterations,
    required this.twoFactorEnabled,
    required this.lastLoginAt,
    required this.lastLoginIp,
  });

  final int id;
  final String name;
  final String email;
  final String encryptionSalt;
  final int keyIterations;
  final bool twoFactorEnabled;
  final String? lastLoginAt;
  final String? lastLoginIp;

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      encryptionSalt: json['encryption_salt'] as String,
      keyIterations: json['key_iterations'] as int,
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] as String?,
      lastLoginIp: json['last_login_ip'] as String?,
    );
  }
}
