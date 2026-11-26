import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // PPPoE
  bool _loadingPppoe = true;
  List<Map<String, dynamic>> _pppoeSecrets = [];
  List<Map<String, dynamic>> _pppoeProfiles = [];
  Map<String, dynamic>? _activeRouter;

  // Hotspot
  bool _loadingHotspot = true;
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _hotspotProfiles = [];
  Map<String, dynamic> _hotspotStats = {};

  // Voucher Orders
  bool _loadingOrders = true;
  List<Map<String, dynamic>> _voucherOrders = [];

  // GenieACS
  bool _loadingGenieacs = true;
  List<Map<String, dynamic>> _genieacsServers = [];
  int? _selectedGenieacsId;
  List<Map<String, dynamic>> _ontDevices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPppoe();
    _loadHotspot();
    _loadVoucherOrders();
    _loadGenieacsServers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPppoe() async {
    setState(() => _loadingPppoe = true);
    final res = await AdminApiService().get('/pppoe');
    if (!mounted) return;
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
    setState(() {
      _activeRouter = data['router'] is Map ? Map<String, dynamic>.from(data['router']) : null;
      _pppoeSecrets = extractList(data['secrets']);
      _pppoeProfiles = extractList(data['profiles']);
      _loadingPppoe = false;
    });
  }

  Future<void> _loadHotspot() async {
    setState(() => _loadingHotspot = true);
    final res = await AdminApiService().get('/hotspot');
    if (!mounted) return;
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
    setState(() {
      _hotspotStats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats']) : {};
      _vouchers = extractList(data['vouchers']);
      _hotspotProfiles = extractList(data['profiles']);
      _loadingHotspot = false;
    });
  }

  Future<void> _loadVoucherOrders() async {
    setState(() => _loadingOrders = true);
    final res = await AdminApiService().get('/voucher-orders');
    if (!mounted) return;
    setState(() {
      _voucherOrders = extractList(res['data']);
      _loadingOrders = false;
    });
  }

  Future<void> _loadGenieacsServers() async {
    setState(() => _loadingGenieacs = true);
    final res = await AdminApiService().get('/genieacs-servers');
    if (!mounted) return;
    final servers = extractList(res['data']);
    setState(() {
      _genieacsServers = servers;
      if (_selectedGenieacsId == null && servers.isNotEmpty) {
        _selectedGenieacsId = int.tryParse(servers.first['id'].toString());
      }
      _loadingGenieacs = false;
    });
    if (_selectedGenieacsId != null) {
      await _loadOntDevices();
    }
  }

  Future<void> _loadOntDevices() async {
    if (_selectedGenieacsId == null) return;
    setState(() => _loadingGenieacs = true);
    final res = await AdminApiService().get('/genieacs-servers/$_selectedGenieacsId/devices');
    if (!mounted) return;
    setState(() {
      _ontDevices = extractList(res['data']);
      _loadingGenieacs = false;
    });
  }

  Future<void> _createPppoeSecretModal() async {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String profile = _pppoeProfiles.isNotEmpty ? (_pppoeProfiles.first['name']?.toString() ?? 'default') : 'default';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Buat Secret PPPoE'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              adminTextField(nameCtrl, 'Username PPPoE'),
              adminTextField(passCtrl, 'Password PPPoE'),
              DropdownButtonFormField<String>(
                initialValue: profile,
                decoration: const InputDecoration(labelText: 'Profil', border: OutlineInputBorder()),
                items: (_pppoeProfiles.isNotEmpty
                        ? _pppoeProfiles.map((p) => p['name']?.toString() ?? 'default').toSet().toList()
                        : ['default'])
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setDlgState(() => profile = v ?? 'default'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final res = await AdminApiService().post('/pppoe/secret', body: {
      'name': nameCtrl.text.trim(),
      'password': passCtrl.text.trim(),
      'profile': profile,
      'router_id': _activeRouter?['id'],
    });
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    _loadPppoe();
  }

  Future<void> _generateHotspotBatchModal() async {
    final qtyCtrl = TextEditingController(text: '10');
    final priceCtrl = TextEditingController(text: '5000');
    final validityCtrl = TextEditingController(text: '1d');
    final prefixCtrl = TextEditingController(text: 'VC-');
    String profile = _hotspotProfiles.isNotEmpty
        ? (_hotspotProfiles.first['name']?.toString() ?? 'default')
        : 'default';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Generate Voucher Hotspot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: profile,
                  decoration: const InputDecoration(labelText: 'Profil Hotspot', border: OutlineInputBorder()),
                  items: (_hotspotProfiles.isNotEmpty
                          ? _hotspotProfiles.map((p) => p['name']?.toString() ?? 'default').toSet().toList()
                          : ['default'])
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => profile = v ?? 'default'),
                ),
                const SizedBox(height: 10),
                adminTextField(qtyCtrl, 'Jumlah Voucher', keyboardType: TextInputType.number),
                adminTextField(priceCtrl, 'Harga Satuan (Rp)', keyboardType: TextInputType.number),
                adminTextField(validityCtrl, 'Masa Aktif (cth: 1d, 6h)'),
                adminTextField(prefixCtrl, 'Prefix Kode'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final res = await AdminApiService().post('/hotspot/generate', body: {
      'profile': profile,
      'qty': int.tryParse(qtyCtrl.text.trim()) ?? 10,
      'price': double.tryParse(priceCtrl.text.trim()) ?? 5000,
      'validity': validityCtrl.text.trim(),
      'prefix': prefixCtrl.text.trim(),
    });
    if (!mounted) return;
    showAdminSnackBar(context, res['message']?.toString() ?? 'Selesai', isError: res['success'] != true);
    _loadHotspot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jaringan & MikroTik'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AdminColors.primary,
          tabs: const [
            Tab(text: 'PPPoE'),
            Tab(text: 'Hotspot'),
            Tab(text: 'Order Voucher'),
            Tab(text: 'ONT GenieACS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. PPPoE
          Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: _createPppoeSecretModal,
              child: const Icon(Icons.add_rounded),
            ),
            body: RefreshIndicator(
              onRefresh: _loadPppoe,
              child: _loadingPppoe
                  ? const Center(child: CircularProgressIndicator())
                  : _pppoeSecrets.isEmpty
                      ? adminEmptyState('Tidak ada secret PPPoE atau router offline.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _pppoeSecrets.length,
                          itemBuilder: (context, idx) {
                            final s = _pppoeSecrets[idx];
                            final username = s['name']?.toString() ?? '';
                            final profile = s['profile']?.toString() ?? 'default';
                            final isOnline = s['is_online'] == true;
                            final isIsolir = profile.toLowerCase().contains('isolir');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(username, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                                subtitle: Text(
                                  'Profil: $profile • ${s['customer']?['name'] ?? 'Non-mapping'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                ),
                                leading: adminBadge(
                                  isOnline ? 'ON' : 'OFF',
                                  color: isOnline ? AdminColors.success : AdminColors.textMuted,
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (act) async {
                                    if (act == 'isolir') {
                                      final res = await AdminApiService().post('/pppoe/toggle-isolir', body: {
                                        'username': username,
                                        'current_profile': profile,
                                        'router_id': _activeRouter?['id'],
                                      });
                                      if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                      _loadPppoe();
                                    } else if (act == 'kick') {
                                      final res = await AdminApiService().post('/pppoe/kick', body: {
                                        'username': username,
                                        'router_id': _activeRouter?['id'],
                                      });
                                      if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                      _loadPppoe();
                                    } else if (act == 'fup') {
                                      final res = await AdminApiService().post('/pppoe/reset-fup', body: {'username': username});
                                      if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'isolir',
                                      child: Text(isIsolir ? 'Buka Isolir' : 'Isolir Secret'),
                                    ),
                                    const PopupMenuItem(value: 'kick', child: Text('Kick Sesi')),
                                    const PopupMenuItem(value: 'fup', child: Text('Reset FUP')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),

          // 2. Hotspot
          Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: _generateHotspotBatchModal,
              child: const Icon(Icons.qr_code_2_rounded),
            ),
            body: RefreshIndicator(
              onRefresh: _loadHotspot,
              child: _loadingHotspot
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniStat('Total', '${_hotspotStats['total'] ?? 0}'),
                                _miniStat('Belum Pakai', '${_hotspotStats['unused'] ?? 0}'),
                                _miniStat('Terpakai', '${_hotspotStats['used'] ?? 0}'),
                                _miniStat('Online', '${_hotspotStats['online_devices'] ?? 0}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_vouchers.isEmpty)
                          adminEmptyState('Belum ada voucher hotspot.')
                        else
                          ..._vouchers.map(
                            (v) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(v['code']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                                subtitle: Text('${v['profile']} • ${AdminConfig.rupiah(v['price'])} • ${v['validity']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    adminBadge(
                                      (v['status']?.toString() ?? '-').toUpperCase(),
                                      color: statusColor(v['status']?.toString()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                                      onPressed: () async {
                                        final res = await AdminApiService().delete('/hotspot/voucher/${v['id']}');
                                        if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                        _loadHotspot();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // 3. Voucher Orders
          RefreshIndicator(
            onRefresh: _loadVoucherOrders,
            child: _loadingOrders
                ? const Center(child: CircularProgressIndicator())
                : _voucherOrders.isEmpty
                    ? adminEmptyState('Belum ada order voucher online.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _voucherOrders.length,
                        itemBuilder: (context, idx) {
                          final o = _voucherOrders[idx];
                          final isPending = o['status'] == 'pending';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                '${o['order_number'] ?? '-'} • ${AdminConfig.rupiah(o['total_amount'])}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                '${o['buyer_name'] ?? 'Tamu'} (${o['buyer_phone'] ?? '-'}) • ${o['package']?['name'] ?? '-'}',
                              ),
                              trailing: isPending
                                  ? ElevatedButton(
                                      onPressed: () async {
                                        final res = await AdminApiService().post('/voucher-orders/${o['order_number']}/approve');
                                        if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                        _loadVoucherOrders();
                                      },
                                      child: const Text('ACC'),
                                    )
                                  : adminBadge(
                                      (o['status']?.toString() ?? '-').toUpperCase(),
                                      color: statusColor(o['status']?.toString()),
                                    ),
                            ),
                          );
                        },
                      ),
          ),

          // 4. GenieACS ONT Devices
          RefreshIndicator(
            onRefresh: _loadOntDevices,
            child: _loadingGenieacs
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      if (_genieacsServers.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedGenieacsId,
                          decoration: const InputDecoration(
                            labelText: 'Server GenieACS',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _genieacsServers
                              .map((s) => DropdownMenuItem(
                                    value: int.tryParse(s['id'].toString()),
                                    child: Text(s['name']?.toString() ?? '-'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedGenieacsId = v);
                            _loadOntDevices();
                          },
                        ),
                      const SizedBox(height: 12),
                      if (_ontDevices.isEmpty)
                        adminEmptyState('Belum ada perangkat ONT ditemukan di GenieACS.')
                      else
                        ..._ontDevices.map((d) {
                          final devId = d['_id']?.toString() ?? '';
                          final info = d['_deviceId'] is Map ? d['_deviceId'] as Map : {};
                          final sn = info['_SerialNumber']?.toString() ?? devId;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(sn, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                '${info['_Manufacturer'] ?? '-'} ${info['_ProductClass'] ?? ''}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (_selectedGenieacsId == null) return;
                                  final res = await AdminApiService().post(
                                    '/genieacs-servers/$_selectedGenieacsId/device-action',
                                    body: {'device_id': devId, 'action': action},
                                  );
                                  if (mounted) {
                                    showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
                                  PopupMenuItem(value: 'reboot', child: Text('Reboot ONT')),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted)),
      ],
    );
  }
}
