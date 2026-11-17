import 'package:flutter/material.dart';
import '../models/cycle_models.dart';

class DailyLogEditor extends StatefulWidget {
  final DateTime date;
  final DailyLog log;
  final ValueChanged<DailyLog> onChanged;

  const DailyLogEditor({
    super.key,
    required this.date,
    required this.log,
    required this.onChanged,
  });

  @override
  State<DailyLogEditor> createState() => _DailyLogEditorState();
}

class _DailyLogEditorState extends State<DailyLogEditor> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.log.note);
  }

  @override
  void didUpdateWidget(covariant DailyLogEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (CycleCalculator.dateKey(oldWidget.date) !=
        CycleCalculator.dateKey(widget.date) ||
        oldWidget.log.note != widget.log.note) {
      if (_noteController.text != widget.log.note) {
        _noteController.text = widget.log.note;
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String symptom) {
    final updated = Set<String>.from(widget.log.symptoms);
    if (updated.contains(symptom)) {
      updated.remove(symptom);
    } else {
      updated.add(symptom);
    }
    widget.onChanged(widget.log.copyWith(symptoms: updated));
  }

  void _toggleMedication(String med) {
    final updated = Set<String>.from(widget.log.medications);
    if (updated.contains(med)) {
      updated.remove(med);
    } else {
      updated.add(med);
    }
    widget.onChanged(widget.log.copyWith(medications: updated));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6DDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Intensità Flusso
          const Text(
            'Intensità del flusso',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CycleCalculator.availableFlowLevels.map((level) {
              final isSelected = widget.log.flowIntensity == level;
              return ChoiceChip(
                label: Text(level),
                selected: isSelected,
                onSelected: (_) {
                  widget.onChanged(
                    widget.log.copyWith(
                      flowIntensity: level,
                      clearFlow: isSelected,
                    ),
                  );
                },
                backgroundColor: const Color(0xFFFAF7F2),
                selectedColor: const Color(0xFFD97757).withValues(alpha: 0.22),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFFD97757)
                      : const Color(0xFF2C2520),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
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

          const SizedBox(height: 20),

          // 2. Umore & Energia (1-5)
          Row(
            children: [
              Expanded(
                child: _buildScaleSelector(
                  title: 'Umore',
                  currentValue: widget.log.mood,
                  activeColor: const Color(0xFFD4A373),
                  icons: const [
                    Icons.sentiment_very_dissatisfied_rounded,
                    Icons.sentiment_dissatisfied_rounded,
                    Icons.sentiment_neutral_rounded,
                    Icons.sentiment_satisfied_rounded,
                    Icons.sentiment_very_satisfied_rounded,
                  ],
                  onSelect: (val) {
                    final isSame = widget.log.mood == val;
                    widget.onChanged(
                      widget.log.copyWith(mood: val, clearMood: isSame),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildScaleSelector(
                  title: 'Energia',
                  currentValue: widget.log.energy,
                  activeColor: const Color(0xFF8AB17D),
                  icons: const [
                    Icons.battery_1_bar_rounded,
                    Icons.battery_2_bar_rounded,
                    Icons.battery_4_bar_rounded,
                    Icons.battery_5_bar_rounded,
                    Icons.battery_full_rounded,
                  ],
                  onSelect: (val) {
                    final isSame = widget.log.energy == val;
                    widget.onChanged(
                      widget.log.copyWith(energy: val, clearEnergy: isSame),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Sintomi
          const Text(
            'Sintomi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CycleCalculator.availableSymptoms.map((symptom) {
              final isSelected = widget.log.symptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (_) => _toggleSymptom(symptom),
                backgroundColor: const Color(0xFFFAF7F2),
                selectedColor: const Color(0xFFD97757).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFD97757),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? const Color(0xFFD97757)
                      : const Color(0xFF2C2520),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
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

          const SizedBox(height: 20),

          // 4. Farmaci e Integratori
          const Text(
            'Farmaci e integratori',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CycleCalculator.availableMedications.map((med) {
              final isSelected = widget.log.medications.contains(med);
              return FilterChip(
                label: Text(med),
                selected: isSelected,
                onSelected: (_) => _toggleMedication(med),
                backgroundColor: const Color(0xFFFAF7F2),
                selectedColor: const Color(0xFF9C89B8).withValues(alpha: 0.22),
                checkmarkColor: const Color(0xFF9C89B8),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? const Color(0xFF6B5887)
                      : const Color(0xFF2C2520),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF9C89B8)
                        : const Color(0xFFE6DDD3),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 5. Note libere
          const Text(
            'Note personali',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2520),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Es. viaggio, sonno scarso, stress, allenamento...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9A8E85)),
              filled: true,
              fillColor: const Color(0xFFFAF7F2),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6DDD3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6DDD3)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFFD97757)),
                tooltip: 'Salva nota',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onChanged(
                    widget.log.copyWith(note: _noteController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nota salvata'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            onSubmitted: (val) {
              widget.onChanged(widget.log.copyWith(note: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScaleSelector({
    required String title,
    required int? currentValue,
    required Color activeColor,
    required List<IconData> icons,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2520),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = currentValue == level;
            return GestureDetector(
              onTap: () => onSelect(level),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.22)
                      : const Color(0xFFFAF7F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                    isSelected ? activeColor : const Color(0xFFE6DDD3),
                  ),
                ),
                child: Icon(
                  icons[index],
                  size: 20,
                  color: isSelected ? activeColor : const Color(0xFF8A7E75),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}