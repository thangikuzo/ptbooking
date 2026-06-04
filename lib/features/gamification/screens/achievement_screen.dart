import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
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

  void _showBadgeDetails(String title, String image, String description, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Image (Grayscale if locked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: Image.asset(image, width: 75, height: 75),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUnlocked ? "ĐÃ MỞ KHÓA" : "CHƯA ĐẠT ĐƯỢC",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Bảng Thành Tích',
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
              Tab(icon: Icon(Icons.stars), text: "Của tôi"),
              Tab(icon: Icon(Icons.auto_awesome), text: "Thư viện Huy hiệu"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: USER UNLOCKED BADGES
            _buildMyBadgesTab(),

            // TAB 2: SYSTEM BADGES DIRECTORY/GUIDE
            _buildBadgeDirectoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBadgesTab() {
    if (_currentUser!.unlockedBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "Bạn chưa đạt huy hiệu nào.",
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Hãy tham gia Thử Thách để ghi tên mình lên bảng vàng!",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _currentUser!.unlockedBadges.length,
      itemBuilder: (context, index) {
        var badgeData = _currentUser!.unlockedBadges[index];
        String badgeImage = badgeData['image'] ?? 'assets/badges/bronze_1.png';
        String challengeName = badgeData['challengeName'] ?? 'Huy Hiệu';

        // Check tier for glow color
        Color glowColor = Colors.amber;
        if (badgeImage.contains('silver')) glowColor = Colors.cyan;
        if (badgeImage.contains('bronze')) glowColor = Colors.orange;

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index % 3 * 100)),
          child: GestureDetector(
            onTap: () => _showBadgeDetails(
              challengeName,
              badgeImage,
              "Huy chương vinh danh bạn đã chinh phục thành công thứ hạng cao trong thử thách này.",
              true,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: glowColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    badgeImage,
                    width: 50,
                    height: 50,
                    errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.amber, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      challengeName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeDirectoryTab() {
    final List<Map<String, String>> systemBadges = [
      {
        'title': 'Huy hiệu Quán Quân (Vàng)',
        'image': 'assets/badges/gold_1.png',
        'desc': 'Dành riêng cho chiến binh xuất sắc nhất đoạt ngôi vị Quán quân (Top 1) trong bất kỳ đấu trường thử thách nào.'
      },
      {
        'title': 'Huy hiệu Á Quân (Bạc)',
        'image': 'assets/badges/silver_1.png',
        'desc': 'Phần thưởng trao cho chiến binh quả cảm đoạt giải Á quân (Top 2) trong các cuộc đua thử thách.'
      },
      {
        'title': 'Huy hiệu Hạng Ba (Đồng)',
        'image': 'assets/badges/bronze_1.png',
        'desc': 'Ghi nhận nỗ lực vượt bậc của học viên cán đích ở vị trí thứ 3 (Top 3) trong sự kiện thử thách.'
      },
      {
        'title': 'Khung Avatar Đồng',
        'image': 'assets/frame_avatar/1.png',
        'desc': 'Khung trang trí avatar Đồng cao cấp. Tự động nhận được khi nhân vật tích lũy đạt Cấp độ 10.'
      },
      {
        'title': 'Khung Avatar Bạc',
        'image': 'assets/frame_avatar/2.png',
        'desc': 'Khung trang trí avatar Bạc sáng bóng. Tự động nhận được khi nhân vật tích lũy đạt Cấp độ 20.'
      },
      {
        'title': 'Khung Avatar Vàng',
        'image': 'assets/frame_avatar/3.png',
        'desc': 'Khung trang trí avatar Vàng lấp lánh. Tự động nhận được khi nhân vật tích lũy đạt Cấp độ 30.'
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: systemBadges.length,
      itemBuilder: (context, index) {
        var badge = systemBadges[index];
        
        // Kiểm tra xem user đã sở hữu vật phẩm này chưa
        bool owned = false;
        String path = badge['image']!;
        if (path.contains('gold_1')) {
          owned = _currentUser!.unlockedBadges.any((b) => b['image'] == path);
        } else if (path.contains('silver_1')) {
          owned = _currentUser!.unlockedBadges.any((b) => b['image'] == path);
        } else if (path.contains('bronze_1')) {
          owned = _currentUser!.unlockedBadges.any((b) => b['image'] == path);
        } else {
          // Khung avatar
          owned = _currentUser!.unlockedFrames.contains(path) ||
                  _currentUser!.unlockedFrames.contains(path.replaceAll('.png', '.jpg'));
        }

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index % 2 * 100)),
          child: GestureDetector(
            onTap: () => _showBadgeDetails(badge['title']!, badge['image']!, badge['desc']!, owned),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: owned ? Colors.green.withOpacity(0.3) : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container (Grayscale if not owned)
                  Opacity(
                    opacity: owned ? 1.0 : 0.35,
                    child: ColorFiltered(
                      colorFilter: owned
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: Image.asset(badge['image']!, width: 48, height: 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owned ? "Đã sở hữu" : "Chưa sở hữu",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: owned ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
