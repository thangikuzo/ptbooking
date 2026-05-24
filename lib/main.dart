import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ptbooking/screens/splash_screen.dart';
import 'firebase_options.dart'; // File này vừa được tạo tự động

import 'services/notification_service.dart'; // Thêm import này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Khởi tạo Notification Service
  await NotificationService().init();

  await GoogleSignIn.instance.initialize(
      serverClientId: "501388421930-610ost62oop0k4vu1p6pgigh1ej0s65p.apps.googleusercontent.com",  // Web Client ID của bạn
      // scopes: ['email', 'profile'], // Nếu cần thêm scopes (mặc định đã có)
  );
  runApp(MaterialApp(
    home: const SplashScreen(), // Đổi sang SplashScreen để check login tự động luôn sếp nhé
    debugShowCheckedModeBanner: false,

    // 🔥 THÊM ĐOẠN THEME NÀY VÀO ĐỂ QUẢN LÝ APPBAR TOÀN HỆ THỐNG
    theme: ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, // Ép nền AppBar tất cả các màn hình thành màu trắng
        elevation: 0.5,                // Độ nổi bóng đổ nhẹ nhàng, hiện đại
        centerTitle: true,             // Tất cả tiêu đề tự động căn giữa
        iconTheme: IconThemeData(color: Color(0xFF2E3B55)), // Icon điều hướng (nút back, menu) màu tối rõ ràng
        titleTextStyle: TextStyle(
          color: Color(0xFF2E3B55),    // Chữ tiêu đề màu tối cực kỳ dễ đọc
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ));
}