class SplashBootstrap {
  const SplashBootstrap({
    required this.nextRoute,
    required this.statusMessage,
    this.requiresSessionRefresh = false,
  });

  final String nextRoute;
  final String statusMessage;
  final bool requiresSessionRefresh;

  factory SplashBootstrap.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const SplashBootstrap(
        nextRoute: '/home',
        statusMessage: 'Decrypting local vault...',
      );
    }

    return SplashBootstrap(
      nextRoute: json['nextRoute'] as String? ?? '/home',
      statusMessage:
          json['statusMessage'] as String? ?? 'Decrypting local vault...',
      requiresSessionRefresh: json['requiresSessionRefresh'] as bool? ?? false,
    );
  }
}
