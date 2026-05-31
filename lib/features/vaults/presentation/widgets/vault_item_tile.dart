import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/vault_item_model.dart';

class VaultItemTile extends StatelessWidget {
  const VaultItemTile({
    required this.item,
    required this.decryptionKey,
    super.key,
  });

  final VaultItemModel item;
  final Uint8List? decryptionKey;

  @override
  Widget build(BuildContext context) {
    final payload = decryptionKey != null
        ? item.decryptPayload(decryptionKey!)
        : null;
    final title =
        payload?['title'] ?? payload?['card_name'] ?? 'Encrypted Item';
    final subtitle = _buildSubtitle(item.type, payload);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _typeIcon(item.type),
              size: 18.sp,
              color: const Color(0xFF8899AA),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF8899AA),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18.sp,
            color: const Color(0xFF8899AA),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'login' => Icons.login_outlined,
      'secure_note' => Icons.note_outlined,
      'credit_card' => Icons.credit_card_outlined,
      _ => Icons.lock_outline,
    };
  }

  String _buildSubtitle(String type, Map<String, dynamic>? payload) {
    if (payload == null) return 'Tap to decrypt';

    switch (type) {
      case 'login':
        return payload['username'] as String? ?? '';
      case 'secure_note':
        final content = payload['content'] as String? ?? '';
        return content.length > 40 ? '${content.substring(0, 40)}...' : content;
      case 'credit_card':
        final number = payload['number'] as String? ?? '';
        return number.length >= 4
            ? '**** ${number.substring(number.length - 4)}'
            : '****';
      default:
        return '';
    }
  }
}
