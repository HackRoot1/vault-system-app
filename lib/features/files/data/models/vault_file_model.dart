class VaultFileModel {
  const VaultFileModel({
    required this.id,
    required this.vaultId,
    required this.fileName,
    required this.iv,
    required this.tag,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int vaultId;
  final String fileName;
  final String iv;
  final String tag;
  final String createdAt;
  final String updatedAt;

  factory VaultFileModel.fromJson(Map<String, dynamic> json) {
    return VaultFileModel(
      id: json['id'] as int,
      vaultId: json['vault_id'] as int,
      fileName: json['file_name'] as String,
      iv: json['iv'] as String,
      tag: json['tag'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  String get extension {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  String get displayName {
    if (fileName.length <= 24) {
      return fileName;
    }

    final ext = extension.isNotEmpty ? '.$extension' : '';
    final base = ext.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - ext.length);

    if (base.length <= 20) {
      return '$base...$ext';
    }

    return '${base.substring(0, 20)}...$ext';
  }
}
