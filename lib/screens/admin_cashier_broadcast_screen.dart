import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class AgentPaymentPointScreen extends StatefulWidget {
  const AgentPaymentPointScreen({super.key});

  @override
  State<AgentPaymentPointScreen> createState() => _AgentPaymentPointScreenState();
}

class _AgentPaymentPointScreenState extends State<AgentPaymentPointScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _searching = false;
  List<Map<String, dynamic>> _agents = [];
  int? _selectedAgentId;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/agents', query: {'approval_status': 'approved'});
    if (!mounted) return;
    final list = extractList(res['data']).where((a) => a['is_active'] == true).toList();
    setState(() {
      _agents = list;
      if (_selectedAgentId == null && list.isNotEmpty) {
        _selectedAgentId = int.tryParse(list.first['id'].toString());
      }
      _loading = false;
    });
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().length < 2) return;
    setState(() => _searching = true);
    final res = await AdminApiService().get('/agent-payment/search', query: {'q': _searchCtrl.text.trim()});
    if (!mounted) return;
    setState(() {
      _results = extractList(res['data']);
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loket Bayar Agen (Admin)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (_agents.isEmpty)
                  adminEmptyState('Belum ada Mitra Agen aktif.')
                else ...[
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedAgentId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Loket Mitra Agen',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _agents
                        .map((a) => DropdownMenuItem(
                              value: int.tryParse(a['id'].toString()),
                              child: Text('${a['agent_code']} • ${a['name']} (${AdminConfig.rupiah(a['balance'])})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAgentId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            hintText: 'Cari invoice, nama, atau PPPoE pelanggan',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searching ? null : _search,
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._results.map((inv) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('${inv['customer_name']} • ${inv['formatted_total']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          subtitle: Text('${inv['invoice_number']} • ${inv['package_name']} • Tempo: ${inv['due_date']}'),
                          trailing: ElevatedButton(
                            onPressed: _selectedAgentId == null
                                ? null
                                : () async {
                                    final ok = await confirmAdminDialog(
                                      context,
                                      title: 'Bayar via Saldo Agen',
                                      message: 'Proses ${inv['invoice_number']} (${inv['formatted_total']})?',
                                    );
                                    if (!ok) return;
                                    final res = await AdminApiService().post('/agent-payment/pay', body: {
                                      'agent_id': _selectedAgentId,
                                      'invoice_id': inv['id'],
                                    });
                                    if (!mounted) return;
                                    showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                    _loadAgents();
                                    _search();
                                  },
                            child: const Text('Bayar'),
                          ),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _targetType = 'all';
  bool _sending = false;
  bool _loadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final res = await AdminApiService().get('/onesignal/history');
    if (!mounted) return;
    setState(() {
      _history = extractList(res['data']);
      _loadingHistory = false;
    });
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Judul dan pesan wajib diisi.', isError: true);
      return;
    }
    setState(() => _sending = true);
    final res = await AdminApiService().post('/onesignal/send', body: {
      'title': _titleCtrl.text.trim(),
      'message': _msgCtrl.text.trim(),
      'target_type': _targetType,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
    if (res['success'] == true) {
      _titleCtrl.clear();
      _msgCtrl.clear();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Push OneSignal')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kirim Notifikasi Massal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _targetType,
                      decoration: const InputDecoration(labelText: 'Target Penerima', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua Pelanggan')),
                        DropdownMenuItem(value: 'active_customers', child: Text('Pelanggan Aktif')),
                        DropdownMenuItem(value: 'isolated_customers', child: Text('Pelanggan Terisolir')),
                      ],
                      onChanged: (v) => setState(() => _targetType = v ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    adminTextField(_titleCtrl, 'Judul Notifikasi'),
                    adminTextField(_msgCtrl, 'Isi Pesan Broadcast', maxLines: 3),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Kirim Broadcast Sekarang'),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Riwayat Pengiriman', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              adminEmptyState('Belum ada riwayat broadcast.')
            else
              ..._history.map((h) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(h['title']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      subtitle: Text('${h['message'] ?? '-'}\nTarget: ${h['target_label'] ?? h['target_type'] ?? '-'}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
