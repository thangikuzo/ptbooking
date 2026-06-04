import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class RevenueRecent extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> paidBookings;

  const RevenueRecent({
    super.key,
    required this.paidBookings,
  });

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa rõ';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final recent = paidBookings.toList()
      ..sort((a, b) {
        final aDate = _toDate(a.data()['payment_updated_at']) ?? _toDate(a.data()['created_at']) ?? DateTime(1970);
        final bDate = _toDate(b.data()['payment_updated_at']) ?? _toDate(b.data()['created_at']) ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final items = recent.take(6).toList();
    if (items.isEmpty) {
      return const Text('Chưa có giao dịch doanh thu.', style: TextStyle(color: AppColors.mutedText));
    }

    return Column(
      children: items.map((doc) {
        final data = doc.data();
        final date = _toDate(data['payment_updated_at']) ?? _toDate(data['created_at']);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.payments_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['package_name']?.toString().isNotEmpty == true ? data['package_name'].toString() : 'Gói tập',
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data['user_name'] ?? 'Học viên'} -> ${data['pt_name'] ?? 'PT'} · ${_formatDate(date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatCurrency(_toInt(data['payment_amount'])),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
