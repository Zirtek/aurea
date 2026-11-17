import 'package:flutter/material.dart';

class CyclePhase {
  final String name;
  final String description;
  final Color color;
  final String nutritionTip;
  final String fitnessTip;
  final String energyTip;

  const CyclePhase({
    required this.name,
    required this.description,
    required this.color,
    required this.nutritionTip,
    required this.fitnessTip,
    required this.energyTip,
  });
}

class DailyLog {
  final String? flowIntensity; // 'Spotting', 'Leggero', 'Medio', 'Abbondante'
  final int? mood; // 1 - 5
  final int? energy; // 1 - 5
  final Set<String> symptoms;
  final Set<String> medications;
  final String note;

  const DailyLog({
    this.flowIntensity,
    this.mood,
    this.energy,
    this.symptoms = const {},
    this.medications = const {},
    this.note = '',
  });

  bool get isEmpty =>
      flowIntensity == null &&
          mood == null &&
          energy == null &&
          symptoms.isEmpty &&
          medications.isEmpty &&
          note.trim().isEmpty;

  DailyLog copyWith({
    String? flowIntensity,
    bool clearFlow = false,
    int? mood,
    bool clearMood = false,
    int? energy,
    bool clearEnergy = false,
    Set<String>? symptoms,
    Set<String>? medications,
    String? note,
  }) {
    return DailyLog(
      flowIntensity: clearFlow ? null : (flowIntensity ?? this.flowIntensity),
      mood: clearMood ? null : (mood ?? this.mood),
      energy: clearEnergy ? null : (energy ?? this.energy),
      symptoms: symptoms ?? this.symptoms,
      medications: medications ?? this.medications,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (flowIntensity != null) 'flow': flowIntensity,
      if (mood != null) 'mood': mood,
      if (energy != null) 'energy': energy,
      if (symptoms.isNotEmpty) 'symptoms': symptoms.toList(),
      if (medications.isNotEmpty) 'medications': medications.toList(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      flowIntensity: json['flow'] as String?,
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      symptoms: json['symptoms'] != null
          ? Set<String>.from(json['symptoms'] as List)
          : const {},
      medications: json['medications'] != null
          ? Set<String>.from(json['medications'] as List)
          : const {},
      note: (json['note'] as String?) ?? '',
    );
  }
}

class CompletedCycleRecord {
  final DateTime startDate;
  final DateTime endDate;
  final int lengthDays;
  final int loggedFlowDays;

  const CompletedCycleRecord({
    required this.startDate,
    required this.endDate,
    required this.lengthDays,
    required this.loggedFlowDays,
  });
}

class CycleAnalytics {
  final int effectiveCycleLength;
  final int effectivePeriodDuration;
  final bool isUsingAutoCycleLength;
  final int minCycleLength;
  final int maxCycleLength;
  final String regularityStatus;
  final List<CompletedCycleRecord> completedCycles;
  final List<MapEntry<String, int>> topSymptoms;
  final List<String> phaseCorrelations;

  const CycleAnalytics({
    required this.effectiveCycleLength,
    required this.effectivePeriodDuration,
    required this.isUsingAutoCycleLength,
    required this.minCycleLength,
    required this.maxCycleLength,
    required this.regularityStatus,
    required this.completedCycles,
    required this.topSymptoms,
    required this.phaseCorrelations,
  });
}

class CycleCalculator {
  static const List<String> availableFlowLevels = [
    'Spotting',
    'Leggero',
    'Medio',
    'Abbondante',
  ];

  static const List<String> availableSymptoms = [
    'Crampi',
    'Stanchezza',
    'Energia alta',
    'Mal di testa',
    'Gonfiore',
    'Sbalzi d\'umore',
    'Pelle luminosa',
    'Insonnia',
    'Nausea',
    'Tensione al seno',
  ];

  static const List<String> availableMedications = [
    'Antidolorifico',
    'Magnesio',
    'Ferro',
    'Antispastico',
    'Integratore',
  ];

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

