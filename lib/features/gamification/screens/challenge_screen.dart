import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import '../models/challenge_model.dart';
import 'challenge_detail_screen.dart';
import 'inventory_screen.dart';
import 'achievement_screen.dart';
import 'battle_pass_screen.dart';
import 'level_rewards_screen.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/features/gamification/widgets/user_avatar_with_frame.dart';
import 'package:ptbooking/features/pt_booking/screens/pt_create_challenge_screen.dart';
import 'package:ptbooking/features/home/screens/notification_screen.dart';
import 'package:ptbooking/features/pt_booking/screens/pt_ranking_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  String? _userRole;
  String _selectedDifficulty = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = (doc.data() as Map<String, dynamic>)['role']?.toString();
        });

        // Trigger check for ended challenges to notify PT
        if (_userRole == 'PT') {
          _checkAndNotifyEndedChallenges(user.uid);
          _cleanupOldChallenges(user.uid);
        }
      }
    }
  }

  Future<void> _cleanupOldChallenges(String uid) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .where('creatorId', isEqualTo: uid)
          .where('isRewardsDistributed', isEqualTo: true)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        // Xóa tất cả submissions của challenge này
        var subSnap = await FirebaseFirestore.instance
            .collection('submissions')
            .where('challengeId', isEqualTo: doc.id)
            .get();
        for (var subDoc in subSnap.docs) {
          batch.delete(subDoc.reference);
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up challenges: $e');
    }
  }

  Future<void> _checkAndNotifyEndedChallenges(String uid) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('challenges').where('creatorId', isEqualTo: uid).get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        bool isRewardsDistributed = data['isRewardsDistributed'] ?? false;
        bool isNotified = data['isEndNotified'] ?? false;
        if (!isRewardsDistributed && !isNotified) {
          Timestamp? endTime = data['endTime'];
          if (endTime != null && endTime.toDate().isBefore(DateTime.now())) {
            // Đã kết thúc nhưng chưa phát thưởng -> Nhắc nhở
            await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
              'type': 'system',
              'message': 'Thử thách "${data['title']}" đã kết thúc! Hãy chấm điểm và trao thưởng cho Top 3 nhé.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            // Đánh dấu đã nhắc nhở
            await doc.reference.update({'isEndNotified': true});
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking ended challenges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Đấu Trường",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.leaderboard, color: Colors.amber, size: 20),
            label: const Text(
              'Top PT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PTRankingScreen()));
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: currentUser != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // LOBBY PROFILE HEADER (Chỉ dành cho User, PT thì ẩn bớt phần exp)
            if (currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  UserModel userModel = UserModel.fromFirestore(userSnap.data!);

                  return FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        children: [
                          // Hàng Avatar + Tên + Cấp độ
                          Row(
                            children: [
                              UserAvatarWithFrame(
                                avatarUrl: userModel.avatar,
                                selectedFrame: userModel.selectedFrame,
                                size: 55,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userModel.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.accent, width: 1),
                                          ),
                                          child: Text(
                                            "Cấp độ ${userModel.level}",
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          userModel.role == 'PT' ? "Huấn luyện viên" : "Học viên",
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (userModel.loginStreak > 0)
                                Column(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                                    Text(
                                      "${userModel.loginStreak} Ngày",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Thanh EXP Progress Bar
                          if (userModel.role != 'PT') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${userModel.exp % 100} / 100 EXP",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  "Cấp tiếp theo: Lv. ${userModel.level + 1}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (userModel.exp % 100) / 100.0,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Grid Lối Tắt Nhanh (Quick Actions)
                          if (userModel.role != 'PT')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildShortcutButton(
                                  context: context,
                                  icon: Icons.confirmation_num_outlined,
                                  label: "Battle Pass",
                                  color: Colors.amber,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BattlePassScreen()),
                                  ),
                                ),
                                _buildShortcutButton(
                                  context: context,
                                  icon: Icons.inventory_2_outlined,
                                  label: "Túi đồ",
                                  color: Colors.cyan,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const InventoryScreen()),
                                  ),
                                ),
                                _buildShortcutButton(
                                  context: context,
                                  icon: Icons.emoji_events_outlined,
                                  label: "Thành tích",
                                  color: Colors.pinkAccent,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AchievementScreen()),
                                  ),
                                ),
                                _buildShortcutButton(
                                  context: context,
                                  icon: Icons.card_giftcard_outlined,
                                  label: "Quà cấp",
                                  color: Colors.greenAccent,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LevelRewardsScreen()),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // TIÊU ĐỀ SECTION & BỘ LỌC ĐỘ KHÓ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    "ĐẤU TRƯỜNG THỬ THÁCH",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.sports_kabaddi, color: Colors.grey.shade400),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // THANH CHỌN BỘ LỌC
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['Tất cả', 'Bình thường', 'Khó', 'Rất khó'].map((difficulty) {
                  bool isSelected = _selectedDifficulty == difficulty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        difficulty,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedDifficulty = difficulty;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // DANH SÁCH THỬ THÁCH
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
                }

                var docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Chưa có thử thách nào đang diễn ra.",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Chuyển đổi thành Object Challenge & Lọc độ khó
                List<Challenge> challenges = docs.map((d) => Challenge.fromFirestore(d)).toList();
                if (_selectedDifficulty != 'Tất cả') {
                  challenges = challenges.where((c) => c.difficulty == _selectedDifficulty).toList();
                }

                if (challenges.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        "Không tìm thấy thử thách $_selectedDifficulty nào.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: challenges.length,
                  itemBuilder: (context, index) {
                    Challenge challenge = challenges[index];

                    // Tính toán thời gian còn lại
                    String timeRemaining = "Không giới hạn";
                    bool isExpired = false;
                    if (challenge.endTime != null) {
                      DateTime end = challenge.endTime!.toDate();
                      Duration diff = end.difference(DateTime.now());
                      if (diff.isNegative) {
                        timeRemaining = "Đã kết thúc";
                        isExpired = true;
                      } else {
                        timeRemaining = "Còn ${diff.inHours}h ${diff.inMinutes % 60}m";
                      }
                    }

                    Color difficultyColor = Colors.green;
                    if (challenge.difficulty == 'Khó') difficultyColor = Colors.orange;
                    if (challenge.difficulty == 'Rất khó') difficultyColor = Colors.red;

                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChallengeDetailScreen(challenge: challenge)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // 1. Ảnh thử thách dạng Circle với bóng đổ
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        challenge.imageUrl.isNotEmpty
                                            ? challenge.imageUrl
                                            : 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
                                        width: 65,
                                        height: 65,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 65, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 2. Thông tin chi tiết
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          challenge.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: difficultyColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                challenge.difficulty,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: difficultyColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 13,
                                              color: isExpired ? Colors.red : Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              timeRemaining,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isExpired ? Colors.red : Colors.grey.shade600,
                                                fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (challenge.rating > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                const SizedBox(width: 2),
                                                Text(
                                                  challenge.rating.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.text,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // 3. EXP bubble ở góc phải
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "+${challenge.points} XP",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), // Chừa khoảng trống cho FAB
          ],
        ),
      ),
      floatingActionButton: _userRole == 'PT'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PTCreateChallengeScreen()));
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "TẠO THỬ THÁCH",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
