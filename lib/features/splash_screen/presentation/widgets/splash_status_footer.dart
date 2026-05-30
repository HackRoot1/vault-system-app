import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/splash_screen/data/models/splash_bootstrap.dart';
import '../../../../theme/app_colors.dart';

class SplashStatusFooter extends StatelessWidget {
  const SplashStatusFooter({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<SplashBootstrap> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final statusText = state.when(
      data: (bootstrap) => bootstrap.statusMessage,
      error: (error, stackTrace) => 'Unable to decrypt vault',
      loading: () => 'Decrypting local vault...',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FractionallySizedBox(
          widthFactor: 0.685,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              minHeight: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.vaultLine),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 35),
        _StatusLine(
          statusText: statusText,
          isError: state.hasError,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.statusText,
    required this.isError,
    required this.onRetry,
  });

  final String statusText;
  final bool isError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.shield_outlined,
          color: AppColors.vaultMuted,
          size: 24,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            statusText.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.vaultMuted,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 3.6,
            ),
          ),
        ),
      ],
    );

    if (!isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: content,
      );
    }

    return TextButton(onPressed: onRetry, child: content);
  }
}
