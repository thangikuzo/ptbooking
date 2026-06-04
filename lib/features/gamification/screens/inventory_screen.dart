import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';
import 'package:ptbooking/features/gamification/widgets/user_avatar_with_frame.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _previewFrame;
  String? _previewChatFrame;

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
          _previewFrame = _currentUser!.selectedFrame;
          _previewChatFrame = _currentUser!.selectedChatFrame;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectItem(String field, String path) async {
    if (_currentUser == null) return;

    String? newValue = path;
    if (field == 'selectedFrame' && _currentUser!.selectedFrame == path) newValue = null;
    if (field == 'selectedChatFrame' && _currentUser!.selectedChatFrame == path) newValue = null;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({field: newValue});
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật trang bị!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Error equipping item: $e');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              const Text("Mã QR Tặng/Sử dụng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              QrImageView(data: voucher['code'] ?? 'INVALID_CODE', version: QrVersions.auto, size: 180.0),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  voucher['code'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text(
                "Voucher này đã hết hạn!",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Kho Đồ Cá Nhân',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D5D9B), Color(0xFF4BA3E3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.portrait), text: "Khung Avatar"),
              Tab(icon: Icon(Icons.chat_bubble), text: "Khung Chat"),
              Tab(icon: Icon(Icons.confirmation_num), text: "Vouchers"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: AVATAR FRAMES
            _buildAvatarFramesTab(),

            // TAB 2: CHAT FRAMES
            _buildChatFramesTab(),

            // TAB 3: VOUCHERS
            _buildVouchersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFramesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // LIVE PREVIEW CANVAS
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "XEM TRƯỚC TRANG BỊ",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  
                  // Live Avatar Preview circle
                  UserAvatarWithFrame(
                    avatarUrl: _currentUser?.avatar,
                    selectedFrame: _previewFrame,
                    size: 90,
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    _currentUser?.name ?? "Học viên",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Bấm vào các khung bên dưới để ướm thử và trang bị",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // GRID FRAMES INVENTORY
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: GamificationConstants.ALL_AVATAR_FRAMES.length,
            itemBuilder: (context, index) {
              String framePath = GamificationConstants.ALL_AVATAR_FRAMES[index];
              bool isUnlocked =
                  _currentUser!.unlockedFrames.contains(framePath) ||
                  _currentUser!.unlockedFrames.contains(framePath.replaceAll('.png', '.jpg'));
              bool isSelected =
                  _currentUser!.selectedFrame == framePath ||
                  _currentUser!.selectedFrame == framePath.replaceAll('.png', '.jpg');
              bool isPreviewing = _previewFrame == framePath;

              return FadeInUp(
                duration: Duration(milliseconds: 200 + (index % 3 * 100)),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewFrame = framePath;
                    });
                    if (isUnlocked) {
                      _selectItem('selectedFrame', framePath);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.green
                            : (isPreviewing ? AppColors.primary : Colors.transparent),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: isUnlocked ? 1.0 : 0.35,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              framePath,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        if (!isUnlocked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock, color: Colors.white, size: 18),
                          ),
                        if (isSelected)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "SỬ DỤNG",
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        else if (isPreviewing)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "ướm thử",
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatFramesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // MOCK CHAT BUBBLE PREVIEW
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "XEM TRƯỚC KHUNG CHAT",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Mock chat layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: _previewChatFrame != null ? Colors.amber.shade400 : Colors.transparent,
                            width: _previewChatFrame != null ? 1.5 : 0,
                          ),
                        ),
                        child: const Text(
                          "Xin chào! Đây là khung chat của tôi.",
                          style: TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      UserAvatarWithFrame(
                        avatarUrl: _currentUser?.avatar,
                        selectedFrame: _previewFrame,
                        size: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CHAT FRAMES LIST
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: GamificationConstants.ALL_CHAT_FRAMES.length,
            itemBuilder: (context, index) {
              String framePath = GamificationConstants.ALL_CHAT_FRAMES[index];
              bool isUnlocked =
                  _currentUser!.unlockedChatFrames.contains(framePath) ||
                  _currentUser!.unlockedChatFrames.contains(framePath.replaceAll('.png', '.jpg'));
              bool isSelected =
                  _currentUser!.selectedChatFrame == framePath ||
                  _currentUser!.selectedChatFrame == framePath.replaceAll('.png', '.jpg');
              bool isPreviewing = _previewChatFrame == framePath;

              return FadeInUp(
                duration: Duration(milliseconds: 200 + (index % 3 * 100)),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewChatFrame = framePath;
                    });
                    if (isUnlocked) {
                      _selectItem('selectedChatFrame', framePath);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.green
                            : (isPreviewing ? AppColors.primary : Colors.transparent),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: isUnlocked ? 1.0 : 0.35,
                          child: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 48),
                        ),
                        if (!isUnlocked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock, color: Colors.white, size: 18),
                          ),
                        if (isSelected)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "SỬ DỤNG",
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        else if (isPreviewing)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "ướm thử",
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersTab() {
    if (_currentUser!.unlockedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text("Bạn chưa có Voucher nào.", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentUser!.unlockedVouchers.length,
      itemBuilder: (context, index) {
        var voucher = _currentUser!.unlockedVouchers[index];

        bool isExpired = false;
        String expireText = "Không thời hạn";
        if (voucher['expiresAt'] != null) {
          DateTime expireDate = (voucher['expiresAt'] as Timestamp).toDate();
          isExpired = expireDate.isBefore(DateTime.now());
          expireText = "Hạn: ${expireDate.day}/${expireDate.month}/${expireDate.year}";
        }

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index % 5 * 100)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                // Left Part of Ticket: Discount Badge
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D5D9B), Color(0xFF4BA3E3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.confirmation_num, color: Colors.white, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        "${voucher['discount']}% GIẢM",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Dashed vertical line cutout representation
                CustomPaint(
                  size: const Size(20, double.infinity),
                  painter: _TicketNotchPainter(),
                ),

                // Right Part of Ticket: Info + Detail Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          voucher['title'] ?? 'Voucher giảm giá',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          expireText,
                          style: TextStyle(color: isExpired ? Colors.red : Colors.grey.shade500, fontSize: 10),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppColors.primaryLight,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => _showVoucherDetails(voucher),
                            child: const Text(
                              "Sử dụng",
                              style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter to draw notches and dashed line representing a classic ticket coupon
class _TicketNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    // Draw top semicirle cutout notch
    canvas.drawCircle(Offset(size.width / 2, 0), 10, paint);

    // Draw bottom semicircle cutout notch
    canvas.drawCircle(Offset(size.width / 2, size.height), 10, paint);

    // Draw vertical dashed line in the center
    final linePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double startY = 12;
    double endY = size.height - 12;
    double dashHeight = 4;
    double dashSpace = 4;

    while (startY < endY) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        linePaint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
