import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'splash_screen.dart';

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

  File? _cvImage;
  File? _certImage;
  bool _isLoading = false;

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        if (type == 'cv') {
          _cvImage = File(pickedFile.path);
        } else if (type == 'cert') {
          _certImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dh4rmz7z0/image/upload');
    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'avatar_preset'
      ..fields['folder'] = 'pt_booking/documents'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData)['secure_url'];
    }
    return null;
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_certImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng tải lên ít nhất 1 ảnh Bằng cấp / Chứng chỉ!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String? certUrl = await _uploadImage(_certImage!);
        String? cvUrl = _cvImage != null ? await _uploadImage(_cvImage!) : null;

        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'role': 'Pending_PT',
          'experience': _experienceController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'bio': _bioController.text.trim(),
          'certificate_url': certUrl,
          if (cvUrl != null) 'cv_url': cvUrl,
          'appliedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nộp hồ sơ thành công! Vui lòng chờ duyệt."), backgroundColor: Colors.green),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Cập nhật nền trắng
      appBar: AppBar(
        title: const Text("Đăng ký làm PT"),
        // Đã xóa backgroundColor để ăn theo Theme trắng của main.dart
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24), // Tăng padding lên 24 cho thoáng
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Điền thông tin chuyên môn", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E3B55))),
              const SizedBox(height: 10),
              const Text("Hồ sơ của bạn sẽ được Admin xét duyệt trước khi bạn có thể bắt đầu nhận học viên.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Số năm kinh nghiệm",
                    prefixIcon: const Icon(Icons.star_border),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập số năm kinh nghiệm" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                    labelText: "Chuyên môn (Ví dụ: Gym, Yoga, Boxing)",
                    prefixIcon: const Icon(Icons.fitness_center),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập chuyên môn" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: "Giới thiệu bản thân & Thành tích",
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50), // Đẩy icon lên trên
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? "Vui lòng viết vài dòng giới thiệu" : null,
              ),
              const SizedBox(height: 30),

              const Text("Hồ sơ đính kèm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3B55))),
              const SizedBox(height: 16),

              _buildImagePicker("Bằng cấp / Chứng chỉ (Bắt buộc)", _certImage, () => _pickImage('cert')),
              const SizedBox(height: 16),
              _buildImagePicker("Ảnh CV / Sơ yếu lý lịch (Tùy chọn)", _cvImage, () => _pickImage('cv')),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCA311),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GỬI HỒ SƠ XÉT DUYỆT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String title, File? imageFile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(imageFile, fit: BoxFit.cover, width: double.infinity),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined, size: 30, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}