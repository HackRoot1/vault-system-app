class ApiConstants {
  const ApiConstants._();

  static const String baseUrl =
      'https://palegreen-eagle-487743.hostingersite.com/api';
  static const String register = '/register';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String vaults = '/vaults';

  static String vaultItems(int vaultId) => '/vaults/$vaultId/items';
  static String vaultItem(int vaultId, int itemId) =>
      '/vaults/$vaultId/items/$itemId';
  static String vaultDetail(int vaultId) => '/vaults/$vaultId';
}
