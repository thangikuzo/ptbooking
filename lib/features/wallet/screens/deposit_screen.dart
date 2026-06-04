import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ptbooking/core/services/notification_service.dart';
import 'package:ptbooking/features/wallet/services/wallet_service.dart';
import 'package:ptbooking/features/wallet/widgets/momo_payment_view.dart';
import 'package:ptbooking/features/wallet/widgets/bank_payment_view.dart';
import 'package:ptbooking/features/wallet/widgets/deposit_success_sheet.dart';

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
        return DepositSuccessSheet(amount: widget.amount);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMomo) {
      return MomoPaymentView(
        amount: widget.amount,
        transferCode: _transferCode,
        isSubmitting: _isSubmitting,
        momoScanDetected: _momoScanDetected,
      );
    } else {
      return BankPaymentView(
        amount: widget.amount,
        transferCode: _transferCode,
        bankQrUrl: _bankQrUrl,
        isSubmitting: _isSubmitting,
        onConfirm: _processDeposit,
        onCancel: () => Navigator.of(context).pop(),
      );
    }
  }
}
