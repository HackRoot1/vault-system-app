import 'package:flutter/material.dart';

import '../../../vaults/data/models/vault_item_model.dart';

class RecentItemModel {
  const RecentItemModel({
    required this.id,
    required this.vaultId,
    required this.type,
    required this.encryptedData,
    required this.iv,
    required this.tag,
    required this.createdAt,
  });

  final int id;
  final int vaultId;
  final String type;
  final String encryptedData;
  final String iv;
  final String tag;
  final String createdAt;

  factory RecentItemModel.fromJson(Map<String, dynamic> json) {
    return RecentItemModel(
      id: json['id'] as int,
      vaultId: json['vault_id'] as int,
      type: json['type'] as String,
      encryptedData: json['encrypted_data'] as String,
      iv: json['iv'] as String,
      tag: json['tag'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  VaultItemModel toVaultItemModel() {
    return VaultItemModel(
      id: id,
      vaultId: vaultId,
      type: type,
      encryptedData: encryptedData,
      iv: iv,
      tag: tag,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  String get title => switch (type) {
    'login' => 'Login Credential',
    'secure_note' => 'Secure Note',
    'credit_card' => 'Credit Card',
    _ => 'Vault Item',
  };

  String get subtitle => 'Vault #$vaultId';

  IconData get icon => switch (type) {
    'login' => Icons.login_outlined,
    'secure_note' => Icons.note_outlined,
    'credit_card' => Icons.credit_card_outlined,
    _ => Icons.lock_outline,
  };
}
