import 'package:flutter/material.dart';

class ProgressSummary extends StatelessWidget {
  final double computedScore;
  final String rank;
  final Color rankColor;

  const ProgressSummary({
    super.key,
    required this.computedScore,
    required this.rank,
    required this.rankColor,
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.12),
              border: Border.all(color: rankColor, width: 3),
            ),
            child: Center(
              child: Text(
                computedScore.toStringAsFixed(1),
                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Điểm tổng quan tuần này", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  rank,
                  style: TextStyle(color: rankColor, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: computedScore / 10,
                    minHeight: 9,
                    backgroundColor: Colors.grey[200],
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
