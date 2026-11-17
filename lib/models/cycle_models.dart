import 'package:flutter/material.dart';

class CyclePhase {
  final String name;
  final String description;
  final Color color;

  const CyclePhase({
    required this.name,
    required this.description,
    required this.color,
  });
}

class CycleCalculator {
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateIt(DateTime date) {
    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static bool isPeriodDay(DateTime day, List<DateTime> starts, int duration) {
    final d = normalizeDate(day);
    for (final start in starts) {
      final s = normalizeDate(start);
      final diff = d.difference(s).inDays;
      if (diff >= 0 && diff < duration) return true;
    }
    return false;
  }

  static bool isPredictedPeriodDay(
      DateTime day,
      DateTime lastStart,
      int cycleLength,
      int duration,
      ) {
    final d = normalizeDate(day);
    final nextStart = normalizeDate(lastStart).add(Duration(days: cycleLength));
    final diff = d.difference(nextStart).inDays;
    return diff >= 0 && diff < duration;
  }

  static bool isFertileDay(
      DateTime day,
      DateTime lastStart,
      int cycleLength,
      ) {
    final d = normalizeDate(day);
    final ovulationDay =
    normalizeDate(lastStart).add(Duration(days: cycleLength - 14));
    final diff = d.difference(ovulationDay).inDays;
    return diff >= -4 && diff <= 1;
  }

  static CyclePhase getCurrentPhase(
      int cycleDay,
      int cycleLength,
      int periodDuration,
      ) {
    final ovulationDay = cycleLength - 14;

    if (cycleDay <= periodDuration) {
      return const CyclePhase(
        name: 'Fase Mestruale',
        description: 'Momento di riposo, introspezione e recupero delle energie.',
        color: Color(0xFFD97757),
      );
    } else if (cycleDay < ovulationDay - 1) {
      return const CyclePhase(
        name: 'Fase Follicolare',
        description: 'Energia in crescita, chiarezza mentale e creatività.',
        color: Color(0xFFD4A373),
      );
    } else if (cycleDay <= ovulationDay + 2) {
      return const CyclePhase(
        name: 'Fase Ovulatoria',
        description: 'Picco di vitalità, socialità e massima fertilità.',
        color: Color(0xFF8AB17D),
      );
    } else {
      return const CyclePhase(
        name: 'Fase Luteale',
        description: 'Rallentamento graduale: privilegia equilibrio e cura di sé.',
        color: Color(0xFF9C89B8),
      );
    }
  }
}