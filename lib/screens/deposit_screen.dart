import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/notification_service.dart';

class DepositScreen extends StatefulWidget {
  final int amount;
  final String method; // 'Bank' or 'Momo'
  final String userId;
  final String userName;

  const DepositScreen({
    Key? key,
    required this.amount,
    required this.method,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final WalletService _walletService = WalletService();
  bool _isSubmitting = false;

  String get _qrUrl {
    if (widget.method == 'Bank') {
      return 'https://img.vietqr.io/image/MB-1234567890-compact.png?amount=${widget.amount}&addInfo=NAPPTB_${widget.userId.substring(0, 6).toUpperCase()}&accountName=PT%20BOOKING%20DEMO';
    } else {
      return 'https://dummyimage.com/200x200/00ff00/000000&text=NEW+MOMO+${widget.amount}';
    }
  }

  Future<void> _processDeposit() async {
    setState(() => _isSubmitting = true);
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Dialog(

              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFFA515))),
                    SizedBox(width: 20),
                    Text('Đang xác nhận giao dịch...'),
                  ],
                ),
              ),
            ));
    try {
      await _walletService.requestDeposit(
          userId: widget.userId,
          userName: widget.userName,
          amount: widget.amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nạp tiền vào ví thành công!'),
            backgroundColor: Colors.green));
        SimulationNotificationService.showNotification(
            context,
            'Tài khoản vừa được cộng +${widget.amount}đ từ ${widget.method}.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
      Navigator.of(context).pop(); // close the loading dialog
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18253E),
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF18253E);
    const accentColor = Color(0xFFFFA515);
    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán ${widget.method}'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quét mã ${widget.method} để chuyển khoản',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 6),
            const Text(
              'Sử dụng ứng dụng để quét mã dưới đây',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                 child: widget.method == 'Momo'
                      ? Image.asset('assets/images/momo.jpg',
                         width: 200,
                         height: 200,
                         fit: BoxFit.contain)
                      : Image.network(
                          _qrUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain),
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
                  _infoRow('Phương thức', widget.method),
                  const Divider(),
                  _infoRow('Số tài khoản', widget.method == 'Bank' ? '1234567890' : '0987654321'),
                  const Divider(),
                  _infoRow('Tên tài khoản', widget.method == 'Bank' ? 'PT BOOKING DEMO' : 'PT BOOKING MOMO'),
                  const Divider(),
                  _infoRow('Số tiền', '${widget.amount}\u0111'),
                  const Divider(),
                  _infoRow('Nội dung CK', 'NAPPTB_${widget.userId.substring(0, 6).toUpperCase()}'),
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
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: _isSubmitting ? null : _processDeposit,
                    child: Text(_isSubmitting ? 'Đang gửi...' : 'Tôi đã chuyển tiền'),
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
