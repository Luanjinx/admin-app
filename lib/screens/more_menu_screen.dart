import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/screens/admin_cashier_broadcast_screen.dart';
import 'package:isp_admin_app/screens/catalog_infra_screen.dart';
import 'package:isp_admin_app/screens/system_settings_screen.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AdminApiService().currentUser ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Modul & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AdminColors.primaryDark,
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
              ),
              title: Text(user['name']?.toString() ?? 'Administrator', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              subtitle: Text('${user['email'] ?? '-'} • ${AdminConfig.baseUrl}'),
            ),
          ),
          const SizedBox(height: 14),
          _sectionTitle('KATALOG & LAYANAN'),
          _menuCard(context, [
            _MenuEntry('Paket Internet', 'Kelola PPPoE/Hotspot & Sync MikroTik', Icons.wifi_rounded, () => _push(context, const PackagesCrudScreen())),
            _MenuEntry('Promo & Banner', 'Kelola promo aplikasi pelanggan', Icons.local_offer_rounded, () => _push(context, const PromosCrudScreen())),
            _MenuEntry('Loket Bayar Agen', 'Proses bayar tagihan via saldo agen', Icons.point_of_sale_rounded, () => _push(context, const AgentPaymentPointScreen())),
            _MenuEntry('Broadcast OneSignal', 'Kirim push notification massal', Icons.campaign_rounded, () => _push(context, const BroadcastScreen())),
          ]),
          const SizedBox(height: 14),
          _sectionTitle('INFRASTRUKTUR & JARINGAN'),
          _menuCard(context, [
            _MenuEntry('Router MikroTik', 'Tambah, tes koneksi & sync profil', Icons.router_rounded, () => _push(context, const RoutersCrudScreen())),
            _MenuEntry('Server GenieACS', 'Konfigurasi TR-069 ACS server', Icons.settings_input_antenna_rounded, () => _push(context, const GenieacsCrudScreen())),
            _MenuEntry('ODP & Peta Jaringan', 'Kelola ODP dan koordinat Google Maps', Icons.map_rounded, () => _push(context, const OdpsMapScreen())),
          ]),
          const SizedBox(height: 14),
          _sectionTitle('SISTEM & PENGATURAN'),
          _menuCard(context, [
            _MenuEntry('Admin & Teknisi', 'Kelola akun admin dan teknisi', Icons.manage_accounts_rounded, () => _push(context, const StaffCrudScreen())),
            _MenuEntry('Halaman Situs (CMS)', 'Edit Syarat Ketentuan & Kebijakan Privasi', Icons.description_outlined, () => _push(context, const SitePagesCrudScreen())),
            _MenuEntry('Payment Gateways', 'Aktif/nonaktif kanal pembayaran otomatis', Icons.account_balance_wallet_rounded, () => _push(context, const PaymentGatewaysScreen())),
            _MenuEntry('Pengaturan Sistem ISP', 'Profil, Maps, Mobile App, WA, Telegram & QRIS', Icons.tune_rounded, () => _push(context, const SystemConfigScreen())),
            _MenuEntry('System Update', 'Cek versi & update backend Laravel', Icons.system_update_alt_rounded, () => _push(context, const SystemUpdateScreen())),
          ]),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final ok = await confirmAdminDialog(
                context,
                title: 'Keluar Aplikasi Admin',
                message: 'Yakin ingin keluar dari akun Admin?',
                isDanger: true,
              );
              if (ok) {
                await AdminApiService().logout();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar Akun Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.textMuted),
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<_MenuEntry> entries) {
    return Card(
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          return Column(
            children: [
              ListTile(
                onTap: e.onTap,
                leading: Icon(e.icon, color: AdminColors.primaryAccent),
                title: Text(e.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text(e.subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AdminColors.textMuted),
              ),
              if (i < entries.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuEntry(this.title, this.subtitle, this.icon, this.onTap);
}