  static String formatShortDateIt(DateTime date) {
    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static bool isPeriodDay(
      DateTime day,
      List<DateTime> starts,
      int defaultDuration,
      Map<String, DailyLog> logs,
      ) {
    final d = normalizeDate(day);
    final log = logs[dateKey(d)];
    if (log?.flowIntensity != null && log!.flowIntensity != 'Spotting') {
      return true;
    }

    for (final start in starts) {
      final s = normalizeDate(start);
      final diff = d.difference(s).inDays;
      if (diff >= 0 && diff < defaultDuration) {
        return true;
      }
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

  static CyclePhase getPhaseForDay(
      int cycleDay,
      int cycleLength,
      int periodDuration,
      ) {
    final ovulationDay = cycleLength - 14;

    if (cycleDay <= periodDuration) {
      return const CyclePhase(
        name: 'Fase Mestruale',
        description:
        'Livelli ormonali bassi: il corpo si rigenera e richiede calma.',
        color: Color(0xFFD97757),
        nutritionTip:
        'Privilegia cibi ricchi di ferro (legumi, spinaci, carne magra), vitamina C per assorbirlo e tisane calde allo zenzero o camomilla.',
        fitnessTip:
        'Preferisci movimenti dolci: camminata leggera, yoga ristorativo, stretching o riposo completo se avverti crampi.',
        energyTip:
        'Riduci gli impegni superflui, ascolta il bisogno di riposo e dedica tempo alla pianificazione tranquilla.',
      );
    } else if (cycleDay < ovulationDay - 1) {
      return const CyclePhase(
        name: 'Fase Follicolare',
        description:
        'Gli estrogeni risalgono portando lucidità mentale, ottimismo e slancio.',
        color: Color(0xFFD4A373),
        nutritionTip:
        'Alimenti freschi e leggeri, verdure a foglia verde, cereali integrali, semi di lino e proteine magre per sostenere la risalita energetica.',
        fitnessTip:
        'Ottimo momento per allenamenti cardio, corsa, nuoto o esercizi di forza progressiva: il recupero muscolare è più rapido.',
        energyTip:
        'Sfrutta il picco di creatività e concentrazione per avviare nuovi progetti, studiare o prendere decisioni importanti.',
      );
    } else if (cycleDay <= ovulationDay + 2) {
      return const CyclePhase(
        name: 'Fase Ovulatoria',
        description:
        'Picco di estrogeni e LH: massima vitalità fisica, comunicativa e fertilità.',
        color: Color(0xFF8AB17D),
        nutritionTip:
        'Verdure crucifere (broccoli, rucola), antiossidanti (frutti di bosco), fibre e abbondante idratazione per supportare il metabolismo ormonale.',
        fitnessTip:
        'Massima resistenza e forza: ideale per HIIT, pesi, sport di squadra o sessioni ad alta intensità.',
        energyTip:
        'Momento favorevole per riunioni, colloqui, vita sociale e attività che richiedono carisma e comunicazione.',
      );
    } else {
      return const CyclePhase(
        name: 'Fase Luteale',
        description:
        'Prevale il progesterone: l\'energia rallenta gradualmente verso la fine del ciclo.',
        color: Color(0xFF9C89B8),
        nutritionTip:
        'Carboidrati complessi (avena, patate dolci, riso integrale), magnesio (cioccolato fondente, mandorle) e vitamina B6 per stabilizzare umore e glicemia.',
        fitnessTip:
        'Nella prima metà mantieni pesi moderati o pilates; negli ultimi giorni prima del ciclo passa a camminate e mobilità.',
        energyTip:
        'Ottima fase per rifinire dettagli, organizzare e completare compiti già avviati. Riduci caffeina e zuccheri raffinati se senti gonfiore.',
      );
    }
  }

  static CycleAnalytics analyze({
    required List<DateTime> periodStartDates,
    required Map<String, DailyLog> dailyLogs,
    required int manualCycleLength,
    required int manualPeriodDuration,
    required bool autoCalculate,
  }) {
    final sortedStarts = [...periodStartDates]
      ..sort((a, b) => b.compareTo(a));

    final List<CompletedCycleRecord> completed = [];
    for (int i = 0; i < sortedStarts.length - 1; i++) {
      final newer = sortedStarts[i];
      final older = sortedStarts[i + 1];
      final len = newer.difference(older).inDays;
      if (len >= 15 && len <= 65) {
        int flowCount = 0;
        for (int d = 0; d < len; d++) {
          final checkDate = older.add(Duration(days: d));
          final log = dailyLogs[dateKey(checkDate)];
          if (log?.flowIntensity != null && log!.flowIntensity != 'Spotting') {
            flowCount++;
          }
        }
        completed.add(
          CompletedCycleRecord(
            startDate: older,
            endDate: newer.subtract(const Duration(days: 1)),
            lengthDays: len,
            loggedFlowDays: flowCount,
          ),
        );
      }
    }

    // Media ultimi 6 cicli conclusi
    final recentCycles = completed.take(6).toList();
    int effectiveCycleLen = manualCycleLength;
    bool usingAuto = false;
    int minLen = manualCycleLength;
    int maxLen = manualCycleLength;
    String regularity = 'Dati iniziali';

    if (recentCycles.isNotEmpty) {
      final lengths = recentCycles.map((c) => c.lengthDays).toList();
      minLen = lengths.reduce((a, b) => a < b ? a : b);
      maxLen = lengths.reduce((a, b) => a > b ? a : b);
      final avg =
      (lengths.reduce((a, b) => a + b) / lengths.length).round();

      if (autoCalculate) {
        effectiveCycleLen = avg;
        usingAuto = true;
      }

      final spread = maxLen - minLen;
      if (recentCycles.length == 1) {
        regularity = '1 ciclo registrato';
      } else if (spread <= 3) {
        regularity = 'Molto regolare';
      } else if (spread <= 7) {
        regularity = 'Regolare';
      } else {
        regularity = 'Variabile';
      }
    }

    // Media durata mestruazioni se l'utente ha registrato il flusso in almeno un ciclo
    final cyclesWithFlow =
    recentCycles.where((c) => c.loggedFlowDays >= 2).toList();
    int effectivePeriodDur = manualPeriodDuration;
    if (autoCalculate && cyclesWithFlow.isNotEmpty) {
      final sumFlow = cyclesWithFlow
          .map((c) => c.loggedFlowDays)
          .reduce((a, b) => a + b);
      effectivePeriodDur = (sumFlow / cyclesWithFlow.length).round();
    }

    // Conteggio sintomi e correlazione con le fasi
    final Map<String, int> symptomCounts = {};
    final Map<String, Map<String, int>> symptomByPhase = {};

    dailyLogs.forEach((key, log) {
      if (log.symptoms.isEmpty) return;
      DateTime? logDate;
      try {
        logDate = normalizeDate(DateTime.parse(key));
      } catch (_) {
        return;
      }

      final phaseName = _findPhaseNameForHistoricalDate(
        logDate,
        sortedStarts,
        effectiveCycleLen,
        effectivePeriodDur,
      );

      for (final s in log.symptoms) {
        symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
        if (phaseName != null) {
          symptomByPhase.putIfAbsent(s, () => {});
          symptomByPhase[s]![phaseName] =
              (symptomByPhase[s]![phaseName] ?? 0) + 1;
        }
      }
    });

    final topSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<String> correlations = [];
    for (final entry in topSymptoms.take(4)) {
      final symptom = entry.key;
      final phaseMap = symptomByPhase[symptom];
      if (phaseMap != null && phaseMap.isNotEmpty) {
        final bestPhase = phaseMap.entries.reduce(
              (a, b) => a.value >= b.value ? a : b,
        );
        if (bestPhase.value >= 2) {
          correlations.add(
            'Registri spesso "$symptom" durante la ${bestPhase.key} (${bestPhase.value} volte).',
          );
        }
      }
    }

    return CycleAnalytics(
      effectiveCycleLength: effectiveCycleLen,
      effectivePeriodDuration: effectivePeriodDur,
      isUsingAutoCycleLength: usingAuto,
      minCycleLength: minLen,
      maxCycleLength: maxLen,
      regularityStatus: regularity,
      completedCycles: completed,
      topSymptoms: topSymptoms,
      phaseCorrelations: correlations,
    );
  }

  static String? _findPhaseNameForHistoricalDate(
      DateTime date,
      List<DateTime> sortedStartsDesc,
      int defaultCycleLen,
      int periodDur,
      ) {
    if (sortedStartsDesc.isEmpty) return null;

    DateTime? cycleStart;
    int cycleLen = defaultCycleLen;

    for (int i = 0; i < sortedStartsDesc.length; i++) {
      final s = sortedStartsDesc[i];
      if (!date.isBefore(s)) {
        cycleStart = s;
        if (i > 0) {
          final diff = sortedStartsDesc[i - 1].difference(s).inDays;
          if (diff >= 15 && diff <= 65) {
            cycleLen = diff;
          }
        }
        break;
      }
    }

    if (cycleStart == null) return null;
    final cycleDay = date.difference(cycleStart).inDays + 1;
    if (cycleDay < 1 || cycleDay > 65) return null;

    return getPhaseForDay(cycleDay, cycleLen, periodDur).name;
  }

  static String generateMedicalReport({
    required List<DateTime> periodStartDates,
    required Map<String, DailyLog> dailyLogs,
    required CycleAnalytics analytics,
  }) {
    final buffer = StringBuffer();
    final today = normalizeDate(DateTime.now());

    buffer.writeln('RIEPILOGO CICLO MESTRUALE - AUREA');
    buffer.writeln('Data report: ${formatDateIt(today)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('PARAMETRI GENERALI');
    buffer.writeln(
        '• Durata media ciclo: ${analytics.effectiveCycleLength} giorni (${analytics.regularityStatus})');
    if (analytics.completedCycles.length >= 2) {
      buffer.writeln(
          '• Intervallo min-max: ${analytics.minCycleLength} - ${analytics.maxCycleLength} giorni');
    }
    buffer.writeln(
        '• Durata media mestruazioni: ${analytics.effectivePeriodDuration} giorni');
    buffer.writeln('');

    buffer.writeln('ULTIME DATE INIZIO CICLO');
    for (int i = 0; i < periodStartDates.length && i < 12; i++) {
      final start = periodStartDates[i];
      if (i == 0) {
        final currentDay = today.difference(start).inDays + 1;
        buffer.writeln(
            '• ${formatDateIt(start)} (Ciclo attuale - Giorno $currentDay)');
      } else {
        final prev = periodStartDates[i - 1];
        final len = prev.difference(start).inDays;
        buffer.writeln('• ${formatDateIt(start)} -> Durata: $len giorni');
      }
    }
    buffer.writeln('');

    if (analytics.topSymptoms.isNotEmpty) {
      buffer.writeln('SINTOMI PIÙ FREQUENTI');
      for (final s in analytics.topSymptoms.take(6)) {
        buffer.writeln('• ${s.key}: ${s.value} registrazioni');
      }
      buffer.writeln('');
    }

    final Set<String> usedMeds = {};
    final List<String> recentNotes = [];
    final sortedLogKeys = dailyLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final key in sortedLogKeys) {
      final log = dailyLogs[key]!;
      usedMeds.addAll(log.medications);
      if (log.note.trim().isNotEmpty && recentNotes.length < 5) {
        try {
          final d = DateTime.parse(key);
          recentNotes.add('• ${formatDateIt(d)}: ${log.note.trim()}');
        } catch (_) {}
      }
    }

    if (usedMeds.isNotEmpty) {
      buffer.writeln('FARMACI / INTEGRATORI REGISTRATI');
      buffer.writeln('• ${usedMeds.join(', ')}');
      buffer.writeln('');
    }

    if (recentNotes.isNotEmpty) {
      buffer.writeln('NOTE PERSONALI RECENTI');
      for (final n in recentNotes) {
        buffer.writeln(n);
      }
    }

    return buffer.toString().trim();
  }
}