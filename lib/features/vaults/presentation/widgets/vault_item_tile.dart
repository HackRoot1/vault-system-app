import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/vault_item_model.dart';

class VaultItemTile extends StatelessWidget {
  const VaultItemTile({
    required this.item,
    required this.decryptedPayload,
    this.onEditTap,
    this.onDeleteTap,
    super.key,
  });

  final VaultItemModel item;
  final Map<String, dynamic>? decryptedPayload;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final title =
        decryptedPayload?['title'] ??
        decryptedPayload?['card_name'] ??
        'Encrypted Item';
    final subtitle = _buildSubtitle(item.type, decryptedPayload);

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
          if (onEditTap != null || onDeleteTap != null)
            GestureDetector(
              onTap: () => _showItemOptions(context),
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF8899AA),
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8899AA)),
        ],
      ),
    );
  }

  void _showItemOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF112240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _typeLabel(item.type),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatDate(item.createdAt),
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF8899AA)),
            ),
            SizedBox(height: 12.h),
            const Divider(color: Color(0x14FFFFFF)),
            SizedBox(height: 4.h),
            if (onEditTap != null)
              _OptionRow(
                icon: Icons.edit_outlined,
                label: 'Edit Item',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(context);
                  onEditTap!();
                },
              ),
            if (onDeleteTap != null)
              _OptionRow(
                icon: Icons.delete_outline,
                label: 'Delete Item',
                color: const Color(0xFFCC3333),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteTap!();
                },
              ),
            SizedBox(height: 4.h),
          ],
        ),
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

  String _typeLabel(String type) {
    switch (type) {
      case 'login':
        return 'Login Credential';
      case 'secure_note':
        return 'Secure Note';
      case 'credit_card':
        return 'Credit Card';
      default:
        return 'Vault Item';
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
