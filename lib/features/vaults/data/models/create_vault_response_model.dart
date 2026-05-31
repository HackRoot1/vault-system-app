class CreateVaultResponseModel {
  const CreateVaultResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final VaultData data;

  factory CreateVaultResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateVaultResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: VaultData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class VaultData {
  const VaultData({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String createdAt;

  factory VaultData.fromJson(Map<String, dynamic> json) {
    return VaultData(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
