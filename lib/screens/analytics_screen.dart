import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cycle_models.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<DateTime> periodStartDates;
  final Map<String, DailyLog> dailyLogs;
  final CycleAnalytics analytics;

  const AnalyticsScreen({
    super.key,
    required this.periodStartDates,
    required this.dailyLogs,
    required this.analytics,
  });

  void _openMedicalReportModal(BuildContext context) {
    final reportText = CycleCalculator.generateMedicalReport(
      periodStartDates: periodStartDates,
      dailyLogs: dailyLogs,
      analytics: analytics,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Riepilogo per visita medica',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2520),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Copia questo riepilogo per incollarlo nelle note o inviarlo al tuo medico.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6E6259)),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6DDD3)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    reportText,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2C2520),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: reportText));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report medico copiato negli appunti'),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97757),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text(
                  'Copia report completo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentCycles = analytics.completedCycles.take(6).toList().reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Metriche principali
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Durata media ciclo',
                  value: '${analytics.effectiveCycleLength} gg',
                  subtitle: analytics.isUsingAutoCycleLength
                      ? 'Calcolata sullo storico'
                      : 'Impostazione manuale',
                  accentColor: const Color(0xFFD97757),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'Regolarità',
                  value: analytics.regularityStatus,
                  subtitle: analytics.completedCycles.length >= 2
                      ? 'Range ${analytics.minCycleLength}-${analytics.maxCycleLength} gg'
                      : 'Flusso medio: ${analytics.effectivePeriodDuration} gg',
                  accentColor: const Color(0xFF8AB17D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Grafico andamento ultimi cicli
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
                const Text(
                  'Andamento durata cicli',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2520),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recentCycles.isEmpty
                      ? 'Registra almeno 2 cicli nello storico per visualizzare il grafico.'
                      : 'Ultimi ${recentCycles.length} cicli conclusi (in giorni)',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6E6259)),
                ),
                if (recentCycles.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: recentCycles.map((cycle) {
                        final ratio = (cycle.lengthDays / 42).clamp(0.25, 1.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${cycle.lengthDays}g',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2520),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 28,
                              height: 95 * ratio,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97757)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CycleCalculator.formatShortDateIt(
                                  cycle.startDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6E6259),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Correlazioni e sintomi ricorrenti
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
                const Text(
                  'Correlazioni e sintomi ricorrenti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2520),
                  ),
                ),
                const SizedBox(height: 12),
                if (analytics.topSymptoms.isEmpty)
                  const Text(
                    'Registra i tuoi sintomi nella schermata Oggi o nel Calendario per scoprire i pattern ricorrenti.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6E6259)),
                  )
                else ...[
                  if (analytics.phaseCorrelations.isNotEmpty) ...[
                    ...analytics.phaseCorrelations.map(
                          (insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 18, color: Color(0xFFD4A373)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                insight,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2C2520),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: analytics.topSymptoms.take(6).map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6DDD3)),
                        ),
                        child: Text(
                          '${entry.key} (${entry.value})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C2520),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Report per visita medica
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
                const Text(
                  'Esporta per visita ginecologica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2520),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Genera un riepilogo ordinato con le date degli ultimi cicli, durata media, sintomi frequenti e farmaci assunti.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E6259),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openMedicalReportModal(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97757),
                      side: const BorderSide(color: Color(0xFFD97757)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.medical_information_outlined),
                    label: const Text(
                      'Visualizza e copia report medico',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6259),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}