import 'package:flutter/material.dart';

class PTScheduleSection extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedDay;
  final String? selectedTimeSlot;
  final List<String> availableTimeSlots;
  final bool isLoadingSlots;
  final Map<String, String> dayLabels;
  final VoidCallback onSelectDate;
  final ValueChanged<String> onTimeSlotSelected;
  final Color primaryColor;
  final Color accentColor;

  const PTScheduleSection({
    super.key,
    required this.selectedDate,
    required this.selectedDay,
    required this.selectedTimeSlot,
    required this.availableTimeSlots,
    required this.isLoadingSlots,
    required this.dayLabels,
    required this.onSelectDate,
    required this.onTimeSlotSelected,
    required this.primaryColor,
    required this.accentColor,
  });

  Widget _buildTimeSlotPicker() {
    if (selectedDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: accentColor),
            const SizedBox(width: 12),
            const Expanded(child: Text("Chọn ngày trước để xem các khung giờ còn trống.")),
          ],
        ),
      );
    }

    if (isLoadingSlots) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
            const SizedBox(width: 12),
            Text("Đang tải giờ trống...", style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (availableTimeSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: accentColor),
            const SizedBox(width: 12),
            const Expanded(child: Text("PT chưa mở giờ trống hoặc các khung giờ ngày này đã được đặt.")),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Chọn giờ tập",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: availableTimeSlots.map((slot) {
            final isSelected = selectedTimeSlot == slot;

            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: accentColor.withOpacity(0.18),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? accentColor : Colors.grey.shade300),
              onSelected: (_) {
                onTimeSlotSelected(slot);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onSelectDate,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedDate == null ? Colors.grey.shade200 : accentColor,
                width: selectedDate == null ? 1 : 1.5,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: accentColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ngày bắt đầu tập",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDate == null
                            ? "Bấm để chọn ngày kích hoạt"
                            : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year} (${dayLabels[selectedDay]})",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTimeSlotPicker(),
      ],
    );
  }
}
