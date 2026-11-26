import 'package:flutter/material.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/screens/login_screen.dart';
import 'package:isp_admin_app/screens/main_nav_screen.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminApiService().init();
  runApp(const NetSpeedAdminApp());
}

class NetSpeedAdminApp extends StatelessWidget {
  const NetSpeedAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetSpeed Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      home: ValueListenableBuilder<bool>(
        valueListenable: AdminApiService().authState,
        builder: (context, isAuth, _) {
          return isAuth ? const MainNavScreen() : const LoginScreen();
        },
      ),
    );
  }
}
