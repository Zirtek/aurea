import 'package:flutter/material.dart';
import '../models/cycle_models.dart';
import '../services/push_service.dart';

class NotificationSettingsSheet extends StatefulWidget {
  final NotificationSettings initialSettings;
  final DateTime lastPeriodStart;
  final int effectiveCycleLength;
  final bool hasLoggedToday;
  final Future<void> Function(NotificationSettings updated) onSaveSettings;

  const NotificationSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.lastPeriodStart,
    required this.effectiveCycleLength,
    required this.hasLoggedToday,
    required this.onSaveSettings,
  });

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  late NotificationSettings _settings;
  PushEnvironment? _env;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _loadEnv();
  }

  Future<void> _loadEnv() async {
    final env = await PushService.getEnvironment();
    if (mounted) setState(() => _env = env);
  }

  Future<void> _updateAndSync(NotificationSettings next) async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      await PushService.syncWithServer(
        settings: next,
        lastPeriodStart: widget.lastPeriodStart,
        effectiveCycleLength: widget.effectiveCycleLength,
        hasLoggedToday: widget.hasLoggedToday,
      );
      await widget.onSaveSettings(next);
      if (mounted) {
        setState(() {
          _settings = next;
          _statusMessage = next.enabled
              ? 'Preferenze sincronizzate con iPhone'
              : 'Notifiche disattivate';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    try {
      await PushService.sendTestNotification();
      if (mounted) {
        setState(() => _statusMessage = 'Notifica di test inviata! Controlla il centro notifiche.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsInstall = _env?.needsIosHomeScreenInstall ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promemoria iOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2520),
                ),
              ),
              if (_isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFD97757),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (needsInstall)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD97757).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD97757).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Per ricevere notifiche su iPhone, tocca Condividi in Safari → "Aggiungi alla schermata Home" e riapri Aurea dall\'icona creata.',
                style: TextStyle(fontSize: 13, color: Color(0xFF2C2520), height: 1.35),
              ),
            ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Attiva notifiche push',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Ricevi avvisi anche quando l\'app è chiusa',
              style: TextStyle(fontSize: 12),
            ),
            value: _settings.enabled,
            activeColor: const Color(0xFFD97757),
            onChanged: _isBusy
                ? null
                : (val) => _updateAndSync(_settings.copyWith(enabled: val)),
          ),

          const Divider(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ciclo in arrivo (2 giorni prima)'),
            subtitle: const Text('Avviso alle 09:00 due giorni prima della data prevista', style: TextStyle(fontSize: 12)),
            value: _settings.notifyPeriodBefore,
            activeColor: const Color(0xFFD97757),
            onChanged: (!_settings.enabled || _isBusy)
                ? null
                : (val) => _updateAndSync(_settings.copyWith(notifyPeriodBefore: val)),
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inizio finestra fertile'),
            subtitle: const Text('Avviso alle 09:00 nel primo giorno fertile', style: TextStyle(fontSize: 12)),
            value: _settings.notifyFertileStart,
            activeColor: const Color(0xFF8AB17D),
            onChanged: (!_settings.enabled || _isBusy)
                ? null
                : (val) => _updateAndSync(_settings.copyWith(notifyFertileStart: val)),
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Diario serale & farmaci'),
            subtitle: Text(
              'Promemoria alle ${_settings.dailyLogHour.toString().padLeft(2, '0')}:00 se non hai ancora registrato oggi',
              style: const TextStyle(fontSize: 12),
            ),
            value: _settings.notifyDailyLog,
            activeColor: const Color(0xFF9C89B8),
            onChanged: (!_settings.enabled || _isBusy)
                ? null
                : (val) => _updateAndSync(_settings.copyWith(notifyDailyLog: val)),
          ),

          if (_settings.enabled && _settings.notifyDailyLog)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orario promemoria serale', style: TextStyle(fontSize: 13)),
                DropdownButton<int>(
                  value: _settings.dailyLogHour,
                  items: [18, 19, 20, 21, 22].map((h) {
                    return DropdownMenuItem(
                      value: h,
                      child: Text('${h.toString().padLeft(2, '0')}:00'),
                    );
                  }).toList(),
                  onChanged: _isBusy
                      ? null
                      : (h) {
                    if (h != null) {
                      _updateAndSync(_settings.copyWith(dailyLogHour: h));
                    }
                  },
                ),
              ],
            ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _statusMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD97757),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: _isBusy ? null : _sendTest,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97757),
              side: const BorderSide(color: Color(0xFFD97757)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text('Invia notifica di test ora'),
          ),
        ],
      ),
    );
  }
}