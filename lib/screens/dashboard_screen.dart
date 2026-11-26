import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;
  final VoidCallback onOpenAgentCashier;
  final VoidCallback onOpenBroadcast;
  final VoidCallback onOpenRouters;
  final VoidCallback onOpenMoreMenu;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onOpenAgentCashier,
    required this.onOpenBroadcast,
    required this.onOpenRouters,
    required this.onOpenMoreMenu,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _runningIsolir = false;
  bool _generatingInvoices = false;
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _routers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final res = await AdminApiService().get('/dashboard');
    if (!mounted) return;
    if (res['success'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data']);
      setState(() {
        _overview = data['overview'] is Map
            ? Map<String, dynamic>.from(data['overview'])
            : <String, dynamic>{};
        _routers = extractList(data['routers']);
      });
    } else {
      showAdminSnackBar(context, res['message']?.toString() ?? 'Gagal memuat dashboard', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _runAutoIsolir() async {
    final ok = await confirmAdminDialog(
      context,
      title: 'Jalankan Auto-Isolir',
      message: 'Pelanggan yang melewati jatuh tempo akan otomatis diisolir di MikroTik. Lanjutkan?',
      isDanger: true,
    );
    if (!ok || !mounted) return;

    setState(() => _runningIsolir = true);
    final res = await AdminApiService().post('/isolir/run');
    if (!mounted) return;
    setState(() => _runningIsolir = false);
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    await _loadDashboard();
  }

  Future<void> _generateMonthlyInvoices() async {
    final ok = await confirmAdminDialog(
      context,
      title: 'Generate Tagihan Bulanan',
      message: 'Buat tagihan otomatis bulan berjalan untuk seluruh pelanggan PPPoE aktif?',
    );
    if (!ok || !mounted) return;

    setState(() => _generatingInvoices = true);
    final res = await AdminApiService().post('/invoices/generate-monthly');
    if (!mounted) return;
    setState(() => _generatingInvoices = false);
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final userName = AdminApiService().currentUser?['name']?.toString() ?? 'Administrator';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NetSpeed Admin'),
            Text(
              'Halo, $userName',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Semua Modul & Pengaturan',
            onPressed: widget.onOpenMoreMenu,
            icon: const Icon(Icons.apps_rounded),
          ),
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Omzet & Tagihan Hero Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AdminColors.primaryDark, AdminColors.primaryAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemasukan Bulan Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AdminConfig.rupiah(_overview['paid_amount']),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _heroStat(
                                'Lunas',
                                '${_overview['paid_count'] ?? 0} invoice',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _heroStat(
                                'Belum Lunas',
                                '${_overview['unpaid_count'] ?? 0} (${AdminConfig.rupiah(_overview['unpaid_amount'])})',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Overview Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      _kpiCard(
                        'Pelanggan Aktif',
                        '${_overview['active_customers'] ?? 0} / ${_overview['total_customers'] ?? 0}',
                        Icons.people_alt_rounded,
                        AdminColors.success,
                        () => widget.onNavigateTab(1),
                      ),
                      _kpiCard(
                        'Pelanggan Isolir',
                        '${_overview['isolated_customers'] ?? 0}',
                        Icons.block_rounded,
                        AdminColors.danger,
                        () => widget.onNavigateTab(1),
                      ),
                      _kpiCard(
                        'PPPoE / Hotspot Live',
                        '${_overview['active_pppoe_sessions'] ?? 0} / ${_overview['active_hotspot_sessions'] ?? 0}',
                        Icons.wifi_tethering_rounded,
                        AdminColors.secondary,
                        () => widget.onNavigateTab(3),
                      ),
                      _kpiCard(
                        'Router Online',
                        '${_overview['online_routers'] ?? 0} / ${_overview['total_routers'] ?? 0}',
                        Icons.router_rounded,
                        AdminColors.info,
                        widget.onOpenRouters,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Antrean Perlu Tindakan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.textHeadline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _queueTile(
                          'Pengajuan Paket (PSB/Upgrade)',
                          _overview['pending_package_requests'] ?? 0,
                          Icons.fact_check_rounded,
                          () => widget.onNavigateTab(4),
                        ),
                        const Divider(height: 1),
                        _queueTile(
                          'Pendaftaran Mitra Agen Baru',
                          _overview['pending_agents'] ?? 0,
                          Icons.storefront_rounded,
                          () => widget.onNavigateTab(4),
                        ),
                        const Divider(height: 1),
                        _queueTile(
                          'Pengajuan Tarik Saldo Agen',
                          _overview['pending_agent_withdrawals'] ?? 0,
                          Icons.account_balance_wallet_rounded,
                          () => widget.onNavigateTab(4),
                        ),
                        const Divider(height: 1),
                        _queueTile(
                          'Verifikasi Bukti Pembayaran',
                          _overview['pending_payments'] ?? 0,
                          Icons.payments_rounded,
                          () => widget.onNavigateTab(2),
                        ),
                        const Divider(height: 1),
                        _queueTile(
                          'Order Voucher Hotspot Pending',
                          _overview['pending_voucher_orders'] ?? 0,
                          Icons.confirmation_number_rounded,
                          () => widget.onNavigateTab(3),
                        ),
                        const Divider(height: 1),
                        _queueTile(
                          'Tiket Gangguan & SPK Aktif',
                          ((_overview['open_tickets'] ?? 0) as num).toInt() +
                              ((_overview['active_work_orders'] ?? 0) as num).toInt(),
                          Icons.build_circle_rounded,
                          () => widget.onNavigateTab(4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Aksi Cepat Admin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.textHeadline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _quickActionBtn(
                        'Generate Tagihan',
                        Icons.receipt_long_rounded,
                        AdminColors.primaryAccent,
                        _generatingInvoices ? null : _generateMonthlyInvoices,
                      ),
                      _quickActionBtn(
                        'Jalankan Isolir',
                        Icons.gpp_bad_rounded,
                        AdminColors.danger,
                        _runningIsolir ? null : _runAutoIsolir,
                      ),
                      _quickActionBtn(
                        'Loket Bayar Agen',
                        Icons.point_of_sale_rounded,
                        AdminColors.secondary,
                        widget.onOpenAgentCashier,
                      ),
                      _quickActionBtn(
                        'Broadcast Push',
                        Icons.campaign_rounded,
                        AdminColors.info,
                        widget.onOpenBroadcast,
                      ),
                    ],
                  ),

                  if (_routers.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monitor Router MikroTik',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textHeadline,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onOpenRouters,
                          child: const Text('Kelola'),
                        ),
                      ],
                    ),
                    ..._routers.map(
                      (r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor(r['status']?.toString()).withValues(alpha: 0.14),
                            child: Icon(
                              Icons.router_rounded,
                              color: statusColor(r['status']?.toString()),
                            ),
                          ),
                          title: Text(
                            r['name']?.toString() ?? '-',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${r['host']}:${r['port']} • CPU ${r['cpu_load'] ?? 0}% • ${r['uptime'] ?? '-'}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
                          ),
                          trailing: adminBadge(
                            (r['status']?.toString() ?? 'unknown').toUpperCase(),
                            color: statusColor(r['status']?.toString()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AdminColors.textMuted),
                ],
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.textHeadline,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _queueTile(String title, dynamic count, IconData icon, VoidCallback onTap) {
    final c = int.tryParse(count?.toString() ?? '0') ?? 0;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AdminColors.primaryAccent),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      trailing: adminBadge(
        '$c',
        color: c > 0 ? AdminColors.warning : AdminColors.textMuted,
      ),
    );
  }

  Widget _quickActionBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
