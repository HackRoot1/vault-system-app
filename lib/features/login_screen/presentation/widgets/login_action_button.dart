import 'package:flutter/material.dart';

class LoginActionButton extends StatelessWidget {
  const LoginActionButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD0CDCE),
          disabledBackgroundColor: const Color(
            0xFFD0CDCE,
          ).withValues(alpha: 0.65),
          foregroundColor: const Color(0xFF101418),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF101418),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(width: 13),
                  Icon(Icons.shield_outlined, size: 22),
                ],
              ),
      ),
    );
  }
}
