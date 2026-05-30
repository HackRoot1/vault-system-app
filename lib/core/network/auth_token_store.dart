abstract interface class AuthTokenStore {
  Future<String?> readToken();
}

class InMemoryAuthTokenStore implements AuthTokenStore {
  const InMemoryAuthTokenStore({this.token});

  final String? token;

  @override
  Future<String?> readToken() async => token;
}
