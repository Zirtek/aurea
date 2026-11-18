import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cycle_models.dart';
import 'push_bridge_stub.dart'
if (dart.library.js_interop) 'push_bridge_web.dart';

class PushEnvironment {
  final bool isIOS;
  final bool isStandalone;
  final bool isSupported;
  final String permission;

  const PushEnvironment({
    required this.isIOS,
    required this.isStandalone,
    required this.isSupported,
    required this.permission,
  });

  bool get needsIosHomeScreenInstall => isIOS && !isStandalone;
}

class PushService {
  static Future<PushEnvironment> getEnvironment() async {
    final raw = await getPushEnvInfoImpl();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return PushEnvironment(
      isIOS: (map['isIOS'] as bool?) ?? false,
      isStandalone: (map['isStandalone'] as bool?) ?? false,
      isSupported: (map['isSupported'] as bool?) ?? false,
      permission: (map['permission'] as String?) ?? 'default',
    );
  }

  static Future<void> syncWithServer({
    required NotificationSettings settings,
    required DateTime lastPeriodStart,
    required int effectiveCycleLength,
    required bool hasLoggedToday,
  }) async {
    String rawSub = await getCurrentSubscriptionImpl();

    if (settings.enabled && rawSub.isEmpty) {
      rawSub = await subscribePushImpl();
    } else if (!settings.enabled && rawSub.isNotEmpty) {
      await _postJson('/api/sync-push', {
        'subscription': jsonDecode(rawSub),
        'enabled': false,
      });
      await unsubscribePushImpl();
      return;
    }

    if (rawSub.isEmpty) return;

    final now = DateTime.now();
    final tzOffsetMinutes = -now.timeZoneOffset.inMinutes;

    await _postJson('/api/sync-push', {
      'subscription': jsonDecode(rawSub),
      'enabled': settings.enabled,
      'lastPeriodStart': CycleCalculator.dateKey(lastPeriodStart),
      'effectiveCycleLength': effectiveCycleLength,
      'notifyPeriodBefore': settings.notifyPeriodBefore,
      'notifyFertileStart': settings.notifyFertileStart,
      'notifyDailyLog': settings.notifyDailyLog,
      'dailyLogHour': settings.dailyLogHour,
      'timezoneOffsetMinutes': tzOffsetMinutes,
      'hasLoggedToday': hasLoggedToday,
      'todayKey': CycleCalculator.dateKey(now),
    });
  }

  static Future<void> sendTestNotification() async {
    String rawSub = await getCurrentSubscriptionImpl();
    if (rawSub.isEmpty) {
      rawSub = await subscribePushImpl();
    }
    await _postJson('/api/test-push', {
      'subscription': jsonDecode(rawSub),
    });
  }

  static Future<void> _postJson(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () =>
      throw Exception('Timeout connessione al server Vercel.'),
    );
    if (response.statusCode >= 400) {
      throw Exception('Errore server (${response.statusCode}): ${response.body}');
    }
  }
}