import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Để chuyển trang khi logout

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser; // Giả sử bạn thêm getter trong auth_service (xem chú thích dưới)

    // Nếu chưa làm getter currentUser thì dùng tạm text tĩnh
    String displayName = user?.displayName ?? "Người dùng";
    String email = user?.email ?? "user@email.com";
    String? photoUrl = user?.photoURL;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(color: Colors.grey)),
                    ],
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
                  _buildMenuItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () {}),
                  _buildMenuItem(Icons.lock_outline, "Đổi mật khẩu", () {}),
                  _buildMenuItem(Icons.payment_outlined, "Phương thức thanh toán", () {}),
                  _buildMenuItem(Icons.settings_outlined, "Cài đặt ứng dụng", () {}),
                  const Divider(height: 30),

                  // Nút Đăng xuất
                  _buildMenuItem(Icons.logout, "Đăng xuất", () async {
                    // Xử lý đăng xuất
                    await _authService.logout();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false, // Xóa sạch lịch sử back
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

  // Widget con để vẽ dòng menu
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