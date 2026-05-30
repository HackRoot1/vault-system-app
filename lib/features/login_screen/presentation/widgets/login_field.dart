import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class LoginField extends StatelessWidget {
  const LoginField({
    required this.label,
    required this.controller,
    required this.leading,
    required this.onChanged,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final Widget leading;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.vaultText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 62,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: AppColors.vaultText,
            style: const TextStyle(
              color: AppColors.vaultText,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF081C2D),
              contentPadding: const EdgeInsets.only(top: 19, bottom: 19),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, right: 14),
                child: leading,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 56,
                minHeight: 24,
              ),
              suffixIcon: trailing == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 17),
                      child: trailing,
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(
                  color: AppColors.vaultText.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
