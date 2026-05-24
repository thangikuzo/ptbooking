import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _walletService.ensureWallet(user.uid);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _requestDeposit([int? quickAmount]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = quickAmount ?? int.tryParse(_amountController.text.replaceAll('.', '').trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _walletService.requestDeposit(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Học viên',
        amount: amount,
      );
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu nạp ví. Vui lòng chờ admin xác nhận.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    const primaryColor = Color(0xFF18253E);
    const accentColor = Color(0xFFFFA515);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Ví PTBooking')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _walletService.watchWallet(user.uid),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? {};
              final balance = _toInt(data['balance']);
              final heldBalance = _toInt(data['held_balance']);

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(balance),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Đang giữ cho lịch chờ duyệt: ${_formatCurrency(heldBalance)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nạp ví demo',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nhập số tiền',
                    suffixText: 'đ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [500000, 1000000, 3000000, 5000000].map((amount) {
                    return ActionChip(
                      label: Text(_formatCurrency(amount)),
                      onPressed: _isSubmitting ? null : () => _requestDeposit(amount),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _requestDeposit(),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu nạp ví'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo: admin xác nhận yêu cầu nạp trong tab Lịch đặt, tiền sẽ cộng vào ví.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lịch sử ví',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _walletService.watchUserTransactions(user.uid),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final aTime = a.data()['created_at'];
                final bTime = b.data()['created_at'];
                if (aTime is Timestamp && bTime is Timestamp) return bTime.compareTo(aTime);
                return 0;
              });

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có giao dịch ví.')),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final type = data['type']?.toString() ?? '';
                  final status = data['status']?.toString() ?? '';
                  final amount = _toInt(data['amount']);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: type == 'deposit'
                            ? Colors.green.withOpacity(0.12)
                            : accentColor.withOpacity(0.14),
                        child: Icon(
                          type == 'deposit' ? Icons.add : Icons.sync_alt,
                          color: type == 'deposit' ? Colors.green : accentColor,
                        ),
                      ),
                      title: Text(_transactionTitle(type)),
                      subtitle: Text(_transactionStatus(status)),
                      trailing: Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _transactionTitle(String type) {
    switch (type) {
      case 'deposit':
        return 'Nạp ví';
      case 'booking_hold':
        return 'Giữ tiền đặt lịch';
      case 'booking_capture':
        return 'Thanh toán lịch tập';
      case 'booking_refund':
        return 'Hoàn về ví';
      default:
        return 'Giao dịch ví';
    }
  }

  String _transactionStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ admin xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      default:
        return status;
    }
  }
}
