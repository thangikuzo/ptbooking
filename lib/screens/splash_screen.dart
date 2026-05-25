import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/main_wrapper.dart';
import 'login_screen.dart';

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

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Đã đăng nhập -> Lấy Role -> Vào App
      String? role = await _authService.getUserRole();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper(userRole: role ?? 'User')));
      }
    } else {
      // Chưa đăng nhập -> Ra màn hình Login
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
