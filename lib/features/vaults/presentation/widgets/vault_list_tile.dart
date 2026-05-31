import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/models/vault_list_model.dart';
import '../screens/vault_detail_screen.dart';

class VaultListTile extends StatelessWidget {
  const VaultListTile({
    required this.vault,
    required this.token,
    required this.userName,
    required this.onCopy,
    required this.onToggleFavorite,
    required this.onMoreTap,
    super.key,
  });

  final VaultListModel vault;
  final String token;
  final String userName;
  final VoidCallback onCopy;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMoreTap;

  bool _isRecent(String createdAt) {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return false;
    return DateTime.now().difference(created).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final salt = await TokenStorage.getCryptoSalt() ?? '';
        final iterations = await TokenStorage.getCryptoIterations() ?? 100000;

        if (!context.mounted) return;

        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VaultDetailScreen(
                  vault: vault,
                  token: token,
                  userName: userName,
                  cryptoSalt: salt,
                  cryptoIterations: iterations,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      vault.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecent(vault.createdAt)
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF445566),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIcon(icon: Icons.copy_outlined, onTap: onCopy),
                SizedBox(width: 4.w),
                _ActionIcon(
                  icon: vault.isFavorited
                      ? Icons.star
                      : Icons.star_border_outlined,
                  color: vault.isFavorited
                      ? const Color(0xFFFFCC44)
                      : const Color(0xFF8899AA),
                  onTap: onToggleFavorite,
                ),
                SizedBox(width: 4.w),
                _ActionIcon(icon: Icons.more_vert, onTap: onMoreTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(icon, size: 18.sp, color: color ?? const Color(0xFF8899AA)),
      ),
    );
  }
}
