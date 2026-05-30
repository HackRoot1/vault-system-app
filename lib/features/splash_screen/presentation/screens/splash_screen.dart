import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../providers/splash_controller.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_brand_mark.dart';
import '../widgets/splash_status_footer.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (bootstrap) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pushReplacementNamed(
              bootstrap.nextRoute.isEmpty
                  ? AppRoutes.home
                  : bootstrap.nextRoute,
            );
          });
        },
      );
    });

    final splashState = ref.watch(splashControllerProvider);

    return Scaffold(
      body: SplashBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SplashBrandMark(size: constraints.biggest),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: constraints.maxHeight * 0.072,
                  child: SplashStatusFooter(
                    state: splashState,
                    onRetry: () {
                      ref.read(splashControllerProvider.notifier).retry();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
