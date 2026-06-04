import 'package:flutter/material.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class RevenueMetrics extends StatelessWidget {
  final int heldRevenue;
  final int totalDeposits;
  final int totalRefunds;
  final int averageOrder;
  final int uniqueCustomers;
  final int pendingBookings;

  const RevenueMetrics({
    super.key,
    required this.heldRevenue,
    required this.totalDeposits,
    required this.totalRefunds,
    required this.averageOrder,
    required this.uniqueCustomers,
    required this.pendingBookings,
  });

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  Widget _summaryCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.75 : 1.6,
          children: [
            _summaryCard(
              label: 'Tiền đang giữ',
              value: _formatCurrency(heldRevenue),
              icon: Icons.lock_clock_outlined,
              color: AppColors.warning,
            ),
            _summaryCard(
              label: 'Tiền nạp ví',
              value: _formatCurrency(totalDeposits),
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
            ),
            _summaryCard(
              label: 'Đã hoàn ví',
              value: _formatCurrency(totalRefunds),
              icon: Icons.replay_circle_filled_outlined,
              color: AppColors.success,
            ),
            _summaryCard(
              label: 'Giá trị TB',
              value: _formatCurrency(averageOrder),
              icon: Icons.trending_up,
              color: AppColors.accent,
            ),
            _summaryCard(
              label: 'Khách đã trả',
              value: '$uniqueCustomers',
              icon: Icons.group_outlined,
              color: AppColors.primaryDark,
            ),
            _summaryCard(
              label: 'Chờ PT duyệt',
              value: '$pendingBookings',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }
}
