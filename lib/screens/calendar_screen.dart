import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/cycle_models.dart';

class CalendarScreen extends StatefulWidget {
  final List<DateTime> periodStartDates;
  final Map<String, Set<String>> dailySymptoms;
  final int averageCycleLength;
  final int averagePeriodDuration;
  final List<String> availableSymptoms;
  final void Function(DateTime date, String symptom) onToggleSymptom;

  const CalendarScreen({
    super.key,
    required this.periodStartDates,
    required this.dailySymptoms,
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.availableSymptoms,
    required this.onToggleSymptom,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = CycleCalculator.normalizeDate(DateTime.now());
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final lastStart = widget.periodStartDates.first;
    final selectedKey = CycleCalculator.dateKey(_selectedDay);
    final selectedSymptoms = widget.dailySymptoms[selectedKey] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6DDD3)),
            ),
            child: TableCalendar<String>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = CycleCalculator.normalizeDate(selectedDay);
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                final key = CycleCalculator.dateKey(day);
                return widget.dailySymptoms[key]?.toList() ?? [];
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2520),
                ),
              ),
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Color(0xFF2C2520),
                  shape: BoxShape.circle,
                ),
                markerSize: 5,
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, lastStart, isSelected: false),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, lastStart, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, lastStart, isSelected: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(const Color(0xFFD97757), 'Ciclo'),
              _legendItem(
                const Color(0xFFD97757).withValues(alpha: 0.25),
                'Previsto',
              ),
              _legendItem(
                const Color(0xFF8AB17D).withValues(alpha: 0.35),
                'Finestra fertile',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sintomi del ${CycleCalculator.formatDateIt(_selectedDay)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableSymptoms.map((symptom) {
              final isSelected = selectedSymptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (_) => widget.onToggleSymptom(_selectedDay, symptom),
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

  Widget _buildDayCell(
      DateTime day,
      DateTime lastStart, {
        bool isSelected = false,
        bool isToday = false,
      }) {
    final isPeriod = CycleCalculator.isPeriodDay(
      day,
      widget.periodStartDates,
      widget.averagePeriodDuration,
    );
    final isPredicted = !isPeriod &&
        CycleCalculator.isPredictedPeriodDay(
          day,
          lastStart,
          widget.averageCycleLength,
          widget.averagePeriodDuration,
        );
    final isFertile = !isPeriod &&
        !isPredicted &&
        CycleCalculator.isFertileDay(
          day,
          lastStart,
          widget.averageCycleLength,
        );

    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF2C2520);

    if (isPeriod) {
      bgColor = const Color(0xFFD97757);
      textColor = Colors.white;
    } else if (isPredicted) {
      bgColor = const Color(0xFFD97757).withValues(alpha: 0.22);
    } else if (isFertile) {
      bgColor = const Color(0xFF8AB17D).withValues(alpha: 0.30);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: const Color(0xFF2C2520), width: 2)
            : isToday
            ? Border.all(color: const Color(0xFFD97757), width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight:
          (isPeriod || isSelected || isToday) ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5A4F47)),
        ),
      ],
    );
  }
}