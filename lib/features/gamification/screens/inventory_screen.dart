import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUser = UserModel.fromFirestore(doc);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectItem(String field, String path) async {
    if (_currentUser == null) return;

    // Nếu đang chọn khung đã chọn -> gỡ bỏ
    String? newValue = path;
    if (field == 'selectedFrame' && _currentUser!.selectedFrame == path) newValue = null;
    if (field == 'selectedChatFrame' && _currentUser!.selectedChatFrame == path) newValue = null;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({field: newValue});
      _loadUser();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã cập nhật khung!'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showVoucherDetails(Map<String, dynamic> voucher) {
    bool isExpired = false;
    String expireText = "Không thời hạn";
    if (voucher['expiresAt'] != null) {
      DateTime expireDate = (voucher['expiresAt'] as Timestamp).toDate();
      isExpired = expireDate.isBefore(DateTime.now());
      expireText = "Hết hạn: ${expireDate.day}/${expireDate.month}/${expireDate.year}";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          voucher['title'] ?? 'Voucher',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Giảm giá: ${voucher['discount']}%",
              style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(expireText, style: TextStyle(color: isExpired ? Colors.red : Colors.grey)),
            const SizedBox(height: 20),
            if (!isExpired) ...[
              const Text("Mã QR Tặng/Sử dụng:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              QrImageView(data: voucher['code'] ?? 'INVALID_CODE', version: QrVersions.auto, size: 200.0),
              const SizedBox(height: 10),
              SelectableText(
                voucher['code'] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                "Voucher này đã hết hạn!",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kho Đồ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Khung Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: GamificationConstants.ALL_AVATAR_FRAMES.map((framePath) {
                  // Hỗ trợ legacy .jpg
                  bool isUnlocked =
                      _currentUser!.unlockedFrames.contains(framePath) ||
                      _currentUser!.unlockedFrames.contains(framePath.replaceAll('.png', '.jpg'));
                  bool isSelected =
                      _currentUser!.selectedFrame == framePath ||
                      _currentUser!.selectedFrame == framePath.replaceAll('.png', '.jpg');
                  return GestureDetector(
                    onTap: () {
                      if (isUnlocked) _selectItem('selectedFrame', framePath);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: Image.asset(
                              framePath,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.error),
                            ),
                          ),
                          if (!isUnlocked) const Icon(Icons.lock, color: Colors.grey, size: 40),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              const Text('Khung Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: GamificationConstants.ALL_CHAT_FRAMES.map((framePath) {
                  // Hỗ trợ legacy .jpg
                  bool isUnlocked =
                      _currentUser!.unlockedChatFrames.contains(framePath) ||
                      _currentUser!.unlockedChatFrames.contains(framePath.replaceAll('.png', '.jpg'));
                  bool isSelected =
                      _currentUser!.selectedChatFrame == framePath ||
                      _currentUser!.selectedChatFrame == framePath.replaceAll('.png', '.jpg');
                  return GestureDetector(
                    onTap: () {
                      if (isUnlocked) _selectItem('selectedChatFrame', framePath);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: Image.asset(
                              framePath,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.error),
                            ),
                          ),
                          if (!isUnlocked) const Icon(Icons.lock, color: Colors.grey, size: 40),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              const Text('Voucher (Phiếu giảm giá)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_currentUser!.unlockedVouchers.isEmpty)
                const Text("Bạn chưa có Voucher nào.", style: TextStyle(color: Colors.grey)),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _currentUser!.unlockedVouchers.map((voucher) {
                  return GestureDetector(
                    onTap: () => _showVoucherDetails(voucher),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_num, color: AppColors.primary, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            voucher['title'] ?? 'Voucher',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Giảm ${voucher['discount']}%",
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
