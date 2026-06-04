import 'package:flutter/material.dart';

class ProgressWeekSelector extends StatelessWidget {
  final int selectedWeek;
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int?> onWeekChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const ProgressWeekSelector({
    super.key,
    required this.selectedWeek,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onWeekChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 5),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedWeek,
              decoration: const InputDecoration(labelText: "Tuần"),
              items: List.generate(5, (index) {
                final week = index + 1;
                return DropdownMenuItem(value: week, child: Text("Tuần $week"));
              }),
              onChanged: onWeekChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: "Tháng"),
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem(value: month, child: Text("Tháng $month"));
              }),
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: "Năm"),
              items: [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1].map((year) {
                return DropdownMenuItem(value: year, child: Text("$year"));
              }).toList(),
              onChanged: onYearChanged,
            ),
          ),
        ],
      ),
    );
  }
}
