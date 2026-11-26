import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _statusFilter = '';
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic> _meta = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final query = <String, String>{};
    if (_searchController.text.trim().isNotEmpty) {
      query['search'] = _searchController.text.trim();
    }
    if (_statusFilter.isNotEmpty) {
      query['status'] = _statusFilter;
    }

    final results = await Future.wait([
      AdminApiService().get('/customers', query: query),
      if (_meta.isEmpty) AdminApiService().get('/customers/meta'),
    ]);

    if (!mounted) return;
    final custRes = results[0];
    setState(() {
      _customers = extractList(custRes['data']);
      if (results.length > 1 && results[1]['data'] is Map) {
        _meta = Map<String, dynamic>.from(results[1]['data']);
      }
      _isLoading = false;
    });
  }

  Future<void> _openCustomerForm({Map<String, dynamic>? existing}) async {
    final packages = extractList(_meta['packages']);
    final routers = extractList(_meta['routers']);
    final odps = extractList(_meta['odps']);

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing?['email']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: existing?['address']?.toString() ?? '');
    final pppoeUserCtrl = TextEditingController(text: existing?['pppoe_username']?.toString() ?? '');
    final pppoePassCtrl = TextEditingController(text: existing?['pppoe_password']?.toString() ?? '');
    final passCtrl = TextEditingController();

    int? packageId = int.tryParse(existing?['package_id']?.toString() ?? '');
    int? routerId = int.tryParse(existing?['router_id']?.toString() ?? '');
    int? odpId = int.tryParse(existing?['odp_id']?.toString() ?? '');
    String status = existing?['status']?.toString() ?? 'active';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  existing == null ? 'Tambah Pelanggan Baru' : 'Edit Pelanggan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                adminTextField(nameCtrl, 'Nama Pelanggan', validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(phoneCtrl, 'No. WhatsApp', keyboardType: TextInputType.phone, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(emailCtrl, 'Email (Opsional)', keyboardType: TextInputType.emailAddress),
                adminTextField(addressCtrl, 'Alamat Lengkap', maxLines: 2, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                if (packages.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: packageId,
                    decoration: const InputDecoration(labelText: 'Paket Internet', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('- Pilih Paket -')),
                      ...packages.map((p) => DropdownMenuItem(
                            value: int.tryParse(p['id'].toString()),
                            child: Text('${p['name']} (${AdminConfig.rupiah(p['price'])})'),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => packageId = v),
                  ),
                const SizedBox(height: 12),
                if (routers.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: routerId,
                    decoration: const InputDecoration(labelText: 'Router MikroTik', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('- Pilih Router -')),
                      ...routers.map((r) => DropdownMenuItem(
                            value: int.tryParse(r['id'].toString()),
                            child: Text(r['name']?.toString() ?? '-'),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => routerId = v),
                  ),
                const SizedBox(height: 12),
                if (odps.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: odpId,
                    decoration: const InputDecoration(labelText: 'ODP (Opsional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('- Pilih ODP -')),
                      ...odps.map((o) => DropdownMenuItem(
                            value: int.tryParse(o['id'].toString()),
                            child: Text('${o['code']} • ${o['name']}'),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => odpId = v),
                  ),
                const SizedBox(height: 12),
                adminTextField(pppoeUserCtrl, 'Username PPPoE'),
                adminTextField(pppoePassCtrl, 'Password PPPoE'),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status Layanan', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'isolated', child: Text('Isolated')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? 'active'),
                ),
                const SizedBox(height: 12),
                adminTextField(
                  passCtrl,
                  existing == null ? 'Password Akun Portal (default 123456)' : 'Reset Password Portal (Opsional)',
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final body = <String, dynamic>{
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'package_id': packageId,
                      'router_id': routerId,
                      'odp_id': odpId,
                      'pppoe_username': pppoeUserCtrl.text.trim(),
                      'pppoe_password': pppoePassCtrl.text.trim(),
                      'status': status,
                      if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text.trim(),
                    };

                    final res = existing == null
                        ? await AdminApiService().post('/customers', body: body)
                        : await AdminApiService().put('/customers/${existing['id']}', body: body);

                    if (!ctx.mounted) return;
                    if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
                    if (res['success'] == true) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simpan Pelanggan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) _loadAll();
  }

  Future<void> _openCustomerDetail(Map<String, dynamic> cust) async {
    final id = int.tryParse(cust['id'].toString()) ?? 0;
    Map<String, dynamic>? live;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cust['name']?.toString() ?? '-',
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'ID: ${cust['customer_number'] ?? '-'} • ${cust['phone'] ?? '-'}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  adminBadge(
                    (cust['status']?.toString() ?? '-').toUpperCase(),
                    color: statusColor(cust['status']?.toString()),
                  ),
                ],
              ),
              const Divider(height: 22),
              adminInfoRow('Paket', cust['package']?['name']?.toString() ?? '-'),
              adminInfoRow('Router', cust['router']?['name']?.toString() ?? '-'),
              adminInfoRow('PPPoE User', cust['pppoe_username']?.toString() ?? '-'),
              adminInfoRow('ODP', cust['odp']?['code']?.toString() ?? '-'),
              adminInfoRow('Alamat', cust['address']?.toString() ?? '-'),
              if (live != null) ...[
                const Divider(height: 22),
                Text('Status Live Router & ONT', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                adminInfoRow('Online PPPoE', live?['session']?['online'] == true ? 'ONLINE' : 'OFFLINE'),
                adminInfoRow('IP Session', live?['session']?['address']?.toString() ?? '-'),
                adminInfoRow('RX Optical', live?['ont']?['rx_power']?.toString() ?? '-'),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await AdminApiService().get('/customers/$id/live-status');
                      if (res['success'] == true && res['data'] is Map) {
                        setSheetState(() => live = Map<String, dynamic>.from(res['data']));
                      } else if (mounted) {
                        showAdminSnackBar(context, res['message']?.toString() ?? 'Gagal cek live', isError: true);
                      }
                    },
                    icon: const Icon(Icons.network_check_rounded, size: 16),
                    label: const Text('Cek Live'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await AdminApiService().post('/customers/$id/toggle-status');
                      if (!ctx.mounted) return;
                      if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
                      Navigator.pop(ctx);
                      _loadAll();
                    },
                    icon: Icon(cust['status'] == 'isolated' ? Icons.lock_open_rounded : Icons.block_rounded, size: 16),
                    label: Text(cust['status'] == 'isolated' ? 'Buka Isolir' : 'Isolir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cust['status'] == 'isolated' ? AdminColors.success : AdminColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await AdminApiService().post('/customers/$id/generate-invoice');
                      if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('Buat Tagihan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await AdminApiService().post('/customers/$id/ont-reboot');
                      if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reboot ONT'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openCustomerForm(existing: cust);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirmAdminDialog(
                        ctx,
                        title: 'Hapus Pelanggan',
                        message: 'Yakin menghapus ${cust['name']} beserta secret MikroTik-nya?',
                        isDanger: true,
                      );
                      if (!ok) return;
                      final res = await AdminApiService().delete('/customers/$id');
                      if (!ctx.mounted) return;
                      if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? 'Dihapus', isError: res['success'] != true);
                      Navigator.pop(ctx);
                      _loadAll();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AdminColors.danger),
                    label: const Text('Hapus', style: TextStyle(color: AdminColors.danger)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerForm(),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadAll(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, ID pelanggan, PPPoE, atau HP',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _loadAll,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AdminColors.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('', 'Semua'),
                      _filterChip('active', 'Aktif'),
                      _filterChip('isolated', 'Isolir'),
                      _filterChip('pending', 'Pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? adminEmptyState('Tidak ada pelanggan ditemukan.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _openCustomerDetail(c),
                                title: Text(
                                  c['name']?.toString() ?? '-',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  '${c['customer_number'] ?? '-'} • ${c['package']?['name'] ?? '-'} • ${c['pppoe_username'] ?? '-'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                ),
                                trailing: adminBadge(
                                  (c['status']?.toString() ?? '-').toUpperCase(),
                                  color: statusColor(c['status']?.toString()),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (s) {
          if (s) {
            setState(() => _statusFilter = value);
            _loadAll();
          }
        },
        selectedColor: AdminColors.primaryAccent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AdminColors.textHeadline,
        ),
      ),
    );
  }
}
