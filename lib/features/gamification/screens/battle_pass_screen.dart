import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';

class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> {
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
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUser = UserModel.fromFirestore(doc);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _buyVip() async {
    if (_currentUser == null) return;

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text("Kích hoạt VIP", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text("Bạn có muốn kích hoạt thẻ Battle Pass VIP để nhận hàng loạt phần quà Voucher, Khung và Tăng EXP độc quyền với giá 199.000đ không?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("MUA NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({'isVip': true});
      _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kích hoạt VIP thành công!'), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    bool isVip = _currentUser?.isVip ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark gaming theme background
      appBar: AppBar(
        title: const Text(
          "BATTLE PASS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // HEADER CARD (METALLIC PREMIUM LOOK)
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "MÙA 1: ĐỈNH CAO THỂ LỰC",
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Cấp độ ${_currentUser?.bpLevel ?? 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // VIP BUTTON OR BADGE WITH GLOW
                      if (!isVip)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: Colors.amber.withOpacity(0.4),
                          ),
                          onPressed: _buyVip,
                          icon: const Icon(Icons.star, color: Colors.black87, size: 18),
                          label: const Text(
                            "MỞ KHÓA VIP",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.stars, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "ĐÃ SỞ HỮU VIP",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Progress EXP Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_currentUser?.bpExp ?? 0} / 50 BP EXP",
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "50 EXP mỗi cấp",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentUser?.bpExp ?? 0) / 50.0,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB LABELS (FREE vs VIP)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "MIỄN PHÍ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.5, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 70), // Khớp với cột Level ở giữa
                Expanded(
                  child: Center(
                    child: Text(
                      "VIP BATTLE PASS",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade400, letterSpacing: 1.5, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // TIMELINE REWARDS LIST VIEW
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 20, // 20 Levels
              itemBuilder: (context, index) {
                int level = index + 1;
                bool isUnlocked = level <= (_currentUser?.bpLevel ?? 1);

                return FadeInUp(
                  duration: Duration(milliseconds: 200 + (index % 5 * 100)),
                  child: _buildRewardRow(level, isUnlocked, isVip),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(int level, bool isUnlocked, bool userIsVip) {
    var freeList = GamificationConstants.BATTLEPASS_REWARDS_FREE;
    var vipList = GamificationConstants.BATTLEPASS_REWARDS_VIP;

    var freeRewardData = freeList.firstWhere((element) => element['level'] == level, orElse: () => {});
    var vipRewardData = vipList.firstWhere((element) => element['level'] == level, orElse: () => {});

    // Default for free
    String freeRewardName = freeRewardData.isNotEmpty ? freeRewardData['title'] : "100 EXP";
    String freeImage = freeRewardData.isNotEmpty ? freeRewardData['image'] : "assets/rewards/exp.png";
    IconData freeIconFallback = Icons.star_border;

    // Default for VIP
    String vipRewardName = vipRewardData.isNotEmpty ? vipRewardData['title'] : "Voucher 5%";
    String vipImage = vipRewardData.isNotEmpty ? vipRewardData['image'] : "assets/vouchers/voucher_5.png";
    IconData vipIconFallback = Icons.local_activity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 85,
      child: Row(
        children: [
          // 1. FREE REWARD CARD
          Expanded(
            child: _buildRewardCard(
              name: freeRewardName,
              imagePath: freeImage,
              fallbackIcon: freeIconFallback,
              isClaimed: isUnlocked,
              isLocked: !isUnlocked,
              color: const Color(0xFF1E293B),
              accentColor: Colors.cyanAccent,
            ),
          ),

          // 2. TIMELINE CONNECTOR COLUM
          SizedBox(
            width: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Connecting lines
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: isUnlocked ? Colors.cyanAccent.withOpacity(0.4) : Colors.white10,
                  ),
                ),
                // Level Indicator Circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked ? Colors.cyanAccent : Colors.white10,
                      width: 2,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      level.toString(),
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. VIP REWARD CARD
          Expanded(
            child: _buildRewardCard(
              name: vipRewardName,
              imagePath: vipImage,
              fallbackIcon: vipIconFallback,
              isClaimed: isUnlocked && userIsVip,
              isLocked: !(isUnlocked && userIsVip),
              color: const Color(0xFF1E293B),
              accentColor: Colors.amber,
              isVipCard: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required String name,
    required String imagePath,
    required IconData fallbackIcon,
    required bool isClaimed,
    required bool isLocked,
    required Color color,
    required Color accentColor,
    bool isVipCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? accentColor.withOpacity(0.3)
              : (isVipCard ? Colors.amber.withOpacity(0.05) : Colors.white.withOpacity(0.03)),
          width: 1.5,
        ),
        boxShadow: isClaimed
            ? [BoxShadow(color: accentColor.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
      ),
      child: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isLocked ? 0.3 : 1.0,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      imagePath,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(fallbackIcon, color: accentColor, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: isLocked ? Colors.white30 : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Claimed Checkmark overlay
          if (isClaimed)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 10),
              ),
            ),

          // Locked overlay icon
          if (isLocked)
            Positioned(
              top: -2,
              right: -2,
              child: Icon(Icons.lock_outline, color: Colors.white24, size: 12),
            ),
        ],
      ),
    );
  }
}
