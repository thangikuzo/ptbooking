import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // copy clipboard
import 'package:qr_flutter/qr_flutter.dart'; // tạo QR VietQR

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

  // Danh sách ngân hàng phổ biến (bạn có thể thêm icon thật sau)
  final List<Map<String, dynamic>> _banks = [
    {'id': 'vcb', 'name': 'Vietcombank', 'code': 'VCB', 'color': Colors.blue[800]},
    {'id': 'bidv', 'name': 'BIDV', 'code': 'BIDV', 'color': Colors.red[800]},
    {'id': 'vtb', 'name': 'VietinBank', 'code': 'VTB', 'color': Colors.green[800]},
    {'id': 'acb', 'name': 'ACB', 'code': 'ACB', 'color': Colors.orange[800]},
    {'id': 'tpb', 'name': 'TPBank', 'code': 'TPB', 'color': Colors.purple[800]},
    {'id': 'mb', 'name': 'MBBank', 'code': 'MB', 'color': Colors.teal[800]},
  ];

  // Thông tin tài khoản nhận tiền (THAY BẰNG THÔNG TIN THẬT CỦA BẠN)
  final String accountNumber = "0123456789";
  final String accountName = "NGUYEN VAN A";
  final String bankName = "Vietcombank";
  int get amount => widget.pt.price; // hoặc tính thêm phí nếu cần

  String get transferContent => "THUE PT ${widget.pt.name} ${DateTime.now().millisecondsSinceEpoch}";

  Future<void> _confirmPayment() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ngân hàng"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2)); // Giả lập chờ

    setState(() => _isProcessing = false);

    // Tạo booking với trạng thái chờ xác nhận thanh toán
    widget.onPaymentSuccess();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã gửi yêu cầu thuê PT! Chờ admin xác nhận thanh toán."),
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
        title: const Text("Thanh toán ngân hàng"),
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
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
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

            // Chọn ngân hàng
            const Text("Chọn ngân hàng chuyển khoản", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: _banks.map((bank) {
                  final selected = _selectedBank == bank['id'];
                  return ListTile(
                    leading: Icon(Icons.account_balance, color: bank['color'], size: 32),
                    title: Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFFFF6B6B), size: 28) : null,
                    onTap: () {
                      setState(() => _selectedBank = bank['id']);
                    },
                    selected: selected,
                    selectedTileColor: primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ),

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
                      // QR VietQR (dữ liệu mẫu, bạn có thể dùng API tạo QR thật)
                      QrImageView(
                        data: "00020101021238540010A000000727012900097704030112$accountNumber520400005303986540${amount}5802VN62070803$transferContent6304XXXX",
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow("Ngân hàng nhận", bankName),
                      _buildInfoRow("Số tài khoản", accountNumber),
                      _buildInfoRow("Chủ tài khoản", accountName),
                      _buildInfoRow("Số tiền", "${amount ~/ 1000}k"),
                      _buildInfoRow("Nội dung CK", transferContent),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: accountNumber));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã copy số tài khoản")));
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text("Copy STK"),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: transferContent));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã copy nội dung")));
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
              child: ElevatedButton(
                onPressed: (_selectedBank == null || _isProcessing) ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text("Tôi đã thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Sau khi chuyển khoản, bấm nút trên để admin xác nhận nhanh chóng",
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