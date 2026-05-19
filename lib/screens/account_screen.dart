import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'pt_registration_screen.dart';
import 'pt_schedule_screen.dart';
import 'student_progress_screen.dart';
import 'my_progress_screen.dart';

class AccountScreen extends StatefulWidget {
  final String userRole;

  const AccountScreen({super.key, required this.userRole});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  }),

                  if (_userModel?.role == 'User')
                    _buildMenuItem(Icons.bar_chart, "Tiến độ của tôi", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyProgressScreen(),
                        ),
                      );
                    }),

                  if (_userModel?.role == 'User')
                    _buildMenuItem(
                      Icons.sports_gymnastics,
                      "Đăng ký trở thành PT",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PTRegistrationScreen(),
                          ),
                        );
                      },
                    ),

                  if (_userModel?.role == 'PT')
                    _buildMenuItem(Icons.schedule, "Cài đặt giờ làm việc", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PTScheduleScreen(),
                        ),
                      );
                    }),

                  if (_userModel?.role == 'PT')
                    _buildMenuItem(
                      Icons.insights,
                      "Đánh giá tiến độ học viên",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentProgressScreen(),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),

                  _buildMenuItem(Icons.logout, "Đăng xuất", () async {
                    await _authService.logout();

                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    }
                  }, isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String roleDisplay, Color roleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2E3B55),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white24,
            backgroundImage:
            (_userModel?.avatar != null && _userModel!.avatar!.isNotEmpty)
                ? NetworkImage(_userModel!.avatar!)
                : null,
            child: (_userModel?.avatar == null || _userModel!.avatar!.isEmpty)
                ? const Icon(Icons.person, size: 45, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            _userModel?.name ?? "Người dùng",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _userModel?.email ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildRoleBadge(roleDisplay, roleColor),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFF2E3B55).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF2E3B55),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}