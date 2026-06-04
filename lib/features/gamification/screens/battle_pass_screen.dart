import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Luồng mua VIP Ảo
  Future<void> _buyVip() async {
    if (_currentUser == null) return;

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Kích hoạt VIP"),
            content: const Text("Bạn có muốn kích hoạt thẻ Battle Pass VIP với giá 199.000đ không?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("MUA NGAY", style: TextStyle(color: Colors.white)),
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
        ).showSnackBar(SnackBar(content: Text('Kích hoạt VIP thành công!'), backgroundColor: Colors.green));
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "BATTLE PASS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header: Thông tin cấp độ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mùa 1: Đỉnh Cao Thể Lực", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(
                          "CẤP ĐỘ ${_currentUser?.bpLevel ?? 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                          ),
                        ),
                      ],
                    ),
                    if (!(_currentUser?.isVip ?? false))
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 4,
                        ),
                        onPressed: _buyVip,
                        icon: const Icon(Icons.star, color: Colors.white),
                        label: const Text(
                          "MỞ KHÓA VIP",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: AppColors.accent),
                            SizedBox(width: 5),
                            Text(
                              "ĐÃ MỞ VIP",
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Thanh kinh nghiệm
                LinearProgressIndicator(
                  value: (_currentUser?.bpExp ?? 0) / 50.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_currentUser?.bpExp ?? 0} / 50 BP EXP",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Tiêu đề Cột
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "FREE",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 60),
                const Expanded(
                  child: Center(
                    child: Text(
                      "VIP",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách phần thưởng
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 20, // 20 cấp độ BP
              itemBuilder: (context, index) {
                int level = index + 1;
                bool isUnlocked = level <= (_currentUser?.bpLevel ?? 1);

                return _buildRewardRow(level, isUnlocked);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(int level, bool isUnlocked) {
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

    bool isVip = _currentUser?.isVip ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked ? Border.all(color: AppColors.border, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Quà Free
          Expanded(child: _buildRewardItem(freeRewardName, freeImage, freeIconFallback, isUnlocked, true)),

          // Cột Mốc Cấp Độ ở giữa
          Container(
            width: 50,
            decoration: BoxDecoration(
              gradient: isUnlocked ? AppColors.primaryGradient : null,
              color: isUnlocked ? null : Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                level.toString(),
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.grey.shade500,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Quà VIP
          Expanded(child: _buildRewardItem(vipRewardName, vipImage, vipIconFallback, isUnlocked && isVip, false)),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String name, String imagePath, IconData fallbackIcon, bool isUnlocked, bool isFree) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              imagePath,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(fallbackIcon, color: isFree ? AppColors.accent : AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: const Text(
                "ĐÃ NHẬN",
                style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
