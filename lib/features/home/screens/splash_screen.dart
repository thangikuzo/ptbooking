import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/auth/services/auth_service.dart';
import 'package:ptbooking/core/widgets/main_wrapper.dart';
import 'package:ptbooking/features/auth/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginAndRole();
  }

  void _checkLoginAndRole() async {
    // Đợi 1.5 giây cho hiệu ứng khởi động
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Đã đăng nhập -> Lấy Role -> Vào App (Giới hạn timeout 5s đề phòng kết nối mạng chậm/treo)
        String? role;
        try {
          role = await _authService.getUserRole().timeout(
            const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint("Lỗi lấy user role hoặc hết thời gian chờ: $e");
          role = 'User'; // Gán mặc định nếu lỗi/timeout để người dùng vẫn vào được app
        }
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper(userRole: role ?? 'User')));
        }
      } else {
        // Chưa đăng nhập -> Ra màn hình Login
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
        }
      }
    } catch (e) {
      debugPrint("Splash checkLoginAndRole error: $e");
      // Nếu có lỗi hệ thống nghiêm trọng, đăng xuất và đẩy ra màn hình đăng nhập
      try {
        await _authService.logout();
      } catch (_) {}
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "PT BOOKING",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
