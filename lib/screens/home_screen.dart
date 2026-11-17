import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cycle_models.dart';
import '../services/storage_service.dart';
import 'calendar_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  int _selectedIndex = 0;

  int _averageCycleLength = 28;
  int _averagePeriodDuration = 5;
  List<DateTime> _periodStartDates = [];
  Map<String, Set<String>> _dailySymptoms = {};

  final List<String> _availableSymptoms = const [
    'Crampi',
    'Stanchezza',
    'Energia alta',
    'Mal di testa',
    'Gonfiore',
    'Sbalzi d\'umore',
    'Pelle luminosa',
    'Insonnia',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final data = await _storage.loadData();
    setState(() {
      _periodStartDates = data.periodStartDates;
      _dailySymptoms = data.dailySymptoms;
      _averageCycleLength = data.averageCycleLength;
      _averagePeriodDuration = data.averagePeriodDuration;
      _isLoading = false;
    });
  }

  DateTime get _lastPeriodStart => _periodStartDates.first;

  int get _currentCycleDay {
    final today = CycleCalculator.normalizeDate(DateTime.now());
    final diff = today.difference(_lastPeriodStart).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  DateTime get _nextPredictedPeriod =>
      _lastPeriodStart.add(Duration(days: _averageCycleLength));

  int get _daysUntilNextPeriod {
    final today = CycleCalculator.normalizeDate(DateTime.now());
    return _nextPredictedPeriod.difference(today).inDays;
  }

  Future<void> _logNewPeriodStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'Seleziona il giorno di inizio',
    );

    if (picked != null) {
      final normalized = CycleCalculator.normalizeDate(picked);
      setState(() {
        if (!_periodStartDates.contains(normalized)) {
          _periodStartDates.add(normalized);
          _periodStartDates.sort((a, b) => b.compareTo(a));
        }
      });
      await _storage.savePeriodStarts(_periodStartDates);
    }
  }

  Future<void> _toggleSymptomForDate(DateTime date, String symptom) async {
    final key = CycleCalculator.dateKey(date);
    setState(() {
      _dailySymptoms.putIfAbsent(key, () => <String>{});
      if (_dailySymptoms[key]!.contains(symptom)) {
        _dailySymptoms[key]!.remove(symptom);
      } else {
        _dailySymptoms[key]!.add(symptom);
      }
    });
    await _storage.saveDailySymptoms(_dailySymptoms);
  }

  Future<void> _copyBackupToClipboard() async {
    final jsonStr = _storage.exportBackupJson(
      StoredCycleData(
        periodStartDates: _periodStartDates,
        dailySymptoms: _dailySymptoms,
        averageCycleLength: _averageCycleLength,
        averagePeriodDuration: _averagePeriodDuration,
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
                  const SnackBar(content: Text('Dati ripristinati con successo')),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Durata media ciclo (giorni)'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_averageCycleLength > 21) {
                                setState(() => _averageCycleLength--);
                                setModalState(() {});
                                _storage.saveSettings(
                                    _averageCycleLength, _averagePeriodDuration);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_averageCycleLength',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_averageCycleLength < 40) {
                                setState(() => _averageCycleLength++);
                                setModalState(() {});
                                _storage.saveSettings(
                                    _averageCycleLength, _averagePeriodDuration);
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
                      const Text('Durata mestruazioni (giorni)'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_averagePeriodDuration > 2) {
                                setState(() => _averagePeriodDuration--);
                                setModalState(() {});
                                _storage.saveSettings(
                                    _averageCycleLength, _averagePeriodDuration);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_averagePeriodDuration',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_averagePeriodDuration < 10) {
                                setState(() => _averagePeriodDuration++);
                                setModalState(() {});
                                _storage.saveSettings(
                                    _averageCycleLength, _averagePeriodDuration);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 28),
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

    final pages = [
      _buildDashboardTab(),
      CalendarScreen(
        periodStartDates: _periodStartDates,
        dailySymptoms: _dailySymptoms,
        averageCycleLength: _averageCycleLength,
        averagePeriodDuration: _averagePeriodDuration,
        availableSymptoms: _availableSymptoms,
        onToggleSymptom: _toggleSymptomForDate,
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
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: const Color(0xFFFFFDF9),
        indicatorColor: const Color(0xFFD97757).withValues(alpha: 0.2),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFFD97757)),
            label: 'Storico',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final phase = CycleCalculator.getCurrentPhase(
      _currentCycleDay,
      _averageCycleLength,
      _averagePeriodDuration,
    );
    final daysLeft = _daysUntilNextPeriod;
    final today = CycleCalculator.normalizeDate(DateTime.now());
    final todaySymptoms =
        _dailySymptoms[CycleCalculator.dateKey(today)] ?? {};

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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: phase.color.withValues(alpha: 0.3)),
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
                const SizedBox(height: 16),
                Text(
                  'Giorno $_currentCycleDay',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2520),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  countdownText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6E6259),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  phase.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A4F47),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          const Text(
            'Come ti senti oggi?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSymptoms.map((symptom) {
              final isSelected = todaySymptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (_) => _toggleSymptomForDate(today, symptom),
                backgroundColor: const Color(0xFFFFFDF9),
                selectedColor: const Color(0xFFD97757).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFD97757),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFD97757)
                        : const Color(0xFFE6DDD3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _periodStartDates.length,
      itemBuilder: (context, index) {
        final startDate = _periodStartDates[index];
        String cycleDurationLabel = 'Ciclo in corso';

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
              backgroundColor: const Color(0xFFD97757).withValues(alpha: 0.15),
              child: const Icon(Icons.water_drop, color: Color(0xFFD97757)),
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
            trailing: index > 0
                ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
    );
  }
}