class RegisterResponseModel {
  const RegisterResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
    required this.crypto,
  });

  final bool success;
  final String message;
  final String token;
  final UserModel user;
  final CryptoModel crypto;

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return RegisterResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      crypto: CryptoModel.fromJson(data['crypto'] as Map<String, dynamic>),
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.encryptionSalt,
    required this.keyIterations,
  });

  final int id;
  final String name;
  final String email;
  final String encryptionSalt;
  final int keyIterations;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      encryptionSalt: json['encryption_salt'] as String,
      keyIterations: json['key_iterations'] as int,
    );
  }
}

class CryptoModel {
  const CryptoModel({required this.salt, required this.iterations});

  final String salt;
  final int iterations;

  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      salt: json['salt'] as String,
      iterations: json['iterations'] as int,
    );
  }
}
