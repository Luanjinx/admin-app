import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_admin_app/main.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NetSpeedAdminApp shows splash screen then admin-only login screen when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AdminApiService().init();

    await tester.pumpWidget(const NetSpeedAdminApp());
    await tester.pump();

    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    expect(find.text('NetSpeed Admin'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();

    expect(find.text('NetSpeed Admin'), findsOneWidget);
    expect(find.text('Masuk Akun Administrator'), findsOneWidget);
    expect(find.text('Masuk Panel Admin'), findsOneWidget);
  });

  test('AdminApiService rejects stored non-admin sessions during init', () async {
    SharedPreferences.setMockInitialValues({
      'admin_auth_token': 'fake-token',
      'admin_user_data': '{"id": 9, "name": "Teknisi", "role": "technician"}',
    });

    await AdminApiService().init();

    expect(AdminApiService().isAuthenticated, isFalse);
    expect(AdminApiService().currentUser, isNull);
  });

  testWidgets('Admin root screen shows exit confirmation dialog on system back', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AdminApiService().init();

    await tester.pumpWidget(const NetSpeedAdminApp());
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Keluar'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin keluar dari aplikasi NetSpeed Admin?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Keluar'), findsNothing);
  });
}
