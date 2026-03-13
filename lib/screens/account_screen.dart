import 'package:flutter/material.dart';
import 'pt_registration_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatelessWidget {
  final String userRole;

  const AccountScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    String displayName = user?.displayName ?? "Người dùng";
    String email = user?.email ?? "user@email.com";
    String? photoUrl = user?.photoURL;

    // Dịch Role sang tiếng Việt cho đẹp
    String roleDisplay = "Khách hàng";
    Color roleColor = Colors.blueGrey;

    if (userRole == 'PT') {
      roleDisplay = "Huấn luyện viên (PT)";
      roleColor = const Color(0xFFFCA311); // Màu cam
    } else if (userRole == 'Admin') {
      roleDisplay = "Quản trị viên";
      roleColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Profile
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 6),

                        // --- HIỂN THỊ ROLE Ở ĐÂY ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            roleDisplay,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roleColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Menu Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  }),
                  _buildMenuItem(Icons.lock_outline, "Đổi mật khẩu", () {}),

                  // Chỉ User mới thấy phần thanh toán
                  if (userRole == 'User')
                    _buildMenuItem(Icons.payment_outlined, "Phương thức thanh toán", () {}),

                  _buildMenuItem(Icons.sports, "Đăng ký trở thành PT", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PTRegistrationScreen()),
                    );
                  }),

                  // Chỉ PT mới thấy phần cài đặt lịch dạy
                  if (userRole == 'PT')
                    _buildMenuItem(Icons.schedule, "Cài đặt giờ làm việc", () {}),

                  _buildMenuItem(Icons.settings_outlined, "Cài đặt ứng dụng", () {}),
                  const Divider(height: 30),

                  // Nút Đăng xuất
                  _buildMenuItem(Icons.logout, "Đăng xuất", () async {
                    await _authService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF2E3B55)),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black87,
            fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}