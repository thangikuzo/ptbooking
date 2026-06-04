import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class RevenuePackages extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> paidBookings;
  final int totalRevenue;

  const RevenuePackages({
    super.key,
    required this.paidBookings,
    required this.totalRevenue,
  });

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  @override
  Widget build(BuildContext context) {
    final packages = <String, int>{};
    for (final doc in paidBookings) {
      final data = doc.data();
      final name = (data['package_name']?.toString().isNotEmpty ?? false) ? data['package_name'].toString() : 'Gói tập';
      packages[name] = (packages[name] ?? 0) + _toInt(data['payment_amount']);
    }

    final entries = packages.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Text('Chưa có dữ liệu gói tập.', style: TextStyle(color: AppColors.mutedText));
    }

    return Column(
      children: entries.map((entry) {
        final ratio = totalRevenue <= 0 ? 0.0 : entry.value / totalRevenue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    _formatCurrency(entry.value),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.primaryLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
