import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class LoginOptionsRow extends StatelessWidget {
  const LoginOptionsRow({
    required this.rememberMe,
    required this.onRememberChanged,
    super.key,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rememberControl = InkWell(
          onTap: () => onRememberChanged(!rememberMe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: rememberMe
                      ? AppColors.vaultText.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: AppColors.vaultMuted.withValues(alpha: 0.45),
                  ),
                ),
                child: rememberMe
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color: AppColors.vaultText,
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              const Text(
                'Remember Me',
                style: TextStyle(
                  color: AppColors.vaultText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        );

        final forgotButton = TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.vaultText,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              color: AppColors.vaultText,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        );

        if (constraints.maxWidth < 290) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rememberControl,
              const SizedBox(height: 16),
              forgotButton,
            ],
          );
        }

        return Row(children: [rememberControl, const Spacer(), forgotButton]);
      },
    );
  }
}
