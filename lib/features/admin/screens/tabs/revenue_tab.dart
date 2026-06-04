import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/admin/widgets/revenue_hero.dart';
import 'package:ptbooking/features/admin/widgets/revenue_metrics.dart';
import 'package:ptbooking/features/admin/widgets/revenue_packages.dart';
import 'package:ptbooking/features/admin/widgets/revenue_recent.dart';

class RevenueTab extends StatelessWidget {
  const RevenueTab({super.key});

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isSameMonth(DateTime? date, DateTime now) {
    return date != null && date.month == now.month && date.year == now.year;
  }

  bool _isToday(DateTime? date, DateTime now) {
    return date != null && date.day == now.day && date.month == now.month && date.year == now.year;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, bookingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('wallet_transactions').snapshots(),
          builder: (context, transactionSnapshot) {
            if (!bookingSnapshot.hasData || !transactionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final now = DateTime.now();
            final bookings = bookingSnapshot.data!.docs;
            final transactions = transactionSnapshot.data!.docs;
            final paidBookings = bookings.where((doc) => doc.data()['payment_status'] == 'paid').toList();
            final heldBookings = bookings.where((doc) => doc.data()['payment_status'] == 'held').toList();

            final totalRevenue = paidBookings.fold<int>(
              0,
              (total, doc) => total + _toInt(doc.data()['payment_amount']),
            );
            final heldRevenue = heldBookings.fold<int>(0, (total, doc) => total + _toInt(doc.data()['payment_amount']));
            final monthRevenue = paidBookings.fold<int>(0, (total, doc) {
              final date = _toDate(doc.data()['payment_updated_at']) ?? _toDate(doc.data()['created_at']);
              return _isSameMonth(date, now) ? total + _toInt(doc.data()['payment_amount']) : total;
            });
            final todayRevenue = paidBookings.fold<int>(0, (total, doc) {
              final date = _toDate(doc.data()['payment_updated_at']) ?? _toDate(doc.data()['created_at']);
              return _isToday(date, now) ? total + _toInt(doc.data()['payment_amount']) : total;
            });

            final totalDeposits = transactions
                .where((doc) => doc.data()['type'] == 'deposit' && doc.data()['status'] == 'confirmed')
                .fold<int>(0, (total, doc) => total + _toInt(doc.data()['amount']));
            final totalRefunds = transactions
                .where((doc) => doc.data()['type'] == 'booking_refund' && doc.data()['status'] == 'confirmed')
                .fold<int>(0, (total, doc) => total + _toInt(doc.data()['amount']));
            final pendingBookings = bookings.where((doc) => doc.data()['status'] == 'pending').length;
            final averageOrder = paidBookings.isEmpty ? 0 : totalRevenue ~/ paidBookings.length;
            final uniqueCustomers = paidBookings
                .map((doc) => doc.data()['user_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet()
                .length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                RevenueHero(
                  totalRevenue: totalRevenue,
                  monthRevenue: monthRevenue,
                  todayRevenue: todayRevenue,
                  paidCount: paidBookings.length,
                ),
                const SizedBox(height: 14),
                RevenueMetrics(
                  heldRevenue: heldRevenue,
                  totalDeposits: totalDeposits,
                  totalRefunds: totalRefunds,
                  averageOrder: averageOrder,
                  uniqueCustomers: uniqueCustomers,
                  pendingBookings: pendingBookings,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Doanh thu theo gói'),
                      RevenuePackages(paidBookings: paidBookings, totalRevenue: totalRevenue),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Giao dịch doanh thu gần đây'),
                      RevenueRecent(paidBookings: paidBookings),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ghi chú: tiền nạp ví là dòng tiền vào ví khách hàng, chỉ tính doanh thu khi booking được PT chấp nhận và trạng thái thanh toán là paid.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.35),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
