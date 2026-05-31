import 'package:flutter/material.dart';

class VaultModel {
  const VaultModel({
    required this.name,
    required this.lastAccessed,
    required this.status,
    required this.icon,
  });

  final String name;
  final String lastAccessed;
  final String status;
  final IconData icon;
}
