import 'package:flutter/foundation.dart';
import 'package:isp_admin_app/config/app_config.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  String? _initializedAppId;
  bool _observerRegistered = false;
  void Function(String subscriptionId)? _onSubscriptionIdChanged;

  bool get isInitialized => _initializedAppId != null && _initializedAppId!.isNotEmpty;

  void setSubscriptionObserver(void Function(String subscriptionId) callback) {
    _onSubscriptionIdChanged = callback;
  }

  String? get currentSubscriptionId {
    try {
      final id = OneSignal.User.pushSubscription.id?.trim();
      return (id != null && id.isNotEmpty) ? id : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> init({String? appId}) async {
    final effectiveAppId = (appId ?? AdminConfig.oneSignalAppId).trim();
    if (effectiveAppId.isEmpty || _initializedAppId == effectiveAppId) {
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.warn);
      OneSignal.initialize(effectiveAppId);

      if (!_observerRegistered) {
        _observerRegistered = true;
        OneSignal.User.pushSubscription.addObserver((state) {
          final id = state.current.id?.trim() ?? '';
          if (id.isNotEmpty) {
            _onSubscriptionIdChanged?.call(id);
          }
        });
      }

      if (_initializedAppId == null) {
        await OneSignal.Notifications.requestPermission(true);
        await OneSignal.User.pushSubscription.optIn();
        OneSignal.Notifications.addClickListener((event) {
          debugPrint('Admin notification clicked: ${event.notification.title}');
        });
      }

      _initializedAppId = effectiveAppId;

      final existingId = currentSubscriptionId;
      if (existingId != null && existingId.isNotEmpty) {
        _onSubscriptionIdChanged?.call(existingId);
      }
    } catch (e) {
      debugPrint('Admin OneSignal Init Note: $e');
    }
  }

  Future<void> setAdminExternalId(int userId) async {
    if (!isInitialized && AdminConfig.oneSignalAppId.trim().isNotEmpty) {
      await init(appId: AdminConfig.oneSignalAppId);
    }
    if (!isInitialized) return;

    try {
      await OneSignal.login('user_$userId');
      if (!OneSignal.Notifications.permission) {
        await OneSignal.Notifications.requestPermission(true);
      }
      await OneSignal.User.pushSubscription.optIn();
      await OneSignal.User.addTags({
        'user_id': userId.toString(),
        'role': 'admin',
      });

      final subId = currentSubscriptionId;
      if (subId != null && subId.isNotEmpty) {
        _onSubscriptionIdChanged?.call(subId);
      }
    } catch (e) {
      debugPrint('Admin OneSignal login Note: $e');
    }
  }

  Future<void> clearAdminExternalId() async {
    try {
      await OneSignal.logout();
    } catch (_) {}
  }
}

