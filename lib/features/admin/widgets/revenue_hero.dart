import 'package:flutter/material.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class RevenueHero extends StatelessWidget {
  final int totalRevenue;
  final int monthRevenue;
  final int todayRevenue;
  final int paidCount;

  const RevenueHero({
    super.key,
    required this.totalRevenue,
    required this.monthRevenue,
    required this.todayRevenue,
    required this.paidCount,
  });

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  Widget _heroMiniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu thực nhận',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(totalRevenue),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _heroMiniMetric('Tháng này', _formatCurrency(monthRevenue))),
              const SizedBox(width: 10),
              Expanded(child: _heroMiniMetric('Hôm nay', _formatCurrency(todayRevenue))),
              const SizedBox(width: 10),
              Expanded(child: _heroMiniMetric('Lịch đã chốt', '$paidCount')),
            ],
          ),
        ],
      ),
    );
  }
}
