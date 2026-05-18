import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // copy clipboard
import 'package:qr_flutter/qr_flutter.dart'; // tạo QR VietQR

import '../models/pt_model.dart';

class PaymentScreen extends StatefulWidget {
  final PT pt;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.pt,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedBank;
  bool _isProcessing = false;

  // Danh sách ngân hàng phổ biến (thêm icon nếu có asset)
  final List<Map<String, dynamic>> _banks = [
    {'id': 'vcb', 'name': 'Vietcombank', 'color': Colors.blue[800]},
    {'id': 'bidv', 'name': 'BIDV', 'color': Colors.red[800]},
    {'id': 'vtb', 'name': 'VietinBank', 'color': Colors.green[800]},
    {'id': 'acb', 'name': 'ACB', 'color': Colors.orange[800]},
    {'id': 'tpb', 'name': 'TPBank', 'color': Colors.purple[800]},
    {'id': 'mb', 'name': 'MBBank', 'color': Colors.teal[800]},
    {'id': 'techcom', 'name': 'Techcombank', 'color': Colors.blueGrey[800]},
    {'id': 'vpbank', 'name': 'VPBank', 'color': Colors.indigo[800]},
  ];

  // Thông tin tài khoản nhận tiền - THAY BẰNG THÔNG TIN THẬT CỦA BẠN
  final String accountNumber = "0123456789";
  final String accountName = "CÔNG TY TNHH PT BOOKING";
  final String bankName = "Vietcombank - Chi nhánh Đồng Nai";

  int get amount => widget.pt.price; // giá mỗi buổi, có thể nhân số buổi sau

  String get transferContent => "THUEPT${widget.pt.name.replaceAll(' ', '')}${DateTime.now().millisecondsSinceEpoch}";

  get accountNumber520400005303986540 => null;

  get transferContent6304XXXX => null;

  Future<void> _confirmPayment() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ngân hàng"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1)); // giả lập

    setState(() => _isProcessing = false);

    // Tạo booking với trạng thái chờ xác nhận thanh toán
    widget.onPaymentSuccess();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Yêu cầu thuê PT đã được gửi! Chờ admin xác nhận thanh toán."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF6B6B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán chuyển khoản"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin PT
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: widget.pt.avatar.isNotEmpty ? NetworkImage(widget.pt.avatar) : null,
                      child: widget.pt.avatar.isEmpty ? const Icon(Icons.fitness_center, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pt.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(widget.pt.specialty, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text("${widget.pt.experience ?? 0} năm kinh nghiệm"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tóm tắt số tiền
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Số tiền cần thanh toán", style: TextStyle(fontSize: 16)),
                        Text(
                          "${amount ~/ 1000}k",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Phí chuyển khoản"),
                        Text("0đ"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Danh sách ngân hàng
            const Text("Chọn ngân hàng để chuyển khoản", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: _banks.map((bank) {
                  final isSelected = _selectedBank == bank['id'];
                  return ListTile(
                    leading: Icon(Icons.account_balance, color: bank['color'], size: 32),
                    title: Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFFFF6B6B), size: 28)
                        : null,
                    onTap: () {
                      setState(() => _selectedBank = bank['id']);
                    },
                    selected: isSelected,
                    selectedTileColor: primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ),

            // Thông tin chuyển khoản + QR (chỉ hiện khi đã chọn ngân hàng)
            if (_selectedBank != null) ...[
              const SizedBox(height: 32),
              const Text("Thông tin chuyển khoản", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // QR VietQR (dữ liệu mẫu - bạn có thể dùng API tạo QR chính xác hơn)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: "00020101021238540010A000000727012900097704030112$accountNumber520400005303986540${amount}5802VN62070803$transferContent6304XXXX",
                          version: QrVersions.auto,
                          size: 220.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow("Ngân hàng nhận", bankName),
                      _buildInfoRow("Số tài khoản", accountNumber),
                      _buildInfoRow("Chủ tài khoản", accountName),
                      _buildInfoRow("Số tiền", "${amount ~/ 1000}k"),
                      _buildInfoRow("Nội dung chuyển khoản", transferContent),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: accountNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Đã copy số tài khoản")),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text("Copy STK"),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: transferContent));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Đã copy nội dung CK")),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text("Copy nội dung"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Nút xác nhận đã thanh toán
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (_selectedBank == null || _isProcessing) ? null : _confirmPayment,
                icon: const Icon(Icons.check_circle_outline),
                label: _isProcessing
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text("Tôi đã thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Sau khi chuyển khoản thành công, bấm nút trên để admin xác nhận nhanh chóng",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}