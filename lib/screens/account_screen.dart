import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'pt_registration_screen.dart';
import 'pt_schedule_screen.dart';

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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Logic hiển thị Role
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Profile dùng Model
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(radius: 35,
                    backgroundColor: Colors.grey[300],
                    // Kiểm tra nếu có link ảnh thì hiện, không thì hiện icon mặc định
                    backgroundImage: (_userModel?.avatar != null && _userModel!.avatar!.isNotEmpty)
                        ? NetworkImage(_userModel!.avatar!)
                        : null,
                    child: (_userModel?.avatar == null || _userModel!.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userModel?.name ?? "Người dùng", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_userModel?.email ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 6),
                        _buildRoleBadge(roleDisplay, roleColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMenuItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
          }),
          if (_userModel?.role == 'User')
            _buildMenuItem(Icons.sports, "Đăng ký trở thành PT", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PTRegistrationScreen()));
            }),
          if (_userModel?.role == 'PT')
            _buildMenuItem(Icons.schedule, "Cài đặt giờ làm việc", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PTScheduleScreen()));
            }),
          const Divider(height: 30),
          _buildMenuItem(Icons.logout, "Đăng xuất", () async {
            await _authService.logout();
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF2E3B55)),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}