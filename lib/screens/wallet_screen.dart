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

    _showMockPaymentSheet(
      context: context,
      amount: amount,
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Học viên',
    );
  }

  void _showMockPaymentSheet({
    required BuildContext context,
    required int amount,
    required String userId,
    required String userName,
  }) {
    final qrUrl = 'https://img.vietqr.io/image/MB-1234567890-compact.png?'
        'amount=$amount'
        '&addInfo=NAPPTB_${userId.substring(0, 6).toUpperCase()}'
        '&accountName=PT%20BOOKING%20DEMO';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Quét mã VietQR chuyển khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18253E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sử dụng bất kỳ app ngân hàng nào để quét mã dưới đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.network(
                    qrUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Text(
                            'Lỗi tải mã QR.\nVui lòng chuyển khoản thủ công.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Ngân hàng', 'MB Bank (Ngân hàng Quân Đội)'),
                      const Divider(),
                      _buildInfoRow('Số tài khoản', '1234567890'),
                      const Divider(),
                      _buildInfoRow('Tên tài khoản', 'PT BOOKING DEMO'),
                      const Divider(),
                      _buildInfoRow('Số tiền', _formatCurrency(amount)),
                      const Divider(),
                      _buildInfoRow(
                        'Nội dung CK',
                        'NAPPTB_${userId.substring(0, 6).toUpperCase()}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA515),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _processDepositDemo(amount, userId, userName);
                        },
                        child: const Text('Tôi đã chuyển tiền'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF18253E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processDepositDemo(int amount, String userId, String userName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA515))),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Đang quét giao dịch ngân hàng...\nVui lòng chờ trong giây lát.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.of(context).pop();
    }

    setState(() => _isSubmitting = true);

    try {
      await _walletService.requestDeposit(
        userId: userId,
        userName: userName,
        amount: amount,
      );
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nạp tiền vào ví thành công! Số dư đã được cập nhật.'),
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
