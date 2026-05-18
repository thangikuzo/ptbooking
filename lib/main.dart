import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; // File này vừa được tạo tự động
import 'screens/login_screen.dart';
import 'screens/challenge_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );
  await GoogleSignIn.instance.initialize(
      serverClientId: "501388421930-610ost62oop0k4vu1p6pgigh1ej0s65p.apps.googleusercontent.com",  // Web Client ID của bạn
      // scopes: ['email', 'profile'], // Nếu cần thêm scopes (mặc định đã có)
  );
  runApp(MaterialApp(
    home: LoginScreen(), // Bay thẳng vào màn hình Thử thách!
    debugShowCheckedModeBanner: false, // Tiện tay tắt luôn cái chữ DEBUG đỏ chót ở góc cho màn hình nó sạch
  ));
}