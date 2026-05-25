import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final BookingModel booking;

  const PaymentScreen({super.key, required this.bookingId, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookingService = BookingService();
  bool _isSubmitting = false;

  static const String bankName = 'Vietcombank';
  static const String accountNumber = '0123456789';
  static const String accountName = 'PTBOOKING';

  String get _amountText {
    final amount = widget.booking.paymentAmount;
    if (amount <= 0) return 'Liên hệ admin';
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  String get _transferContent => 'PTB ${widget.bookingId.substring(0, 6).toUpperCase()} ${widget.booking.userName}';

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _markTransferred() async {
    setState(() => _isSubmitting = true);

    try {
      await _bookingService.updatePaymentStatus(widget.bookingId, 'waiting_confirm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu xác nhận thanh toán. Vui lòng chờ admin duyệt.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    const primaryColor = Color(0xFF0B2447);
    const accentColor = Color(0xFF4BA3E3);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Thanh toán đặt lịch')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                  'Thông tin lịch tập',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 14),
                _buildInfoRow('PT', widget.booking.ptName),
                _buildInfoRow('Ngày', '${widget.booking.bookingDate} - ${widget.booking.timeSlot}'),
                _buildInfoRow('Gói', '${widget.booking.packageName} (${widget.booking.sessionCount} buổi)'),
                _buildInfoRow('Số tiền', _amountText),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7EA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.45)),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 130, color: primaryColor),
                ),
                const SizedBox(height: 18),
                _buildInfoRow('Ngân hàng', bankName),
                _buildInfoRow('Số tài khoản', accountNumber),
                _buildInfoRow('Chủ tài khoản', accountName),
                _buildInfoRow('Nội dung CK', _transferContent),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(accountNumber, 'Đã copy số tài khoản'),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy STK'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(_transferContent, 'Đã copy nội dung chuyển khoản'),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy nội dung'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _markTransferred,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'TÔI ĐÃ CHUYỂN KHOẢN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sau khi admin xác nhận thanh toán, yêu cầu đặt lịch sẽ được gửi sang PT để duyệt.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B2447)),
            ),
          ),
        ],
      ),
    );
  }
}
