import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ptbooking/screens/splash_screen.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart'; // File này vừa được tạo tự động

import 'services/notification_service.dart'; // Thêm import này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Notification Service
  await NotificationService().init();

  await GoogleSignIn.instance.initialize(
    serverClientId: "501388421930-610ost62oop0k4vu1p6pgigh1ej0s65p.apps.googleusercontent.com", // Web Client ID của bạn
    // scopes: ['email', 'profile'], // Nếu cần thêm scopes (mặc định đã có)
  );
  runApp(
    MaterialApp(
      home: const SplashScreen(), // Đổi sang SplashScreen để check login tự động luôn sếp nhé
      debugShowCheckedModeBanner: false,

      // 🔥 THÊM ĐOẠN THEME NÀY VÀO ĐỂ QUẢN LÝ APPBAR TOÀN HỆ THỐNG
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primaryDark,
          elevation: 0.5,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primaryDark),
          titleTextStyle: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );
}
