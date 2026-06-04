import 'package:flutter/material.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class BankPaymentView extends StatelessWidget {
  final int amount;
  final String transferCode;
  final String bankQrUrl;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BankPaymentView({
    super.key,
    required this.amount,
    required this.transferCode,
    required this.bankQrUrl,
    required this.isSubmitting,
    required this.onConfirm,
    required this.onCancel,
  });

  String _formatCurrency(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? AppColors.primaryDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryDark;
    const accentColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh toán VietQR'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quét mã ngân hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sử dụng ứng dụng ngân hàng để quét mã dưới đây',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Image.network(bankQrUrl, width: 210, height: 210, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _infoRow('Phương thức', 'VietQR'),
                  const Divider(height: 1),
                  _infoRow('Số tài khoản', '1234567890'),
                  const Divider(height: 1),
                  _infoRow('Tên tài khoản', 'PT BOOKING DEMO'),
                  const Divider(height: 1),
                  _infoRow('Số tiền', _formatCurrency(amount)),
                  const Divider(height: 1),
                  _infoRow('Nội dung CK', transferCode),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onCancel,
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting ? null : onConfirm,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Tôi đã chuyển tiền'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
