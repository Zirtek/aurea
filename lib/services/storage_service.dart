import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_models.dart';

class StoredCycleData {
  final List<DateTime> periodStartDates;
  final Map<String, DailyLog> dailyLogs;
  final int manualCycleLength;
  final int manualPeriodDuration;
  final bool autoCalculate;

  StoredCycleData({
    required this.periodStartDates,
    required this.dailyLogs,
    required this.manualCycleLength,
    required this.manualPeriodDuration,
    required this.autoCalculate,
  });
}

class StorageService {
  static const _keyPeriods = 'aurea_period_starts';
  static const _keyLogsV2 = 'aurea_daily_logs_v2';
  static const _keyLegacySymptoms = 'aurea_daily_symptoms';
  static const _keyCycleLength = 'aurea_cycle_length';
  static const _keyPeriodDuration = 'aurea_period_duration';
  static const _keyAutoCalc = 'aurea_auto_calc';

  Future<StoredCycleData> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final cycleLength = prefs.getInt(_keyCycleLength) ?? 28;
    final periodDuration = prefs.getInt(_keyPeriodDuration) ?? 5;
    final autoCalc = prefs.getBool(_keyAutoCalc) ?? true;

    final rawDates = prefs.getStringList(_keyPeriods);
    List<DateTime> dates;
    if (rawDates == null || rawDates.isEmpty) {
      final today = CycleCalculator.normalizeDate(DateTime.now());
      dates = [today.subtract(const Duration(days: 11))];
      await savePeriodStarts(dates);
    } else {
      dates = rawDates
          .map((e) => CycleCalculator.normalizeDate(DateTime.parse(e)))
          .toList()
        ..sort((a, b) => b.compareTo(a));
    }

    final Map<String, DailyLog> logs = {};
    final rawLogsV2 = prefs.getString(_keyLogsV2);

    if (rawLogsV2 != null) {
      final decoded = jsonDecode(rawLogsV2) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        logs[key] = DailyLog.fromJson(value as Map<String, dynamic>);
      });
    } else {
      // Migrazione automatica da eventuali sintomi v1 salvati in precedenza
      final rawLegacy = prefs.getString(_keyLegacySymptoms);
      if (rawLegacy != null) {
        final decoded = jsonDecode(rawLegacy) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          logs[key] = DailyLog(symptoms: Set<String>.from(value as List));
        });
        await saveDailyLogs(logs);
      }
    }

    return StoredCycleData(
      periodStartDates: dates,
      dailyLogs: logs,
      manualCycleLength: cycleLength,
      manualPeriodDuration: periodDuration,
      autoCalculate: autoCalc,
    );
  }

  Future<void> savePeriodStarts(List<DateTime> dates) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = dates.map((d) => d.toIso8601String()).toList();
    await prefs.setStringList(_keyPeriods, encoded);
  }

  Future<void> saveDailyLogs(Map<String, DailyLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serializable = {};
    logs.forEach((key, value) {
      if (!value.isEmpty) {
        serializable[key] = value.toJson();
      }
    });
    await prefs.setString(_keyLogsV2, jsonEncode(serializable));
  }

  Future<void> saveSettings({
    required int cycleLength,
    required int periodDuration,
    required bool autoCalculate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCycleLength, cycleLength);
    await prefs.setInt(_keyPeriodDuration, periodDuration);
    await prefs.setBool(_keyAutoCalc, autoCalculate);
  }

  String exportBackupJson(StoredCycleData data) {
    final Map<String, dynamic> serializedLogs = {};
    data.dailyLogs.forEach((k, v) {
      if (!v.isEmpty) serializedLogs[k] = v.toJson();
    });

    return jsonEncode({
      'version': 2,
      'cycleLength': data.manualCycleLength,
      'periodDuration': data.manualPeriodDuration,
      'autoCalculate': data.autoCalculate,
      'periods': data.periodStartDates.map((d) => d.toIso8601String()).toList(),
      'logs': serializedLogs,
    });
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final cycleLength = (decoded['cycleLength'] as int?) ?? 28;
      final periodDuration = (decoded['periodDuration'] as int?) ?? 5;
      final autoCalculate = (decoded['autoCalculate'] as bool?) ?? true;

      final periods = (decoded['periods'] as List)
          .map((e) => CycleCalculator.normalizeDate(DateTime.parse(e as String)))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final Map<String, DailyLog> logs = {};
      if (decoded['logs'] != null) {
        final rawLogs = decoded['logs'] as Map<String, dynamic>;
        rawLogs.forEach((k, v) {
          logs[k] = DailyLog.fromJson(v as Map<String, dynamic>);
        });
      } else if (decoded['symptoms'] != null) {
        final rawSym = decoded['symptoms'] as Map<String, dynamic>;
        rawSym.forEach((k, v) {
          logs[k] = DailyLog(symptoms: Set<String>.from(v as List));
        });
      }

      await saveSettings(
        cycleLength: cycleLength,
        periodDuration: periodDuration,
        autoCalculate: autoCalculate,
      );
      await savePeriodStarts(periods);
      await saveDailyLogs(logs);
      return true;
    } catch (_) {
      return false;
    }
  }
}