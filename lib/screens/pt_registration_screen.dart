import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'splash_screen.dart'; // Import để reload lại app

class PTRegistrationScreen extends StatefulWidget {
  const PTRegistrationScreen({super.key});

  @override
  State<PTRegistrationScreen> createState() => _PTRegistrationScreenState();
}

class _PTRegistrationScreenState extends State<PTRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // 1. Cập nhật dữ liệu lên Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'role': 'Pending_PT', // Đổi Role thành chờ duyệt
          'experience': _experienceController.text.trim(), // Lưu năm kinh nghiệm
          'specialty': _specialtyController.text.trim(), // Lưu chuyên môn (Gym, Yoga...)
          'bio': _bioController.text.trim(), // Lưu giới thiệu bản thân
          'appliedAt': DateTime.now(), // Thời gian nộp đơn
        });

        if (mounted) {
          // 2. Báo thành công và Load lại app từ màn hình Splash
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nộp hồ sơ thành công! Vui lòng chờ duyệt."), backgroundColor: Colors.green),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false, // Xóa sạch lịch sử để reload lại Role mới
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký làm PT"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Điền thông tin chuyên môn",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E3B55)),
              ),
              const SizedBox(height: 10),
              const Text("Hồ sơ của bạn sẽ được Admin xét duyệt trước khi bạn có thể bắt đầu nhận học viên.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // Form điền kinh nghiệm
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số năm kinh nghiệm", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập số năm kinh nghiệm" : null,
              ),
              const SizedBox(height: 16),

              // Form điền chuyên môn
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: "Chuyên môn (Ví dụ: Gym, Yoga, Boxing)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập chuyên môn" : null,
              ),
              const SizedBox(height: 16),

              // Form điền giới thiệu
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Giới thiệu bản thân & Thành tích", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Vui lòng viết vài dòng giới thiệu" : null,
              ),
              const SizedBox(height: 32),

              // Nút Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCA311),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),



                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GỬI HỒ SƠ XÉT DUYỆT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}