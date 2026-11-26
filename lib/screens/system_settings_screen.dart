import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_api_service.dart';
import 'package:isp_admin_app/widgets/admin_ui.dart';

class StaffCrudScreen extends StatefulWidget {
  const StaffCrudScreen({super.key});

  @override
  State<StaffCrudScreen> createState() => _StaffCrudScreenState();
}

class _StaffCrudScreenState extends State<StaffCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/staff');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: item?['email']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: item?['phone']?.toString() ?? '');
    final areaCtrl = TextEditingController(text: item?['work_area']?.toString() ?? '');
    final passCtrl = TextEditingController();
    String role = item?['role']?.toString() ?? 'technician';
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
              Text(item == null ? 'Tambah Admin / Teknisi' : 'Edit Akun Staf', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role Akun', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'technician', child: Text('Teknisi Lapangan')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                ],
                onChanged: (v) => setModal(() => role = v ?? 'technician'),
              ),
              const SizedBox(height: 12),
              adminTextField(nameCtrl, 'Nama Lengkap'),
              adminTextField(emailCtrl, 'Email Login', keyboardType: TextInputType.emailAddress),
              adminTextField(phoneCtrl, 'No. WhatsApp', keyboardType: TextInputType.phone),
              adminTextField(areaCtrl, 'Area Kerja (Opsional)'),
              adminTextField(passCtrl, item == null ? 'Password' : 'Password Baru (Opsional)', obscureText: true),
              SwitchListTile(title: const Text('Aktif'), value: active, onChanged: (v) => setModal(() => active = v)),
              ElevatedButton(
                onPressed: () async {
                  final body = <String, dynamic>{
                    'role': role,
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'work_area': areaCtrl.text.trim(),
                    'is_active': active,
                    if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                  };
                  final res = item == null
                      ? await AdminApiService().post('/staff', body: body)
                      : await AdminApiService().put('/staff/${item['id']}', body: body);
                  if (!ctx.mounted) return;
                  if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                  if (res['success'] == true) Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                child: const Text('Simpan Akun'),
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
      appBar: AppBar(title: const Text('Admin & Teknisi')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.person_add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _items.length,
                itemBuilder: (_, idx) {
                  final u = _items[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _openForm(item: u),
                      title: Text(u['name']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      subtitle: Text('${u['email']} • ${u['phone'] ?? '-'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          adminBadge((u['role']?.toString() ?? '').toUpperCase()),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                            onPressed: () async {
                              final res = await AdminApiService().delete('/staff/${u['id']}');
                              if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
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

class SitePagesCrudScreen extends StatefulWidget {
  const SitePagesCrudScreen({super.key});

  @override
  State<SitePagesCrudScreen> createState() => _SitePagesCrudScreenState();
}

class _SitePagesCrudScreenState extends State<SitePagesCrudScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/pages');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final titleCtrl = TextEditingController(text: item?['title']?.toString() ?? '');
    final slugCtrl = TextEditingController(text: item?['slug']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: item?['content']?.toString() ?? '');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(item == null ? 'Tambah Halaman' : 'Edit Halaman', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            adminTextField(titleCtrl, 'Judul Halaman'),
            adminTextField(slugCtrl, 'Slug URL (cth: privacy-policy)'),
            adminTextField(contentCtrl, 'Isi Konten Halaman', maxLines: 6),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  'title': titleCtrl.text.trim(),
                  'slug': slugCtrl.text.trim(),
                  'content': contentCtrl.text.trim(),
                };
                final res = item == null
                    ? await AdminApiService().post('/pages', body: body)
                    : await AdminApiService().put('/pages/${item['id']}', body: body);
                if (!ctx.mounted) return;
                if (mounted) showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
                if (res['success'] == true) Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
              child: const Text('Simpan Halaman'),
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
      appBar: AppBar(title: const Text('Halaman Informasi (Site Pages)')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                      subtitle: Text('Slug: ${p['slug']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger),
                        onPressed: () async {
                          final res = await AdminApiService().delete('/pages/${p['id']}');
                          if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
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

class PaymentGatewaysScreen extends StatefulWidget {
  const PaymentGatewaysScreen({super.key});

  @override
  State<PaymentGatewaysScreen> createState() => _PaymentGatewaysScreenState();
}

class _PaymentGatewaysScreenState extends State<PaymentGatewaysScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/payment-gateways');
    if (!mounted) return;
    setState(() {
      _items = extractList(res['data']);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Gateways')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _items.length,
                itemBuilder: (_, idx) {
                  final g = _items[idx];
                  final active = g['is_active'] == true || g['is_active'] == 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: SwitchListTile(
                      title: Text(g['name']?.toString() ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      subtitle: Text('${g['code']} • Fee: ${g['fee_flat'] ?? 0} + ${g['fee_percent'] ?? 0}%'),
                      value: active,
                      onChanged: (v) async {
                        final res = await AdminApiService().put('/payment-gateways/${g['id']}', body: {'is_active': v});
                        if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                        _load();
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  bool _saving = false;
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, bool> _toggles = {};

  static const _textKeys = [
    'company_name', 'company_phone', 'company_email', 'company_address',
    'office_lat', 'office_lng', 'default_zoom', 'google_maps_api_key',
    'app_api_base_url', 'app_api_key', 'onesignal_app_id', 'onesignal_rest_api_key', 'fcm_server_key',
    'whatsapp_gateway_url', 'whatsapp_api_key', 'whatsapp_sender_number',
    'telegram_bot_token', 'telegram_admin_chat_id',
    'payment_gateway_provider', 'static_qris_string', 'default_isolir_profile',
    'pppoe_local_address', 'pppoe_pool_range', 'pppoe_dns_servers',
  ];

  static const _boolKeys = [
    'onesignal_enabled', 'onesignal_notify_invoice', 'onesignal_notify_payment', 'onesignal_notify_ticket',
    'whatsapp_notify_invoice', 'whatsapp_notify_reminder', 'whatsapp_notify_receipt', 'whatsapp_notify_isolir', 'whatsapp_notify_fup',
    'telegram_bot_enabled', 'telegram_notify_payment', 'telegram_notify_invoice', 'telegram_notify_ticket', 'telegram_notify_router', 'telegram_notify_fup',
    'payment_auto_activate', 'payment_auto_receipt', 'payment_auto_telegram', 'use_unique_code',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    for (final k in _textKeys) {
      _ctrls[k] = TextEditingController();
    }
    for (final k in _boolKeys) {
      _toggles[k] = true;
    }
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/settings');
    if (!mounted) return;
    if (res['success'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data']);
      for (final k in _textKeys) {
        _ctrls[k]?.text = data[k]?.toString() ?? '';
      }
      for (final k in _boolKeys) {
        _toggles[k] = data[k]?.toString() == '1';
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{};
    for (final k in _textKeys) {
      payload[k] = _ctrls[k]?.text.trim() ?? '';
    }
    for (final k in _boolKeys) {
      payload[k] = _toggles[k] ?? false;
    }

    final res = await AdminApiService().post('/settings', body: payload);
    if (!mounted) return;
    setState(() => _saving = false);
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
  }

  Widget _switchTile(String key, String label) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
      value: _toggles[key] ?? false,
      onChanged: (v) => setState(() => _toggles[key] = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem ISP'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveAll,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AdminColors.primary,
          tabs: const [
            Tab(text: 'Profil & Peta'),
            Tab(text: 'Mobile & OneSignal'),
            Tab(text: 'WhatsApp'),
            Tab(text: 'Telegram'),
            Tab(text: 'QRIS & Jaringan'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    adminTextField(_ctrls['company_name']!, 'Nama Perusahaan ISP'),
                    adminTextField(_ctrls['company_phone']!, 'No. WhatsApp CS'),
                    adminTextField(_ctrls['company_email']!, 'Email CS'),
                    adminTextField(_ctrls['company_address']!, 'Alamat Kantor', maxLines: 2),
                    adminTextField(_ctrls['office_lat']!, 'Latitude Kantor'),
                    adminTextField(_ctrls['office_lng']!, 'Longitude Kantor'),
                    adminTextField(_ctrls['default_zoom']!, 'Default Zoom Peta'),
                    adminTextField(_ctrls['google_maps_api_key']!, 'Google Maps API Key'),
                    ElevatedButton(onPressed: _saving ? null : _saveAll, child: const Text('Simpan Pengaturan')),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    adminTextField(_ctrls['app_api_base_url']!, 'App API Base URL'),
                    adminTextField(_ctrls['app_api_key']!, 'App Secret API Key'),
                    _switchTile('onesignal_enabled', 'Aktifkan OneSignal Push'),
                    adminTextField(_ctrls['onesignal_app_id']!, 'OneSignal App ID'),
                    adminTextField(_ctrls['onesignal_rest_api_key']!, 'OneSignal REST API Key'),
                    adminTextField(_ctrls['fcm_server_key']!, 'FCM Server Key (Opsional)'),
                    _switchTile('onesignal_notify_invoice', 'Notif OneSignal Tagihan Baru'),
                    _switchTile('onesignal_notify_payment', 'Notif OneSignal Pembayaran Lunas'),
                    _switchTile('onesignal_notify_ticket', 'Notif OneSignal Balasan Tiket'),
                    ElevatedButton(onPressed: _saving ? null : _saveAll, child: const Text('Simpan Pengaturan')),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    adminTextField(_ctrls['whatsapp_gateway_url']!, 'Gateway URL (Fonnte/Lainnya)'),
                    adminTextField(_ctrls['whatsapp_api_key']!, 'WhatsApp API Token'),
                    adminTextField(_ctrls['whatsapp_sender_number']!, 'Nomor Pengirim'),
                    _switchTile('whatsapp_notify_invoice', 'Kirim WA Tagihan Baru'),
                    _switchTile('whatsapp_notify_reminder', 'Kirim WA Pengingat Jatuh Tempo'),
                    _switchTile('whatsapp_notify_receipt', 'Kirim WA Struk Pembayaran'),
                    _switchTile('whatsapp_notify_isolir', 'Kirim WA Notif Isolir'),
                    _switchTile('whatsapp_notify_fup', 'Kirim WA Notif FUP'),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: _saving ? null : _saveAll, child: const Text('Simpan'))),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final phoneCtrl = TextEditingController(text: _ctrls['company_phone']!.text);
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tes Kirim WhatsApp'),
                                content: adminTextField(phoneCtrl, 'Nomor Tujuan'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            final res = await AdminApiService().post('/settings/test-whatsapp', body: {'phone': phoneCtrl.text.trim()});
                            if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                          },
                          child: const Text('Tes WA'),
                        ),
                      ],
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _switchTile('telegram_bot_enabled', 'Aktifkan Bot Telegram'),
                    adminTextField(_ctrls['telegram_bot_token']!, 'Bot Token'),
                    adminTextField(_ctrls['telegram_admin_chat_id']!, 'Admin Chat ID'),
                    _switchTile('telegram_notify_payment', 'Notif Pembayaran'),
                    _switchTile('telegram_notify_invoice', 'Notif Invoice'),
                    _switchTile('telegram_notify_ticket', 'Notif Tiket Gangguan'),
                    _switchTile('telegram_notify_router', 'Notif Status Router'),
                    _switchTile('telegram_notify_fup', 'Notif FUP Pelanggan'),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: _saving ? null : _saveAll, child: const Text('Simpan'))),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final res = await AdminApiService().post('/settings/test-telegram');
                            if (mounted) showAdminSnackBar(this.context, res['message']?.toString() ?? '', isError: res['success'] != true);
                          },
                          child: const Text('Tes Telegram'),
                        ),
                      ],
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    adminTextField(_ctrls['payment_gateway_provider']!, 'Provider Utama (cth: qris_manual)'),
                    _switchTile('payment_auto_activate', 'Auto Aktivasi Saat Lunas'),
                    _switchTile('payment_auto_receipt', 'Kirim Struk Otomatis'),
                    _switchTile('payment_auto_telegram', 'Notif Telegram Pembayaran'),
                    _switchTile('use_unique_code', 'Gunakan Kode Unik Nominal'),
                    adminTextField(_ctrls['static_qris_string']!, 'Payload String QRIS Statis', maxLines: 2),
                    adminTextField(_ctrls['default_isolir_profile']!, 'Profil Isolir Default MikroTik'),
                    adminTextField(_ctrls['pppoe_local_address']!, 'PPPoE Local Address'),
                    adminTextField(_ctrls['pppoe_pool_range']!, 'PPPoE IP Pool Range'),
                    adminTextField(_ctrls['pppoe_dns_servers']!, 'PPPoE DNS Servers'),
                    ElevatedButton(onPressed: _saving ? null : _saveAll, child: const Text('Simpan Pengaturan')),
                  ],
                ),
              ],
            ),
    );
  }
}

class SystemUpdateScreen extends StatefulWidget {
  const SystemUpdateScreen({super.key});

  @override
  State<SystemUpdateScreen> createState() => _SystemUpdateScreenState();
}

class _SystemUpdateScreenState extends State<SystemUpdateScreen> {
  bool _loading = true;
  bool _updating = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load(force: false);
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    final res = await AdminApiService().get('/system-update', query: {'force': force ? '1' : '0'});
    if (!mounted) return;
    setState(() {
      _data = res['data'] is Map ? Map<String, dynamic>.from(res['data']) : {};
      _loading = false;
    });
  }

  Future<void> _runUpdate() async {
    final ok = await confirmAdminDialog(
      context,
      title: 'Jalankan System Update',
      message: 'Server akan menarik kode terbaru dari GitHub dan menjalankan migrasi database. Lanjutkan?',
    );
    if (!ok || !mounted) return;
    setState(() => _updating = true);
    final res = await AdminApiService().post('/system-update/run', body: {'run_migrate': true});
    if (!mounted) return;
    setState(() => _updating = false);
    showAdminSnackBar(context, res['message']?.toString() ?? '', isError: res['success'] != true);
    _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final current = _data['current'] is Map ? Map<String, dynamic>.from(_data['current']) : {};
    final check = _data['check'] is Map ? Map<String, dynamic>.from(_data['check']) : {};

    return Scaffold(
      appBar: AppBar(title: const Text('System Update Server')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Versi Saat Ini', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                        const Divider(height: 18),
                        adminInfoRow('Branch', current['branch']?.toString() ?? '-'),
                        adminInfoRow('Commit', current['short_hash']?.toString() ?? current['commit']?.toString() ?? '-'),
                        adminInfoRow('Status Update', check['has_update'] == true ? 'Tersedia Update Baru' : 'Sudah Terbaru'),
                        if (check['message'] != null) adminInfoRow('Info', check['message'].toString()),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _load(force: true),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Cek Update'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _updating ? null : _runUpdate,
                                icon: const Icon(Icons.system_update_alt_rounded),
                                label: Text(_updating ? 'Updating...' : 'Update Sekarang'),
                                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryAccent, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
