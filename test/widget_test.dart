import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault_system/core/constants/app_strings.dart';
import 'package:vault_system/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:vault_system/features/dashboard/data/models/recent_item_model.dart';
import 'package:vault_system/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:vault_system/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:vault_system/features/vaults/data/models/vault_list_model.dart';
import 'package:vault_system/main.dart';

class _FakeDashboardRepository extends DashboardRepository {
  @override
  Future<DashboardStats> getDashboard(String token) async {
    return const DashboardStats(
      totalVaults: 3,
      totalItems: 12,
      totalFiles: 4,
      user: DashboardUser(
        id: 1,
        name: 'Test Operator',
        email: 'operator@example.com',
      ),
    );
  }

  @override
  Future<List<VaultListModel>> getRecentVaults(String token) async {
    return [
      VaultListModel(
        id: 1,
        name: 'Personal',
        createdAt: '2026-06-03T00:00:00Z',
        updatedAt: '2026-06-03T00:00:00Z',
      ),
    ];
  }

  @override
  Future<List<RecentItemModel>> getRecentItems(String token) async {
    return [
      const RecentItemModel(
        id: 1,
        vaultId: 1,
        type: 'login',
        encryptedData: 'encrypted',
        iv: 'iv',
        tag: 'tag',
        createdAt: '2026-06-03T00:00:00Z',
      ),
    ];
  }

  @override
  Future<List<dynamic>> getRecentFiles(String token) async {
    return const [];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('renders the dashboard screen with static data', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return MaterialApp(home: child);
        },
        child: DashboardScreen(
          userName: 'Test Operator',
          token: 'test-token',
          repository: _FakeDashboardRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Secure Vault'), findsOneWidget);
    expect(find.text('VAULTS'), findsOneWidget);
    expect(find.text('ITEMS'), findsOneWidget);
    expect(find.text('FILES'), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.text('Add Vault'), findsOneWidget);
    expect(find.text('Recent Vaults'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Recently Added Items'), findsOneWidget);
    expect(find.text('Login Credential'), findsOneWidget);
  });
}
