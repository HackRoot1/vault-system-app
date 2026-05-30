import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_system/features/splash_screen/presentation/widgets/splash_background.dart';
import 'package:vault_system/features/splash_screen/presentation/widgets/splash_brand_mark.dart';

void main() {
  testWidgets('renders the splash brand composition', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SplashBackground(child: SplashBrandMark(size: Size(720, 1600))),
        ),
      ),
    );

    expect(find.text('VAULT SYSTEM'), findsOneWidget);
    expect(find.text('SECURE YOUR DIGITAL SECRETS'), findsOneWidget);
  });
}
