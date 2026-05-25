import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import '../services/wallet_service.dart';

class DepositScreen extends StatefulWidget {
  final int amount;
  final String method;
  final String userId;
  final String userName;

  const DepositScreen({
    super.key,
    required this.amount,
    required this.method,
    required this.userId,
    required this.userName,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final WalletService _walletService = WalletService();
  Timer? _momoAutoConfirmTimer;
  bool _isSubmitting = false;
  bool _momoAutoConfirmStarted = false;
  bool _momoScanDetected = false;

  bool get _isMomo => widget.method.toLowerCase() == 'momo';

  String get _transferCode => 'NAPPTB_${widget.userId.substring(0, 6).toUpperCase()}';

  String get _bankQrUrl {
    return 'https://img.vietqr.io/image/MB-1234567890-compact.png?amount=${widget.amount}&addInfo=$_transferCode&accountName=PT%20BOOKING%20DEMO';
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  @override
  void initState() {
    super.initState();
    if (_isMomo) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startMomoAutoConfirm());
    }
  }

  @override
  void dispose() {
    _momoAutoConfirmTimer?.cancel();
    super.dispose();
  }

  void _startMomoAutoConfirm() {
    if (!mounted || _momoAutoConfirmStarted) return;

    setState(() => _momoAutoConfirmStarted = true);
    _momoAutoConfirmTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted || _isSubmitting) return;

      setState(() => _momoScanDetected = true);
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        await _processDeposit();
      }
    });
  }

  Future<void> _processDeposit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 900));
      await _walletService.requestDeposit(userId: widget.userId, userName: widget.userName, amount: widget.amount);

      if (!mounted) return;
      SimulationNotificationService.showNotification(
        context,
        'Tài khoản vừa được cộng +${_formatCurrency(widget.amount)} từ ${_isMomo ? 'MoMo' : 'VietQR'}.',
      );

      await _showSuccessSheet();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thanh toán thành công',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(widget.amount),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hoàn tất', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildMomoPaymentImageCard(Color momoColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2, color: momoColor),
              const SizedBox(width: 8),
              const Text(
                'Mã thanh toán MoMo',
                style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              color: AppColors.background,
              child: Image.asset(
                'lib/services/momo.jpg',
                height: 230,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'Không tải được ảnh MoMo',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _momoScanDetected ? AppColors.success.withValues(alpha: 0.1) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _momoScanDetected ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                if (_momoScanDetected)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                else
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _momoScanDetected
                        ? 'Đã nhận giao dịch MoMo. Đang cộng tiền vào ví...'
                        : 'Đang chờ quét QR. Demo sẽ tự xác nhận sau vài giây.',
                    style: TextStyle(
                      color: _momoScanDetected ? AppColors.success : AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomoScreen() {
    const momoColor = AppColors.primary;
    const momoDark = AppColors.primaryDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: momoColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thanh toán MoMo', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline))],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  decoration: const BoxDecoration(
                    color: momoColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'MoMo',
                            style: TextStyle(color: momoColor, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('PT Booking', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(widget.amount),
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMomoPaymentImageCard(momoColor),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: momoColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet, color: momoColor),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nguồn tiền',
                                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Ví MoMo',
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                  child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Ưu đãi',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Chọn mã',
                                  style: TextStyle(color: momoColor, fontWeight: FontWeight.w700),
                                ),
                                const Icon(Icons.chevron_right, color: momoColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          children: [
                            _infoRow('Nhà cung cấp', 'PT Booking'),
                            const Divider(height: 1),
                            _infoRow('Mã giao dịch', _transferCode),
                            const Divider(height: 1),
                            _infoRow('Số tiền', _formatCurrency(widget.amount)),
                            const Divider(height: 1),
                            _infoRow('Phí giao dịch', 'Miễn phí', valueColor: AppColors.success),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: momoColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: momoColor.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: momoDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Giao dịch được xác nhận trong môi trường demo PTBooking.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, -6)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatCurrency(widget.amount),
                        style: const TextStyle(color: momoColor, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: momoColor.withValues(alpha: _momoScanDetected || _isSubmitting ? 1 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_momoScanDetected)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _momoScanDetected ? 'Đang xác nhận thanh toán' : 'Đang chờ quét QR',
                          style: TextStyle(
                            color: _momoScanDetected || _isSubmitting ? Colors.white : AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankScreen() {
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
                child: Image.network(_bankQrUrl, width: 210, height: 210, fit: BoxFit.contain),
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
                  _infoRow('Số tiền', _formatCurrency(widget.amount)),
                  const Divider(height: 1),
                  _infoRow('Nội dung CK', _transferCode),
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
                    child: _isSubmitting
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

  @override
  Widget build(BuildContext context) {
    return _isMomo ? _buildMomoScreen() : _buildBankScreen();
  }
}
