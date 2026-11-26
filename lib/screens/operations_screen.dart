import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;

  List<Map<String, dynamic>> _packageRequests = [];
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _workOrders = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _technicians = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final res = await Future.wait([
      AdminApiService().get('/package-requests'),
      AdminApiService().get('/agents'),
      AdminApiService().get('/work-orders'),
      AdminApiService().get('/tickets'),
      AdminApiService().get('/staff', query: {'role': 'technician'}),
    ]);
    if (!mounted) return;
    setState(() {
      _packageRequests = extractList(res[0]['data']);
      _agents = extractList(res[1]['data']);
      _workOrders = extractList(res[2]['data']);
      _tickets = extractList(res[3]['data']);
      _technicians = extractList(res[4]['data']);
      _loading = false;
    });
  }

  Future<void> _approveAgentDialog(Map<String, dynamic> agent) async {
    final feeCtrl = TextEditingController(
      text: agent['commission_per_transaction']?.toString() ?? '2000',
    );
    final initBalCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Setujui Agen ${agent['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            adminTextField(feeCtrl, 'Komisi per Transaksi (Rp)', keyboardType: TextInputType.number),
            adminTextField(initBalCtrl, 'Saldo Deposit Awal (Opsional)', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Setujui')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res = await AdminApiService().post('/agents/${agent['id']}/approve', body: {
      'commission_per_transaction': double.tryParse(feeCtrl.text) ?? 2000,
      'initial_balance': double.tryParse(initBalCtrl.text) ?? 0,
    });
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
    _loadAll();
  }

  Future<void> _topUpAgentDialog(Map<String, dynamic> agent) async {
    final amountCtrl = TextEditingController(text: '100000');
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Top-Up Saldo ${agent['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            adminTextField(amountCtrl, 'Nominal Top-Up (Rp)', keyboardType: TextInputType.number),
            adminTextField(notesCtrl, 'Catatan Setoran'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Top-Up')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res = await AdminApiService().post('/agents/${agent['id']}/top-up', body: {
      'amount': double.tryParse(amountCtrl.text) ?? 0,
      'notes': notesCtrl.text.trim(),
    });
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
    _loadAll();
  }

  Future<void> _openTicketDetail(Map<String, dynamic> ticket) async {
    final id = ticket['id'];
    final detailRes = await AdminApiService().get('/tickets/$id');
    if (!mounted) return;
    final data = detailRes['data'] is Map ? Map<String, dynamic>.from(detailRes['data']) : ticket;
    final replies = extractList(data['replies']);
    final replyCtrl = TextEditingController();
    String status = data['status']?.toString() ?? 'open';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data['ticket_number'] ?? '-'} • ${data['subject'] ?? '-'}',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                '${data['customer']?['name'] ?? '-'} • ${data['description'] ?? ''}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
              ),
              const Divider(height: 18),
              Expanded(
                child: replies.isEmpty
                    ? adminEmptyState('Belum ada balasan tiket.')
                    : ListView.builder(
                        itemCount: replies.length,
                        itemBuilder: (_, i) {
                          final r = replies[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['user']?['name']?.toString() ?? 'Sistem',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11.5),
                                ),
                                Text(r['message']?.toString() ?? ''),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Ubah Status Tiket', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (v) => setSheetState(() => status = v ?? 'open'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Tulis balasan admin...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (replyCtrl.text.trim().isEmpty) return;
                      final res = await AdminApiService().post('/tickets/$id/reply', body: {
                        'message': replyCtrl.text.trim(),
                        'status': status,
                      });
                      if (!ctx.mounted) return;
                      if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                      if (res['success'] == true) {
                        Navigator.pop(ctx);
                        _loadAll();
                      }
                    },
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignWorkOrderDialog(Map<String, dynamic> order) async {
    int? techId = int.tryParse(order['technician_id']?.toString() ?? '');
    String status = order['status']?.toString() ?? 'pending';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Assign SPK ${order['order_number'] ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                initialValue: techId,
                decoration: const InputDecoration(labelText: 'Teknisi Lapangan', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('- Belum Ditugaskan -')),
                  ..._technicians.map((t) => DropdownMenuItem(
                        value: int.tryParse(t['id'].toString()),
                        child: Text(t['name']?.toString() ?? '-'),
                      )),
                ],
                onChanged: (v) => setDlgState(() => techId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status SPK', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (v) => setDlgState(() => status = v ?? 'pending'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final res = await AdminApiService().post('/work-orders/${order['id']}/assign', body: {
      'technician_id': techId,
      'status': status,
    });
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval, Agen & SPK'),
        actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded))],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AdminColors.primary,
          tabs: const [
            Tab(text: 'Pengajuan Paket'),
            Tab(text: 'Mitra Agen'),
            Tab(text: 'SPK Teknisi'),
            Tab(text: 'Tiket Bantuan'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Package Requests
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _packageRequests.isEmpty
                      ? adminEmptyState('Tidak ada pengajuan paket.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _packageRequests.length,
                          itemBuilder: (_, idx) {
                            final r = _packageRequests[idx];
                            final isPending = r['status'] == 'pending';
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
                                        Text(r['request_number']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                                        adminBadge((r['status']?.toString() ?? '-').toUpperCase(), color: statusColor(r['status']?.toString())),
                                      ],
                                    ),
                                    Text('${r['customer']?['name'] ?? '-'} • ${r['requested_package']?['name'] ?? '-'}'),
                                    if (isPending) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final res = await AdminApiService().post('/package-requests/${r['id']}/approve');
                                                if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                                _loadAll();
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success, foregroundColor: Colors.white),
                                              child: const Text('Setujui'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () async {
                                                final ctrl = TextEditingController(text: 'Ditolak oleh Admin');
                                                final ok = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Alasan Penolakan'),
                                                    content: adminTextField(ctrl, 'Alasan'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tolak')),
                                                    ],
                                                  ),
                                                );
                                                if (ok != true) return;
                                                final res = await AdminApiService().post('/package-requests/${r['id']}/reject', body: {'reason': ctrl.text.trim()});
                                                if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                                _loadAll();
                                              },
                                              child: const Text('Tolak', style: TextStyle(color: AdminColors.danger)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 2. Agents
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _agents.isEmpty
                      ? adminEmptyState('Belum ada mitra agen terdaftar.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _agents.length,
                          itemBuilder: (_, idx) {
                            final a = _agents[idx];
                            final appStatus = a['approval_status']?.toString() ?? 'approved';
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
                                        Text('${a['agent_code']} • ${a['name']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                                        adminBadge(appStatus.toUpperCase(), color: statusColor(appStatus)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Saldo: ${AdminConfig.rupiah(a['balance'])} • Komisi: ${AdminConfig.rupiah(a['commission_per_transaction'])}'),
                                    Text('${a['phone'] ?? '-'} • ${a['address'] ?? '-'}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AdminColors.textMuted)),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (appStatus != 'approved')
                                          ElevatedButton(
                                            onPressed: () => _approveAgentDialog(a),
                                            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success, foregroundColor: Colors.white),
                                            child: const Text('Setujui'),
                                          ),
                                        if (appStatus == 'pending')
                                          OutlinedButton(
                                            onPressed: () async {
                                              final ctrl = TextEditingController();
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Tolak Pengajuan Agen'),
                                                  content: adminTextField(ctrl, 'Alasan penolakan'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tolak')),
                                                  ],
                                                ),
                                              );
                                              if (ok != true || ctrl.text.trim().isEmpty) return;
                                              final res = await AdminApiService().post('/agents/${a['id']}/reject', body: {'reason': ctrl.text.trim()});
                                              if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                              _loadAll();
                                            },
                                            child: const Text('Tolak', style: TextStyle(color: AdminColors.danger)),
                                          ),
                                        if (appStatus == 'approved') ...[
                                          ElevatedButton(
                                            onPressed: () => _topUpAgentDialog(a),
                                            child: const Text('Top-Up Saldo'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () async {
                                              final res = await AdminApiService().post('/agents/${a['id']}/toggle-active');
                                              if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                              _loadAll();
                                            },
                                            child: Text(a['is_active'] == true ? 'Nonaktifkan' : 'Aktifkan'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 3. Work Orders
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _workOrders.isEmpty
                      ? adminEmptyState('Tidak ada SPK aktif.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _workOrders.length,
                          itemBuilder: (_, idx) {
                            final w = _workOrders[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _assignWorkOrderDialog(w),
                                title: Text(
                                  '${w['order_number'] ?? '-'} • ${w['title'] ?? '-'}',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  '${w['customer']?['name'] ?? '-'} • Teknisi: ${w['technician']?['name'] ?? 'Belum ada'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                ),
                                trailing: adminBadge(
                                  (w['status']?.toString() ?? '-').toUpperCase(),
                                  color: statusColor(w['status']?.toString()),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 4. Support Tickets
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _tickets.isEmpty
                      ? adminEmptyState('Belum ada tiket bantuan.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _tickets.length,
                          itemBuilder: (_, idx) {
                            final t = _tickets[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _openTicketDetail(t),
                                title: Text(
                                  '${t['ticket_number'] ?? '-'} • ${t['subject'] ?? '-'}',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  '${t['customer']?['name'] ?? '-'} • Prioritas: ${t['priority'] ?? '-'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                ),
                                trailing: adminBadge(
                                  (t['status']?.toString() ?? '-').toUpperCase(),
                                  color: statusColor(t['status']?.toString()),
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
}
