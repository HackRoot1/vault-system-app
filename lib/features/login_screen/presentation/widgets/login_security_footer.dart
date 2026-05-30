import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class LoginSecurityFooter extends StatelessWidget {
  const LoginSecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 428,
          child: Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A27D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x6600A27D), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              const Text(
                'SYSTEM SECURE',
                style: TextStyle(
                  color: AppColors.vaultMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.1,
                ),
              ),
              const Spacer(),
              const Text(
                'ENCRYPTION: AES-256-GCM',
                style: TextStyle(
                  color: AppColors.vaultMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
