import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../providers/login_controller.dart';
import '../widgets/login_background.dart';
import '../widgets/login_card.dart';
import '../widgets/login_security_footer.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != true && next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        });
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LoginBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(30, 52, 30, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 428),
                      child: LoginCard(),
                    ),
                  ),
                ),
              ),
              LoginSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
