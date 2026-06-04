import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/wallet/services/wallet_service.dart';
import 'deposit_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();

  // 0 = Bank, 1 = Momo
  int _selectedMethod = 0;

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
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  int _toInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> _requestDeposit([int? quickAmount]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final amount = quickAmount ?? int.tryParse(_amountController.text.replaceAll('.', '').trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(
          amount: amount,
          method: _selectedMethod == 0 ? 'Bank' : 'Momo',
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'Học viên',
        ),
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

  // ------------------- BUILD -------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    const primaryColor = AppColors.primaryDark;
    const accentColor = AppColors.accent;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Ví PTBooking'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentColor,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Nạp tiền'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ----- Deposit Tab -----
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Wallet balance card (same as before)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _walletService.watchWallet(user.uid),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};
                    final balance = _toInt(data['balance']);
                    final heldBalance = _toInt(data['held_balance']);
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
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
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Sau khi chuyển tiền qua ngân hàng hoặc Momo, tiền sẽ được cộng tự động vào ví.',
                              style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
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
                // Deposit method selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Bank'),
                      selected: _selectedMethod == 0,
                      onSelected: (selected) {
                        setState(() => _selectedMethod = 0);
                      },
                      selectedColor: accentColor.withValues(alpha: 0.18),
                      backgroundColor: Colors.white,
                      checkmarkColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedMethod == 0 ? primaryColor : AppColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(color: _selectedMethod == 0 ? accentColor : AppColors.border),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Momo'),
                      selected: _selectedMethod == 1,
                      onSelected: (selected) {
                        setState(() => _selectedMethod = 1);
                      },
                      selectedColor: accentColor.withValues(alpha: 0.18),
                      backgroundColor: Colors.white,
                      checkmarkColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedMethod == 1 ? primaryColor : AppColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(color: _selectedMethod == 1 ? accentColor : AppColors.border),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Deposit form
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nạp tiền vào ví',
                        style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Nhập số tiền',
                          suffixText: 'đ',
                          filled: true,
                          fillColor: AppColors.background,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: accentColor, width: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [500000, 1000000, 3000000, 5000000]
                            .map(
                              (amt) => ActionChip(
                                label: Text(_formatCurrency(amt)),
                                labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                                backgroundColor: AppColors.primaryLight,
                                side: const BorderSide(color: AppColors.border),
                                onPressed: () => _requestDeposit(amt),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(height: 8),
                      Text(
                        'Sau khi bạn quét mã và chuyển tiền, hệ thống sẽ tự động xác nhận và cộng tiền vào ví của bạn.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ----- History Tab -----
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Lịch sử ví',
                  style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _walletService.watchUserTransactions(user.uid),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    docs.sort((a, b) {
                      final aTime = a.data()['created_at'];
                      final bTime = b.data()['created_at'];
                      if (aTime is Timestamp && bTime is Timestamp) {
                        return bTime.compareTo(aTime);
                      }
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
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : accentColor.withValues(alpha: 0.14),
                              child: Icon(
                                type == 'deposit' ? Icons.add : Icons.sync_alt,
                                color: type == 'deposit' ? AppColors.success : accentColor,
                              ),
                            ),
                            title: Text(_transactionTitle(type)),
                            subtitle: Text(_transactionStatus(status)),
                            trailing: Text(
                              _formatCurrency(amount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
