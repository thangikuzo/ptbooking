import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

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

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa rõ';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isSameMonth(DateTime? date, DateTime now) {
    return date != null && date.month == now.month && date.year == now.year;
  }

  bool _isToday(DateTime? date, DateTime now) {
    return date != null && date.day == now.day && date.month == now.month && date.year == now.year;
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _metricGrid(List<Widget> children) {
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
          children: children,
        );
      },
    );
  }

  Widget _revenueHero({
    required int totalRevenue,
    required int monthRevenue,
    required int todayRevenue,
    required int paidCount,
  }) {
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

  Widget _packageBreakdown(List<QueryDocumentSnapshot<Map<String, dynamic>>> paidBookings, int totalRevenue) {
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

  Widget _recentRevenue(List<QueryDocumentSnapshot<Map<String, dynamic>>> paidBookings) {
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
                _revenueHero(
                  totalRevenue: totalRevenue,
                  monthRevenue: monthRevenue,
                  todayRevenue: todayRevenue,
                  paidCount: paidBookings.length,
                ),
                const SizedBox(height: 14),
                _metricGrid([
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
                ]),
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
                    children: [_sectionTitle('Doanh thu theo gói'), _packageBreakdown(paidBookings, totalRevenue)],
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
                    children: [_sectionTitle('Giao dịch doanh thu gần đây'), _recentRevenue(paidBookings)],
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
