import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class PackagesCrudScreen extends StatefulWidget {
  const PackagesCrudScreen({super.key});

  @override
  State<PackagesCrudScreen> createState() => _PackagesCrudScreenState();
}

class _PackagesCrudScreenState extends State<PackagesCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/packages');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final speedCtrl = TextEditingController(text: item?['speed_rate']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: item?['price']?.toString() ?? '');
    final promoPriceCtrl = TextEditingController(text: item?['promo_price']?.toString() ?? '');
    final profileCtrl = TextEditingController(text: item?['mikrotik_profile']?.toString() ?? '');
    final isolirCtrl = TextEditingController(text: item?['mikrotik_isolir_profile']?.toString() ?? 'PROFIL-ISOLIR');
    final descCtrl = TextEditingController(text: item?['description']?.toString() ?? '');
    String type = item?['type']?.toString() ?? 'pppoe';
    bool isActive = item == null ? true : (item['is_active'] == true || item['is_active'] == 1);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(item == null ? 'Tambah Paket Internet' : 'Edit Paket Internet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipe Layanan', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pppoe', child: Text('PPPoE Bulanan')),
                    DropdownMenuItem(value: 'hotspot', child: Text('Hotspot Voucher')),
                  ],
                  onChanged: (v) => setModal(() => type = v ?? 'pppoe'),
                ),
                const SizedBox(height: 12),
                adminTextField(nameCtrl, 'Nama Paket', validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(speedCtrl, 'Kecepatan (cth: 20M/20M)', validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(priceCtrl, 'Harga Normal (Rp)', keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(promoPriceCtrl, 'Harga Promo (Opsional)', keyboardType: TextInputType.number),
                adminTextField(profileCtrl, 'Nama Profil MikroTik', validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                adminTextField(isolirCtrl, 'Profil Isolir MikroTik'),
                adminTextField(descCtrl, 'Deskripsi', maxLines: 2),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (v) => setModal(() => isActive = v),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final body = {
                      'type': type,
                      'name': nameCtrl.text.trim(),
                      'speed_rate': speedCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'promo_price': promoPriceCtrl.text.trim().isEmpty ? null : double.tryParse(promoPriceCtrl.text),
                      'mikrotik_profile': profileCtrl.text.trim(),
                      'mikrotik_isolir_profile': isolirCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'is_active': isActive,
                    };
                    final res = item == null
                        ? await AdminApiService().post('/packages', body: body)
                        : await AdminApiService().put('/packages/${item['id']}', body: body);
                    if (!ctx.mounted) return;
                    if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                    if (res['success'] == true) Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                  child: const Text('Simpan Paket'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Internet'),
        actions: [
          IconButton(
            tooltip: 'Sync ke MikroTik',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              final res = await AdminApiService().post('/packages/sync-mikrotik');
              if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? adminEmptyState('Belum ada paket internet.')
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    itemBuilder: (_, idx) {
                      final p = _items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openForm(item: p),
                          title: Text('${p['name']} (${p['speed_rate']})', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          subtitle: Text('${p['type']?.toString().toUpperCase()} • ${AdminConfig.rupiah(p['price'])} • Profil: ${p['mikrotik_profile']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                            onPressed: () async {
                              final ok = await confirmAdminDialog(context, title: 'Hapus Paket', message: 'Hapus ${p['name']}?', isDanger: true);
                              if (!ok) return;
                              final res = await AdminApiService().delete('/packages/${p['id']}');
                              if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                              _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class PromosCrudScreen extends StatefulWidget {
  const PromosCrudScreen({super.key});

  @override
  State<PromosCrudScreen> createState() => _PromosCrudScreenState();
}

class _PromosCrudScreenState extends State<PromosCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/promos');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final titleCtrl = TextEditingController(text: item?['title']?.toString() ?? '');
    final subCtrl = TextEditingController(text: item?['subtitle']?.toString() ?? '');
    final badgeCtrl = TextEditingController(text: item?['badge_text']?.toString() ?? 'PROMO');
    final imageCtrl = TextEditingController(text: item?['image']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: item?['content']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: item?['promo_price']?.toString() ?? '');
    bool active = item == null ? true : (item['is_active'] == true || item['is_active'] == 1);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(item == null ? 'Tambah Promo' : 'Edit Promo', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              adminTextField(titleCtrl, 'Judul Promo'),
              adminTextField(subCtrl, 'Subjudul'),
              adminTextField(badgeCtrl, 'Teks Badge'),
              adminTextField(imageCtrl, 'URL Gambar Banner'),
              adminTextField(priceCtrl, 'Harga Promo (Rp)', keyboardType: TextInputType.number),
              adminTextField(contentCtrl, 'Konten Detail Promo', maxLines: 3),
              SwitchListTile(title: const Text('Aktif'), value: active, onChanged: (v) => setModal(() => active = v)),
              ElevatedButton(
                onPressed: () async {
                  final body = {
                    'title': titleCtrl.text.trim(),
                    'subtitle': subCtrl.text.trim(),
                    'badge_text': badgeCtrl.text.trim(),
                    'image': imageCtrl.text.trim(),
                    'promo_price': priceCtrl.text.trim().isEmpty ? null : double.tryParse(priceCtrl.text),
                    'content': contentCtrl.text.trim(),
                    'is_active': active,
                  };
                  final res = item == null
                      ? await AdminApiService().post('/promos', body: body)
                      : await AdminApiService().put('/promos/${item['id']}', body: body);
                  if (!ctx.mounted) return;
                  if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                  if (res['success'] == true) Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                child: const Text('Simpan Promo'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Promo & Banner')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? adminEmptyState('Belum ada promo aktif.')
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    itemBuilder: (_, idx) {
                      final p = _items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openForm(item: p),
                          title: Text(p['title']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          subtitle: Text('${p['badge_text'] ?? '-'} • ${p['subtitle'] ?? '-'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                            onPressed: () async {
                              final res = await AdminApiService().delete('/promos/${p['id']}');
                              if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                              _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class RoutersCrudScreen extends StatefulWidget {
  const RoutersCrudScreen({super.key});

  @override
  State<RoutersCrudScreen> createState() => _RoutersCrudScreenState();
}

class _RoutersCrudScreenState extends State<RoutersCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/routers');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final hostCtrl = TextEditingController(text: item?['host']?.toString() ?? '');
    final portCtrl = TextEditingController(text: item?['port']?.toString() ?? '8728');
    final userCtrl = TextEditingController(text: item?['username']?.toString() ?? 'admin');
    final passCtrl = TextEditingController();
    bool active = item == null ? true : (item['is_active'] == true || item['is_active'] == 1);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(item == null ? 'Tambah Router MikroTik' : 'Edit Router', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              adminTextField(nameCtrl, 'Nama Router'),
              adminTextField(hostCtrl, 'IP / Host'),
              adminTextField(portCtrl, 'Port API (default 8728)', keyboardType: TextInputType.number),
              adminTextField(userCtrl, 'Username API'),
              adminTextField(passCtrl, item == null ? 'Password API' : 'Password Baru (Opsional)', obscureText: true),
              SwitchListTile(title: const Text('Aktif'), value: active, onChanged: (v) => setModal(() => active = v)),
              ElevatedButton(
                onPressed: () async {
                  final body = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'host': hostCtrl.text.trim(),
                    'port': int.tryParse(portCtrl.text) ?? 8728,
                    'username': userCtrl.text.trim(),
                    'is_active': active,
                    if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                  };
                  final res = item == null
                      ? await AdminApiService().post('/routers', body: body)
                      : await AdminApiService().put('/routers/${item['id']}', body: body);
                  if (!ctx.mounted) return;
                  if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                  if (res['success'] == true) Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                child: const Text('Simpan Router'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Router MikroTik')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? adminEmptyState('Belum ada router MikroTik.')
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    itemBuilder: (_, idx) {
                      final r = _items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r['name']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                                  adminBadge((r['status']?.toString() ?? 'unknown').toUpperCase(), color: statusColor(r['status']?.toString())),
                                ],
                              ),
                              Text('${r['host']}:${r['port']} • ${r['customers_count'] ?? 0} pelanggan'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final res = await AdminApiService().post('/routers/${r['id']}/test');
                                      if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                      _load();
                                    },
                                    child: const Text('Tes Koneksi'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final res = await AdminApiService().post('/routers/${r['id']}/sync-profiles');
                                      if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                    },
                                    child: const Text('Sync Profil'),
                                  ),
                                  OutlinedButton(onPressed: () => _openForm(item: r), child: const Text('Edit')),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final res = await AdminApiService().delete('/routers/${r['id']}');
                                      if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                      _load();
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: AdminColors.danger)),
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
    );
  }
}

class GenieacsCrudScreen extends StatefulWidget {
  const GenieacsCrudScreen({super.key});

  @override
  State<GenieacsCrudScreen> createState() => _GenieacsCrudScreenState();
}

class _GenieacsCrudScreenState extends State<GenieacsCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/genieacs-servers');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final urlCtrl = TextEditingController(text: item?['base_url']?.toString() ?? '');
    final userCtrl = TextEditingController(text: item?['username']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(item == null ? 'Tambah Server GenieACS' : 'Edit GenieACS', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            adminTextField(nameCtrl, 'Nama Server'),
            adminTextField(urlCtrl, 'Base URL (cth: http://ip:7557)', keyboardType: TextInputType.url),
            adminTextField(userCtrl, 'Username (Opsional)'),
            adminTextField(passCtrl, 'Password (Opsional)', obscureText: true),
            adminTextField(tokenCtrl, 'Auth Token (Opsional)'),
            ElevatedButton(
              onPressed: () async {
                final body = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'base_url': urlCtrl.text.trim(),
                  'username': userCtrl.text.trim(),
                  if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                  if (tokenCtrl.text.isNotEmpty) 'auth_token': tokenCtrl.text,
                };
                final res = item == null
                    ? await AdminApiService().post('/genieacs-servers', body: body)
                    : await AdminApiService().put('/genieacs-servers/${item['id']}', body: body);
                if (!ctx.mounted) return;
                if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                if (res['success'] == true) Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
              child: const Text('Simpan Server'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server GenieACS')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? adminEmptyState('Belum ada server GenieACS.')
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    itemBuilder: (_, idx) {
                      final s = _items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openForm(item: s),
                          title: Text(s['name']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          subtitle: Text(s['base_url']?.toString() ?? '-'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final res = await AdminApiService().post('/genieacs-servers/${s['id']}/test');
                                  if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                },
                                child: const Text('Tes'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                                onPressed: () async {
                                  final res = await AdminApiService().delete('/genieacs-servers/${s['id']}');
                                  if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                  _load();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class OdpsMapScreen extends StatefulWidget {
  const OdpsMapScreen({super.key});

  @override
  State<OdpsMapScreen> createState() => _OdpsMapScreenState();
}

class _OdpsMapScreenState extends State<OdpsMapScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _odps = [];
  List<Map<String, dynamic>> _mapCustomers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Future.wait([
      AdminApiService().get('/odps'),
      AdminApiService().get('/network-map'),
    ]);
    if (!mounted) return;
    setState(() {
      _odps = extractList(res[0]['data']);
      final mapData = res[1]['data'] is Map ? Map<String, dynamic>.from(res[1]['data']) : {};
      _mapCustomers = extractList(mapData['customers']);
      _loading = false;
    });
  }

  Future<void> _openMaps(dynamic lat, dynamic lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: item?['code']?.toString() ?? '');
    final portsCtrl = TextEditingController(text: item?['total_ports']?.toString() ?? '8');
    final splitterCtrl = TextEditingController(text: item?['splitter_ratio']?.toString() ?? '1:8');
    final addrCtrl = TextEditingController(text: item?['address']?.toString() ?? '');
    final latCtrl = TextEditingController(text: item?['latitude']?.toString() ?? '');
    final lngCtrl = TextEditingController(text: item?['longitude']?.toString() ?? '');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(item == null ? 'Tambah ODP' : 'Edit ODP', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            adminTextField(codeCtrl, 'Kode ODP (cth: ODP-01)'),
            adminTextField(nameCtrl, 'Nama ODP'),
            adminTextField(portsCtrl, 'Jumlah Port', keyboardType: TextInputType.number),
            adminTextField(splitterCtrl, 'Rasio Splitter'),
            adminTextField(addrCtrl, 'Alamat'),
            adminTextField(latCtrl, 'Latitude', keyboardType: TextInputType.number),
            adminTextField(lngCtrl, 'Longitude', keyboardType: TextInputType.number),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  'code': codeCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'total_ports': int.tryParse(portsCtrl.text) ?? 8,
                  'splitter_ratio': splitterCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                  'latitude': double.tryParse(latCtrl.text),
                  'longitude': double.tryParse(lngCtrl.text),
                };
                final res = item == null
                    ? await AdminApiService().post('/odps', body: body)
                    : await AdminApiService().put('/odps/${item['id']}', body: body);
                if (!ctx.mounted) return;
                if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                if (res['success'] == true) Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
              child: const Text('Simpan ODP'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ODP & Peta Jaringan')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_location_alt_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Total ODP: ${_odps.length}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          Text('Pelanggan Terpetakan: ${_mapCustomers.length}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_odps.isEmpty)
                    adminEmptyState('Belum ada ODP terdaftar.')
                  else
                    ..._odps.map((o) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _openForm(item: o),
                            title: Text('${o['code']} • ${o['name']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                            subtitle: Text('Port terpakai: ${o['customers_count'] ?? 0}/${o['total_ports']} • ${o['address'] ?? '-'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (o['latitude'] != null && o['longitude'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.map_rounded, color: AdminColors.secondary),
                                    onPressed: () => _openMaps(o['latitude'], o['longitude']),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                                  onPressed: () async {
                                    final res = await AdminApiService().delete('/odps/${o['id']}');
                                    if (context.mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                                    _load();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}
