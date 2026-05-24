import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/wallet_service.dart';

class BookingListTab extends StatelessWidget {
  const BookingListTab({super.key});

  static final WalletService _walletService = WalletService();

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  Widget _buildStatus(String status) {
    Color color = Colors.grey;
    String text = status;

    if (status == 'pending') {
      color = Colors.orange;
      text = 'Chờ PT duyệt';
    } else if (status == 'confirmed') {
      color = Colors.green;
      text = 'Đã chốt';
    } else if (status == 'canceled') {
      color = Colors.red;
      text = 'Đã hủy';
    }

    return _badge(text, color);
  }

  Widget _buildPaymentStatus(String status) {
    Color color = Colors.grey;
    String text = 'Chưa trừ ví';

    if (status == 'held') {
      color = Colors.blue;
      text = 'Đã giữ ví';
    } else if (status == 'paid') {
      color = Colors.green;
      text = 'Đã quyết toán';
    } else if (status == 'refunded_to_wallet') {
      color = Colors.teal;
      text = 'Đã hoàn ví';
    }

    return _badge(text, color);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Future<void> _confirmDeposit(BuildContext context, String transactionId) async {
    try {
      await _walletService.confirmDeposit(transactionId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xác nhận nạp ví.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildDepositRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _walletService.watchDepositRequests(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? []).where((doc) => doc.data()['status'] == 'pending').toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                'Yêu cầu nạp ví',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2937)),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data();
              final amount = _toInt(data['amount']);

              return Card(
                color: const Color(0xFFFFFBEB),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEDD5),
                    child: Icon(Icons.account_balance_wallet, color: Color(0xFFF97316)),
                  ),
                  title: Text(data['user_name']?.toString() ?? 'Học viên'),
                  subtitle: Text('Muốn nạp: ${_formatCurrency(amount)}'),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmDeposit(context, doc.id),
                    child: const Text('Xác nhận'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildDepositRequests(),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Chưa có lịch đặt nào.')),
              )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final paymentStatus = data['payment_status']?.toString() ?? 'unpaid';
                final amount = _toInt(data['payment_amount']);

                return Card(
                  child: ListTile(
                    title: Text(
                      'HV: ${data['user_name'] ?? 'Học viên'} -> PT: ${data['pt_name'] ?? 'HLV'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày tập: ${data['booking_date']} | Khung giờ: ${data['time_slot']}'),
                        if ((data['package_name'] ?? '').toString().isNotEmpty)
                          Text('Gói: ${data['package_name']} (${data['session_count'] ?? 1} buổi)'),
                        if (amount > 0) Text('Số tiền: ${_formatCurrency(amount)}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [_buildStatus(data['status'] ?? 'pending'), _buildPaymentStatus(paymentStatus)],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
