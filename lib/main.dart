import 'package:flutter/material.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AdminSplashScreen(),
    );
  }
}
