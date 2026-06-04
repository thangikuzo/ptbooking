import 'package:flutter/material.dart';
import 'package:ptbooking/core/constants/app_colors.dart';

class MomoPaymentView extends StatelessWidget {
  final int amount;
  final String transferCode;
  final bool isSubmitting;
  final bool momoScanDetected;

  const MomoPaymentView({
    super.key,
    required this.amount,
    required this.transferCode,
    required this.isSubmitting,
    required this.momoScanDetected,
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
              color: momoScanDetected ? AppColors.success.withValues(alpha: 0.1) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: momoScanDetected ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                if (momoScanDetected)
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
                    momoScanDetected
                        ? 'Đã nhận giao dịch MoMo. Đang cộng tiền vào ví...'
                        : 'Đang chờ quét QR. Demo sẽ tự xác nhận sau vài giây.',
                    style: TextStyle(
                      color: momoScanDetected ? AppColors.success : AppColors.primaryDark,
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

  @override
  Widget build(BuildContext context) {
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
                        _formatCurrency(amount),
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
                            _infoRow('Mã giao dịch', transferCode),
                            const Divider(height: 1),
                            _infoRow('Số tiền', _formatCurrency(amount)),
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
                        _formatCurrency(amount),
                        style: const TextStyle(color: momoColor, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: momoColor.withValues(alpha: momoScanDetected || isSubmitting ? 1 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!momoScanDetected)
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
                          momoScanDetected ? 'Đang xác nhận thanh toán' : 'Đang chờ quét QR',
                          style: TextStyle(
                            color: momoScanDetected || isSubmitting ? Colors.white : AppColors.primaryDark,
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
}
