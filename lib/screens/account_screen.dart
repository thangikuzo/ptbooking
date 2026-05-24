import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'pt_registration_screen.dart';
import 'pt_schedule_screen.dart';
import 'student_progress_screen.dart';
import 'my_progress_screen.dart';
import 'battle_pass_screen.dart';
import 'level_rewards_screen.dart';
import 'inventory_screen.dart';
import 'achievement_screen.dart';
import 'dev_tool_screen.dart';

class AccountScreen extends StatefulWidget {
  final String userRole;

  const AccountScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();

  UserModel? _userModel;

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var doc = snapshot.data!;
        if (!doc.exists) {
          return const Scaffold(body: Center(child: Text("Không tìm thấy dữ liệu")));
        }
  Future<void> _fetchUserData() async {
    UserModel? user = await _authService.getUserData();

    setState(() {
      _userModel = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

        _userModel = UserModel.fromFirestore(doc);

        String roleDisplay = "Khách hàng";
        Color roleColor = Colors.blueGrey;

        if (_userModel?.role == 'PT') {
          roleDisplay = "Huấn luyện viên (PT)";
          roleColor = const Color(0xFFFCA311);
        } else if (_userModel?.role == 'Admin') {
          roleDisplay = "Quản trị viên";
          roleColor = Colors.redAccent;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(roleDisplay, roleColor),
                const SizedBox(height: 10),
    if (_userModel?.role == "PT") {
      roleDisplay = "Huấn luyện viên (PT)";
      roleColor = const Color(0xFFFCA311);
    } else if (_userModel?.role == "Admin") {
      roleDisplay = "Quản trị viên";
      roleColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              roleDisplay,
              roleColor,
            ),
            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_userModel?.role == 'user') ...[
                    _buildLoginStreak(),
                    const SizedBox(height: 16),
                  ],
                  _buildMenuItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  }),

                  if (_userModel?.role == 'user') ...[
                    _buildMenuItem(Icons.card_giftcard, "Phần thưởng cấp độ", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LevelRewardsScreen(),
                        ),
                      );
                    }),
                    
                    _buildMenuItem(Icons.star, "Thẻ Battle Pass", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BattlePassScreen(),
                        ),
                      );
                    }),
                    
                    _buildMenuItem(Icons.workspace_premium, "Bảng Thành Tích", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AchievementScreen(),
                        ),
                      );
                    }),

                    _buildMenuItem(Icons.inventory_2, "Kho Đồ (Khung & Avatar)", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InventoryScreen(),
                        ),
                      );
                    }),
                  ],

                  if (_userModel?.role == 'user')
                    _buildMenuItem(Icons.bar_chart, "Tiến độ của tôi", () {

                  _buildMenuItem(
                    Icons.person_outline,
                    "Chỉnh sửa hồ sơ",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const EditProfileScreen(),
                        ),
                      );
                    },
                  ),

                  if (_userModel?.role == "user")
                    _buildMenuItem(
                      Icons.bar_chart,
                      "Tiến độ của tôi",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const MyProgressScreen(),
                          ),
                        );
                      },
                    ),

                  if (_userModel?.role == "user")
                    _buildMenuItem(
                      Icons.sports_gymnastics,
                      "Đăng ký trở thành PT",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const PTRegistrationScreen(),
                          ),
                        );
                      },
                    ),

                  if (_userModel?.role == "PT")
                    _buildMenuItem(
                      Icons.schedule,
                      "Cài đặt giờ làm việc",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const PTScheduleScreen(),
                          ),
                        );
                      },
                    ),

                  if (_userModel?.role == "PT")
                    _buildMenuItem(
                      Icons.insights,
                      "Đánh giá tiến độ học viên",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const StudentProgressScreen(),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  _buildMenuItem(Icons.developer_mode, "Developer Tools (Test)", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DevToolScreen(),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    Icons.logout,
                    "Đăng xuất",
                        () async {
                      await _authService.logout();

                      if (mounted) {
                        Navigator.of(context)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                            const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildLoginStreak() {
    int streak = _userModel?.loginStreak ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
              const SizedBox(width: 8),
              const Text("Chuỗi đăng nhập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text("$streak ngày", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              int day = index + 1;
              bool isActive = day <= streak;
              bool isToday = day == streak;
              bool isRewardDay = day == 7;
              
              // Animated lửa
              return Column(
                children: [
                  if (isActive)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: isToday ? scale : 1.0,
                          child: Icon(
                            isRewardDay ? Icons.local_fire_department : Icons.whatshot,
                            color: isRewardDay ? Colors.red : Colors.orangeAccent,
                            size: isRewardDay ? 36 : 28,
                          ),
                        );
                      },
                      onEnd: () {
                        // Trick để lặp animation vô tận (hoặc dùng provider/state) - tạm thời TweenAnimationBuilder sẽ chạy 1 lần. 
                        // Để lửa động liên tục cần AnimationController, nhưng dùng pulse CSS-like đơn giản.
                      },
                    )
                  else
                    Icon(
                      isRewardDay ? Icons.card_giftcard : Icons.whatshot,
                      color: Colors.grey.shade300,
                      size: isRewardDay ? 30 : 24,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "T${day + 1 == 8 ? "CN" : day + 1}", 
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.orange.shade800 : Colors.grey,
                    )
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      String roleDisplay,
      Color roleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)], // Xanh lá - Trắng nhẹ
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
        ]
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 8)
              ]
            ),
            child: SizedBox(
              width: 115,
              height: 115,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage:
                    (_userModel?.avatar != null && _userModel!.avatar!.isNotEmpty)
                        ? NetworkImage(_userModel!.avatar!)
                        : null,
                    child: (_userModel?.avatar == null || _userModel!.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 45, color: Colors.grey)
                        : null,
                  ),
                  if (_userModel?.selectedFrame != null && _userModel!.selectedFrame!.isNotEmpty)
                    SizedBox(
                      width: 115,
                      height: 115,
                      child: Image.asset(
                        _userModel!.selectedFrame!.replaceAll('.jpg', '.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white24,
            backgroundImage:
            (_userModel?.avatar != null &&
                _userModel!.avatar!.isNotEmpty)
                ? NetworkImage(
              _userModel!.avatar!,
            )
                : null,
            child:
            (_userModel?.avatar == null ||
                _userModel!
                    .avatar!.isEmpty)
                ? const Icon(
              Icons.person,
              size: 45,
              color: Colors.white,
            )
                : null,
          ),

          const SizedBox(height: 14),

          Text(
            _userModel?.name ??
                "Người dùng",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)]
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _userModel?.email ?? "",
            style: const TextStyle(color: Colors.white, fontSize: 13),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),
          if (_userModel?.role == 'User')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Text("Lv ${_userModel?.level ?? 1}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Text("${_userModel?.exp ?? 0} / ${_userModel!.level * 500} EXP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Text("BP Lv ${_userModel?.bpLevel ?? 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _buildRoleBadge(roleDisplay, Colors.white, Colors.black),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],

          _buildRoleBadge(
            roleDisplay,
            roleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(
      String text,
      Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.15,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: color.withOpacity(
            0.4,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontWeight:
          FontWeight.bold,
          color: color,
        ),
      ),
    );
  }


  Widget _buildMenuItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Container(
          padding:
          const EdgeInsets.all(
            10,
          ),
          decoration:
          BoxDecoration(
            color: isDestructive
                ? Colors.red
                .withOpacity(
                0.1)
                : const Color(
                0xFF2E3B55)
                .withOpacity(
                0.1),
            borderRadius:
            BorderRadius
                .circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color:
            isDestructive
                ? Colors.red
                : const Color(
                0xFF2E3B55),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
            isDestructive
                ? Colors.red
                : Colors.black87,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}