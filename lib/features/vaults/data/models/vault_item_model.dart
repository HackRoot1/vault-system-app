import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/crypto/vault_crypto.dart';

class VaultItemModel {
  const VaultItemModel({
    required this.id,
    required this.vaultId,
    required this.type,
    required this.encryptedData,
    required this.iv,
    required this.tag,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int vaultId;
  final String type;
  final String encryptedData;
  final String iv;
  final String tag;
  final String createdAt;
  final String updatedAt;

  factory VaultItemModel.fromJson(Map<String, dynamic> json) {
    return VaultItemModel(
      id: json['id'] as int,
      vaultId: json['vault_id'] as int,
      type: json['type'] as String,
      encryptedData: json['encrypted_data'] as String,
      iv: json['iv'] as String,
      tag: json['tag'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic>? decryptPayload(Uint8List key) {
    try {
      final plain = VaultCrypto.decrypt(
        encryptedDataB64: encryptedData,
        ivB64: iv,
        tagB64: tag,
        key: key,
      );
      return jsonDecode(plain) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
