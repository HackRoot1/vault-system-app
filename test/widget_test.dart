import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_system/core/constants/app_strings.dart';
import 'package:vault_system/main.dart';

void main() {
  testWidgets('renders the login screen', (tester) async {
    await tester.pumpWidget(const VaultSystemApp());

    expect(find.text(AppStrings.vaultTitle), findsOneWidget);
    expect(find.text('DECRYPTING LOCAL VAULT...'), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('DECRYPTING LOCAL VAULT...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('VERIFYING CREDENTIALS...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('INITIALIZING SECURE CHANNEL...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.vaultTitle), findsOneWidget);
    expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    expect(find.text(AppStrings.email), findsOneWidget);
    expect(find.text(AppStrings.password), findsOneWidget);
    expect(find.text(AppStrings.login), findsOneWidget);
    expect(find.text(AppStrings.systemSecure), findsOneWidget);
    expect(find.text(AppStrings.encryptionStatus), findsOneWidget);
  });

  testWidgets('opens the register screen from login', (tester) async {
    await tester.pumpWidget(const VaultSystemApp());

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final registerLink = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains(AppStrings.register),
    );

    final richText = tester.widget<RichText>(registerLink);
    final textSpan = richText.text as TextSpan;
    final registerSpan = textSpan.children!.last as TextSpan;
    final recognizer = registerSpan.recognizer! as TapGestureRecognizer;

    recognizer.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Create Operator Profile'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('MASTER PASSWORD'), findsOneWidget);
    expect(find.text('ENCRYPTION LEVEL'), findsOneWidget);
  });
}
