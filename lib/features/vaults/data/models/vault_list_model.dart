class VaultListModel {
  VaultListModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorited = false,
  });

  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;
  bool isFavorited;

  factory VaultListModel.fromJson(Map<String, dynamic> json) {
    return VaultListModel(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
