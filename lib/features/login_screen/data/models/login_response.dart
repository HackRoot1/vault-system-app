class LoginResponse {
  const LoginResponse({required this.token, required this.email, this.name});

  final String token;
  final String email;
  final String? name;

  factory LoginResponse.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const LoginResponse(token: '', email: '');
    }

    final data = json['data'];
    final payload = data is Map<String, dynamic> ? data : json;
    final user = payload['user'];
    final userMap = user is Map<String, dynamic> ? user : payload;

    return LoginResponse(
      token:
          payload['token'] as String? ??
          payload['access_token'] as String? ??
          payload['accessToken'] as String? ??
          '',
      email: userMap['email'] as String? ?? '',
      name: userMap['name'] as String?,
    );
  }
}
