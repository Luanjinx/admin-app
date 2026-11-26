import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _loadingInvoices = true;
  bool _loadingPayments = true;
  String _invoiceStatus = 'unpaid';
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvoices();
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _loadingInvoices = true);
    final query = <String, String>{};
    if (_invoiceStatus.isNotEmpty) query['status'] = _invoiceStatus;
    if (_searchCtrl.text.trim().isNotEmpty) query['search'] = _searchCtrl.text.trim();
    final res = await AdminApiService().get('/invoices', query: query);
    if (!mounted) return;
    setState(() {
      _invoices = extractList(res['data']);
      _loadingInvoices = false;
    });
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    final res = await AdminApiService().get('/payments');
    if (!mounted) return;
    setState(() {
      _payments = extractList(res['data']);
      _loadingPayments = false;
    });
  }

  Future<void> _markPaid(Map<String, dynamic> inv) async {
    final ok = await confirmAdminDialog(
      context,
      title: 'Tandai Tagihan Lunas',
      message:
          'Lunasi ${inv['invoice_number']} (${inv['customer']?['name'] ?? '-'}) sebesar ${AdminConfig.rupiah(inv['total_amount'])}? Internet pelanggan akan otomatis diaktifkan.',
    );
    if (!ok || !mounted) return;

    final res = await AdminApiService().post('/invoices/${inv['id']}/mark-paid');
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    _loadInvoices();
    _loadPayments();
  }

  Future<void> _verifyPayment(Map<String, dynamic> p) async {
    final ok = await confirmAdminDialog(
      context,
      title: 'Verifikasi Pembayaran',
      message: 'Setujui pembayaran ${p['payment_reference']} sebesar ${AdminConfig.rupiah(p['amount_paid'])}?',
    );
    if (!ok || !mounted) return;

    final res = await AdminApiService().post('/payments/${p['id']}/verify');
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    _loadPayments();
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan & Pembayaran'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AdminColors.primary,
          tabs: const [
            Tab(text: 'Tagihan (Invoice)'),
            Tab(text: 'Riwayat & Bukti Bayar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onSubmitted: (_) => _loadInvoices(),
                            decoration: InputDecoration(
                              hintText: 'Cari no invoice atau nama pelanggan',
                              prefixIcon: const Icon(Icons.search_rounded),
                              isDense: true,
                              filled: true,
                              fillColor: AdminColors.surfaceAlt,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _loadInvoices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primaryAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cari'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip('unpaid', 'Belum Lunas'),
                        const SizedBox(width: 8),
                        _chip('paid', 'Lunas'),
                        const SizedBox(width: 8),
                        _chip('', 'Semua'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: _loadingInvoices
                      ? const Center(child: CircularProgressIndicator())
                      : _invoices.isEmpty
                          ? adminEmptyState('Tidak ada data tagihan.')
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _invoices.length,
                              itemBuilder: (context, idx) {
                                final inv = _invoices[idx];
                                final isPaid = inv['status'] == 'paid';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              inv['invoice_number']?.toString() ?? '-',
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                                            ),
                                            adminBadge(
                                              (inv['status']?.toString() ?? '-').toUpperCase(),
                                              color: statusColor(inv['status']?.toString()),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${inv['customer']?['name'] ?? '-'} • Periode ${inv['period'] ?? '-'}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AdminColors.textMuted),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AdminConfig.rupiah(inv['total_amount']),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: AdminColors.primaryDark,
                                              ),
                                            ),
                                            if (!isPaid)
                                              ElevatedButton(
                                                onPressed: () => _markPaid(inv),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AdminColors.success,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Tandai Lunas'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
          RefreshIndicator(
            onRefresh: _loadPayments,
            child: _loadingPayments
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? adminEmptyState('Belum ada data pembayaran.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _payments.length,
                        itemBuilder: (context, idx) {
                          final p = _payments[idx];
                          final verified = p['is_verified'] == true || p['is_verified'] == 1;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                '${p['payment_reference'] ?? '-'} • ${AdminConfig.rupiah(p['amount_paid'])}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                '${p['invoice']?['customer']?['name'] ?? '-'} • ${p['payment_method'] ?? '-'}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                              ),
                              trailing: verified
                                  ? adminBadge('VERIFIED', color: AdminColors.success)
                                  : ElevatedButton(
                                      onPressed: () => _verifyPayment(p),
                                      child: const Text('Verifikasi'),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _invoiceStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) {
        if (s) {
          setState(() => _invoiceStatus = value);
          _loadInvoices();
        }
      },
      selectedColor: AdminColors.primaryAccent,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AdminColors.textHeadline,
      ),
    );
  }
}

