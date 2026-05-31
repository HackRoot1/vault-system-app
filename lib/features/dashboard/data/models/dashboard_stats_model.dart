class DashboardStats {
  const DashboardStats({
    required this.totalVaults,
    required this.totalItems,
    required this.totalFiles,
    required this.user,
  });

  final int totalVaults;
  final int totalItems;
  final int totalFiles;
  final DashboardUser user;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DashboardStats(
      totalVaults: data['total_vaults'] as int,
      totalItems: data['total_items'] as int,
      totalFiles: data['total_file_items'] as int,
      user: DashboardUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

class DashboardUser {
  const DashboardUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
