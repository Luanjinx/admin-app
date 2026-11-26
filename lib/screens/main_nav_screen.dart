import 'package:flutter/material.dart';
import 'package:isp_admin_app/screens/admin_cashier_broadcast_screen.dart';
import 'package:isp_admin_app/screens/billing_screen.dart';
import 'package:isp_admin_app/screens/catalog_infra_screen.dart';
import 'package:isp_admin_app/screens/customers_screen.dart';
import 'package:isp_admin_app/screens/dashboard_screen.dart';
import 'package:isp_admin_app/screens/more_menu_screen.dart';
import 'package:isp_admin_app/screens/network_screen.dart';
import 'package:isp_admin_app/screens/operations_screen.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
        onOpenAgentCashier: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentPaymentPointScreen())),
        onOpenBroadcast: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen())),
        onOpenRouters: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutersCrudScreen())),
        onOpenMoreMenu: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreMenuScreen())),
      ),
      const CustomersScreen(),
      const BillingScreen(),
      const NetworkScreen(),
      const OperationsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmAdminAppExit(context);
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Pelanggan'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Tagihan'),
            NavigationDestination(icon: Icon(Icons.router_rounded), label: 'Jaringan'),
            NavigationDestination(icon: Icon(Icons.fact_check_rounded), label: 'Approval'),
          ],
        ),
      ),
    );
  }
}

