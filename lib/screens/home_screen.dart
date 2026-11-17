import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cycle_models.dart';
import '../services/storage_service.dart';
import '../widgets/daily_log_editor.dart';
import 'calendar_screen.dart';
import 'analytics_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  int _selectedIndex = 0;

  int _manualCycleLength = 28;
  int _manualPeriodDuration = 5;
  bool _autoCalculate = true;
  List<DateTime> _periodStartDates = [];
  Map<String, DailyLog> _dailyLogs = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final data = await _storage.loadData();
    setState(() {
      _periodStartDates = data.periodStartDates;
      _dailyLogs = data.dailyLogs;
      _manualCycleLength = data.manualCycleLength;
      _manualPeriodDuration = data.manualPeriodDuration;
      _autoCalculate = data.autoCalculate;
      _isLoading = false;
    });
  }

  CycleAnalytics get _analytics => CycleCalculator.analyze(
    periodStartDates: _periodStartDates,
    dailyLogs: _dailyLogs,
    manualCycleLength: _manualCycleLength,
    manualPeriodDuration: _manualPeriodDuration,
    autoCalculate: _autoCalculate,
  );

  DateTime get _lastPeriodStart => _periodStartDates.first;

  int get _currentCycleDay {
    final today = CycleCalculator.normalizeDate(DateTime.now());
    final diff = today.difference(_lastPeriodStart).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  DateTime get _nextPredictedPeriod =>
      _lastPeriodStart.add(Duration(days: _analytics.effectiveCycleLength));

  int get _daysUntilNextPeriod {
    final today = CycleCalculator.normalizeDate(DateTime.now());
    return _nextPredictedPeriod.difference(today).inDays;
  }

  Future<void> _logNewPeriodStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 730)),
      lastDate: now,
      helpText: 'Seleziona il giorno di inizio ciclo',
    );

    if (picked != null) {
      final normalized = CycleCalculator.normalizeDate(picked);
      final key = CycleCalculator.dateKey(normalized);

      setState(() {
        if (!_periodStartDates.contains(normalized)) {
          _periodStartDates.add(normalized);
          _periodStartDates.sort((a, b) => b.compareTo(a));
        }
        // Imposta flusso 'Medio' di default se non già registrato per quel giorno
        final existing = _dailyLogs[key] ?? const DailyLog();
        if (existing.flowIntensity == null) {
          _dailyLogs[key] = existing.copyWith(flowIntensity: 'Medio');
        }
      });

      await _storage.savePeriodStarts(_periodStartDates);
      await _storage.saveDailyLogs(_dailyLogs);
    }
  }

  Future<void> _updateLogForDate(DateTime date, DailyLog updatedLog) async {
    final key = CycleCalculator.dateKey(date);
    setState(() {
      if (updatedLog.isEmpty) {
        _dailyLogs.remove(key);
      } else {
        _dailyLogs[key] = updatedLog;
      }
    });
    await _storage.saveDailyLogs(_dailyLogs);
  }

  Future<void> _copyBackupToClipboard() async {
    final jsonStr = _storage.exportBackupJson(
      StoredCycleData(
        periodStartDates: _periodStartDates,
        dailyLogs: _dailyLogs,
        manualCycleLength: _manualCycleLength,
        manualPeriodDuration: _manualPeriodDuration,
        autoCalculate: _autoCalculate,
      ),
    );
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup copiato negli appunti')),
    );
  }

  Future<void> _showRestoreDialog() async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripristina backup'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Incolla qui il codice JSON salvato',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await _storage.importBackupJson(controller.text.trim());
              if (ok) {
                await _initData();
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Dati ripristinati con successo')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Codice backup non valido')),
                );
              }
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parametri del ciclo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2520),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Calcolo automatico media',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Adatta le previsioni usando gli ultimi cicli registrati',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _autoCalculate,
                    activeColor: const Color(0xFFD97757),
                    onChanged: (val) {
                      setState(() => _autoCalculate = val);
                      setModalState(() {});
                      _storage.saveSettings(
                        cycleLength: _manualCycleLength,
                        periodDuration: _manualPeriodDuration,
                        autoCalculate: _autoCalculate,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _autoCalculate
                            ? 'Ciclo base di riferimento (gg)'
                            : 'Durata ciclo manuale (gg)',
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_manualCycleLength > 21) {
                                setState(() => _manualCycleLength--);
                                setModalState(() {});
                                _storage.saveSettings(
                                  cycleLength: _manualCycleLength,
                                  periodDuration: _manualPeriodDuration,
                                  autoCalculate: _autoCalculate,
                                );
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_manualCycleLength',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_manualCycleLength < 45) {
                                setState(() => _manualCycleLength++);
                                setModalState(() {});
                                _storage.saveSettings(
                                  cycleLength: _manualCycleLength,
                                  periodDuration: _manualPeriodDuration,
                                  autoCalculate: _autoCalculate,
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Durata mestruazioni base (gg)'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_manualPeriodDuration > 2) {
                                setState(() => _manualPeriodDuration--);
                                setModalState(() {});
                                _storage.saveSettings(
                                  cycleLength: _manualCycleLength,
                                  periodDuration: _manualPeriodDuration,
                                  autoCalculate: _autoCalculate,
                                );
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_manualPeriodDuration',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_manualPeriodDuration < 10) {
                                setState(() => _manualPeriodDuration++);
                                setModalState(() {});
                                _storage.saveSettings(
                                  cycleLength: _manualCycleLength,
                                  periodDuration: _manualPeriodDuration,
                                  autoCalculate: _autoCalculate,
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Sicurezza dati (PWA)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2520),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyBackupToClipboard,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copia backup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showRestoreDialog,
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text('Ripristina'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentAnalytics = _analytics;

    final pages = [
      _buildDashboardTab(currentAnalytics),
      CalendarScreen(
        periodStartDates: _periodStartDates,
        dailyLogs: _dailyLogs,
        effectiveCycleLength: currentAnalytics.effectiveCycleLength,
        effectivePeriodDuration: currentAnalytics.effectivePeriodDuration,
        onUpdateLog: _updateLogForDate,
      ),
      AnalyticsScreen(
        periodStartDates: _periodStartDates,
        dailyLogs: _dailyLogs,
        analytics: currentAnalytics,
      ),
      _buildHistoryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF2C2520)),
            onPressed: _openSettingsModal,
            tooltip: 'Impostazioni',
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: const Color(0xFFFFFDF9),
        indicatorColor: const Color(0xFFD97757).withValues(alpha: 0.2),
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: Color(0xFFD97757)),
            label: 'Oggi',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFFD97757)),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: Color(0xFFD97757)),
            label: 'Analisi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFFD97757)),
            label: 'Storico',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(CycleAnalytics currentAnalytics) {
    final phase = CycleCalculator.getPhaseForDay(
      _currentCycleDay,
      currentAnalytics.effectiveCycleLength,
      currentAnalytics.effectivePeriodDuration,
    );
    final daysLeft = _daysUntilNextPeriod;
    final today = CycleCalculator.normalizeDate(DateTime.now());
    final todayLog =
        _dailyLogs[CycleCalculator.dateKey(today)] ?? const DailyLog();

    String countdownText;
    if (daysLeft > 1) {
      countdownText = 'Prossimo ciclo tra $daysLeft giorni';
    } else if (daysLeft == 1) {
      countdownText = 'Prossimo ciclo previsto domani';
    } else if (daysLeft == 0) {
      countdownText = 'Ciclo previsto oggi';
    } else {
      countdownText = 'Ritardo di ${daysLeft.abs()} giorni';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Card Principale Ciclo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: phase.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: phase.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phase.name.toUpperCase(),
                    style: TextStyle(
                      color: phase.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Giorno $_currentCycleDay',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2520),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdownText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6E6259),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentAnalytics.isUsingAutoCycleLength
                      ? 'Media reale: ${currentAnalytics.effectiveCycleLength} giorni (${currentAnalytics.regularityStatus})'
                      : 'Ciclo di riferimento: ${currentAnalytics.effectiveCycleLength} giorni',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7E75),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  phase.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A4F47),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _logNewPeriodStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD97757),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text(
                    'Registra inizio ciclo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Consigli pratici Cycle Syncing
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6DDD3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa_outlined, color: phase.color, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Consigli per questa fase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2520),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _tipRow(
                  icon: Icons.restaurant_outlined,
                  title: 'Alimentazione',
                  body: phase.nutritionTip,
                  color: phase.color,
                ),
                const SizedBox(height: 12),
                _tipRow(
                  icon: Icons.fitness_center_outlined,
                  title: 'Movimento',
                  body: phase.fitnessTip,
                  color: phase.color,
                ),
                const SizedBox(height: 12),
                _tipRow(
                  icon: Icons.bolt_outlined,
                  title: 'Energia & Focus',
                  body: phase.energyTip,
                  color: phase.color,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Diario completo di oggi
          const Text(
            'Il tuo diario di oggi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 12),
          DailyLogEditor(
            date: today,
            log: todayLog,
            onChanged: (updated) => _updateLogForDate(today, updated),
          ),
        ],
      ),
    );
  }

  Widget _tipRow({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2520),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5A4F47),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logNewPeriodStart,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97757),
                side: const BorderSide(color: Color(0xFFD97757)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Aggiungi data inizio ciclo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _periodStartDates.length,
            itemBuilder: (context, index) {
              final startDate = _periodStartDates[index];
              String cycleDurationLabel = 'Ciclo attuale (Giorno $_currentCycleDay)';

              if (index > 0) {
                final previousStart = _periodStartDates[index - 1];
                final length = previousStart.difference(startDate).inDays;
                cycleDurationLabel = 'Durata ciclo: $length giorni';
              }

              return Card(
                color: const Color(0xFFFFFDF9),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE6DDD3)),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                    const Color(0xFFD97757).withValues(alpha: 0.15),
                    child:
                    const Icon(Icons.water_drop, color: Color(0xFFD97757)),
                  ),
                  title: Text(
                    CycleCalculator.formatDateIt(startDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2520),
                    ),
                  ),
                  subtitle: Text(
                    cycleDurationLabel,
                    style: const TextStyle(color: Color(0xFF6E6259)),
                  ),
                  trailing: _periodStartDates.length > 1
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.grey),
                    onPressed: () async {
                      setState(() {
                        _periodStartDates.removeAt(index);
                      });
                      await _storage.savePeriodStarts(_periodStartDates);
                    },
                  )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}