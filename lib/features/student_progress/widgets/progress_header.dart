import 'package:flutter/material.dart';

class ProgressHeader extends StatelessWidget {
  final String studentName;
  final Color primaryColor;

  const ProgressHeader({
    super.key,
    required this.studentName,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bảng đánh giá tiến độ", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
