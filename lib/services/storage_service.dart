import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_models.dart';

class StoredCycleData {
  final List<DateTime> periodStartDates;
  final Map<String, Set<String>> dailySymptoms;
  final int averageCycleLength;
  final int averagePeriodDuration;

  StoredCycleData({
    required this.periodStartDates,
    required this.dailySymptoms,
    required this.averageCycleLength,
    required this.averagePeriodDuration,
  });
}

class StorageService {
  static const _keyPeriods = 'aurea_period_starts';
  static const _keySymptoms = 'aurea_daily_symptoms';
  static const _keyCycleLength = 'aurea_cycle_length';
  static const _keyPeriodDuration = 'aurea_period_duration';

  Future<StoredCycleData> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final cycleLength = prefs.getInt(_keyCycleLength) ?? 28;
    final periodDuration = prefs.getInt(_keyPeriodDuration) ?? 5;

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

    final rawSymptoms = prefs.getString(_keySymptoms);
    final Map<String, Set<String>> symptoms = {};
    if (rawSymptoms != null) {
      final decoded = jsonDecode(rawSymptoms) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        symptoms[key] = Set<String>.from(value as List);
      });
    }

    return StoredCycleData(
      periodStartDates: dates,
      dailySymptoms: symptoms,
      averageCycleLength: cycleLength,
      averagePeriodDuration: periodDuration,
    );
  }

  Future<void> savePeriodStarts(List<DateTime> dates) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = dates.map((d) => d.toIso8601String()).toList();
    await prefs.setStringList(_keyPeriods, encoded);
  }

  Future<void> saveDailySymptoms(Map<String, Set<String>> symptoms) async {
    final prefs = await SharedPreferences.getInstance();
    final serializable =
    symptoms.map((key, value) => MapEntry(key, value.toList()));
    await prefs.setString(_keySymptoms, jsonEncode(serializable));
  }

  Future<void> saveSettings(int cycleLength, int periodDuration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCycleLength, cycleLength);
    await prefs.setInt(_keyPeriodDuration, periodDuration);
  }

  String exportBackupJson(StoredCycleData data) {
    return jsonEncode({
      'cycleLength': data.averageCycleLength,
      'periodDuration': data.averagePeriodDuration,
      'periods': data.periodStartDates.map((d) => d.toIso8601String()).toList(),
      'symptoms': data.dailySymptoms.map((k, v) => MapEntry(k, v.toList())),
    });
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final cycleLength = decoded['cycleLength'] as int;
      final periodDuration = decoded['periodDuration'] as int;
      final periods = (decoded['periods'] as List)
          .map((e) => CycleCalculator.normalizeDate(DateTime.parse(e as String)))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final Map<String, Set<String>> symptoms = {};
      final rawSym = decoded['symptoms'] as Map<String, dynamic>;
      rawSym.forEach((k, v) {
        symptoms[k] = Set<String>.from(v as List);
      });

      await saveSettings(cycleLength, periodDuration);
      await savePeriodStarts(periods);
      await saveDailySymptoms(symptoms);
      return true;
    } catch (_) {
      return false;
    }
  }
}