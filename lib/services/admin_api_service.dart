import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isp_admin_app/config/app_config.dart';
import 'package:isp_admin_app/services/admin_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  static final AdminApiService _instance = AdminApiService._internal();
  factory AdminApiService() => _instance;
  AdminApiService._internal();

  static const String _tokenKey = 'admin_auth_token';
  static const String _userKey = 'admin_user_data';
  static const String _baseUrlKey = 'admin_base_url';
  static const String _oneSignalAppIdKey = 'admin_onesignal_app_id';

  String? _authToken;
  Map<String, dynamic>? _currentUser;
  String? _lastSyncedOneSignalId;

  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get token => _authToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey)?.trim();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      AdminConfig.baseUrl = savedUrl;
    }

    final cachedOneSignalAppId = prefs.getString(_oneSignalAppIdKey)?.trim() ?? '';
    if (cachedOneSignalAppId.isNotEmpty) {
      AdminConfig.oneSignalAppId = cachedOneSignalAppId;
    }

    _authToken = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(rawUser));
        if (decoded['role']?.toString().toLowerCase() == 'admin') {
          _currentUser = decoded;
        } else {
          _authToken = null;
        }
      } catch (_) {}
    }

    AdminNotificationService().setSubscriptionObserver((subscriptionId) {
      syncOneSignalDevice(subscriptionId).ignore();
    });

    authState.value = isAuthenticated && _currentUser != null;

    if (AdminConfig.oneSignalAppId.isNotEmpty) {
      await AdminNotificationService().init(appId: AdminConfig.oneSignalAppId);
      if (isAuthenticated && _currentUser != null) {
        await syncOneSignalDevice();
      }
    }
  }

  Future<void> syncOneSignalDevice([String? subscriptionIdOverride]) async {
    if (!isAuthenticated || _currentUser == null) return;

    final userId = int.tryParse(_currentUser?['id']?.toString() ?? '');
    if (userId != null) {
      await AdminNotificationService().setAdminExternalId(userId);
    }

    final subId = (subscriptionIdOverride ?? AdminNotificationService().currentSubscriptionId)?.trim() ?? '';
    if (subId.isEmpty || subId == _lastSyncedOneSignalId) return;

    try {
      final response = await http
          .post(
            Uri.parse(AdminConfig.oneSignalIdUrl),
            headers: AdminConfig.getHeaders(token: _authToken),
            body: jsonEncode({'onesignal_id': subId}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _lastSyncedOneSignalId = subId;
      }
    } catch (_) {}
  }

  Future<void> applyAppConfig(Map<String, dynamic>? appConfig) async {
    if (appConfig == null) return;
    final remoteId = appConfig['onesignal_app_id']?.toString().trim() ?? '';
    if (remoteId.isEmpty) return;

    AdminConfig.oneSignalAppId = remoteId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_oneSignalAppIdKey, remoteId);

    AdminNotificationService().setSubscriptionObserver((subscriptionId) {
      syncOneSignalDevice(subscriptionId).ignore();
    });
    await AdminNotificationService().init(appId: remoteId);
    if (isAuthenticated && _currentUser != null) {
      await syncOneSignalDevice();
    }
  }

  Future<void> fetchAndSyncAppConfig() async {
    try {
      final response = await http
          .get(
            Uri.parse(AdminConfig.publicAppConfigUrl),
            headers: AdminConfig.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          await applyAppConfig(Map<String, dynamic>.from(decoded['data']));
        }
      }
    } catch (_) {}
  }

  Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) return;
    AdminConfig.baseUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, clean);
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(AdminConfig.loginUrl),
            headers: AdminConfig.getHeaders(),
            body: jsonEncode({
              'login': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(AdminConfig.timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final payload = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'])
            : <String, dynamic>{};
        final userMap = payload['user'] is Map
            ? Map<String, dynamic>.from(payload['user'])
            : <String, dynamic>{};
        final role = userMap['role']?.toString().toLowerCase() ?? '';

        if (role != 'admin') {
          return {
            'success': false,
            'message': 'Akses ditolak. Aplikasi ini khusus untuk akun Admin (role saat ini: ${role.isEmpty ? 'customer' : role}).',
          };
        }

        final token = payload['token']?.toString() ?? data['token']?.toString() ?? '';
        if (token.isEmpty) {
          return {'success': false, 'message': 'Token autentikasi tidak ditemukan.'};
        }

        _authToken = token;
        _currentUser = userMap;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(userMap));
        authState.value = true;

        final appConfig = payload['app_config'] ?? data['app_config'];
        if (appConfig is Map) {
          applyAppConfig(Map<String, dynamic>.from(appConfig)).ignore();
        } else {
          fetchAndSyncAppConfig().ignore();
        }
        syncOneSignalDevice().ignore();

        return {'success': true, 'message': 'Login berhasil.'};
      }

      return {
        'success': false,
        'message': data['message']?.toString() ?? 'Email/HP atau password salah.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<void> logout() async {
    try {
      if (isAuthenticated) {
        await http
            .post(
              Uri.parse(AdminConfig.logoutUrl),
              headers: AdminConfig.getHeaders(token: _authToken),
            )
            .timeout(const Duration(seconds: 6));
      }
    } catch (_) {}

    _authToken = null;
    _currentUser = null;
    _lastSyncedOneSignalId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    authState.value = false;
    AdminNotificationService().clearAdminExternalId().ignore();
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final base = Uri.parse(AdminConfig.endpoint(path));
      final uri = (query != null && query.isNotEmpty)
          ? base.replace(queryParameters: query)
          : base;
      final headers = AdminConfig.getHeaders(token: _authToken);

      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(AdminConfig.timeoutDuration);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(AdminConfig.timeoutDuration);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(AdminConfig.timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(AdminConfig.timeoutDuration);
          break;
      }

      if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi berakhir. Silakan login kembali.'};
      }

      final dynamic decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (decoded is Map<String, dynamic>) {
        final ok = response.statusCode < 300 && decoded['success'] != false;
        String message = decoded['message']?.toString() ?? '';
        if (message.isEmpty && decoded['errors'] is Map) {
          final errors = decoded['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstVal = errors.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              message = firstVal.first.toString();
            }
          }
        }
        return {
          ...decoded,
          'success': ok,
          'message': message.isNotEmpty
              ? message
              : (ok ? 'Berhasil' : 'Permintaan gagal (${response.statusCode})'),
        };
      }

      return {
        'success': response.statusCode < 300,
        'data': decoded,
        'message': response.statusCode < 300 ? 'Berhasil' : 'Error ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}

