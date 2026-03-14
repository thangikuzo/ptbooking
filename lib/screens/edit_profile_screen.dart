import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'splash_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'Nam';
  bool _isLoading = false;
  bool _isFetching = true;

  // ---- BIẾN CHO AVATAR ----
  String _currentAvatarUrl = ''; // Link ảnh mạng
  bool _isUploadingAvatar = false; // Vòng xoay lúc up ảnh
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          setState(() {
            _nameController.text = data?['name'] ?? '';
            _phoneController.text = data?['phone'] ?? '';
            _ageController.text = data?['age']?.toString() ?? '';
            _heightController.text = data?['height']?.toString() ?? '';
            _weightController.text = data?['weight']?.toString() ?? '';
            _addressController.text = data?['address'] ?? '';

            // Lấy link Avatar hiện tại
            _currentAvatarUrl = data?['avatar'] ?? '';

            if (data?['gender'] != null && ['Nam', 'Nữ', 'Khác'].contains(data?['gender'])) {
              _selectedGender = data?['gender'];
            }
            _isFetching = false;
          });
        }
      } catch (e) {
        debugPrint("Lỗi tải dữ liệu: $e");
        setState(() => _isFetching = false);
      }
    }
  }

  // ---- HÀM CHỌN VÀ UP ẢNH LÊN CLOUDINARY ----
  Future<void> _pickAndUploadAvatar() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() { _isUploadingAvatar = true; });

      try {
        // Chú ý: api.cloudinary.com/v1_1/.../image/upload (dùng image thay vì video)
        var uri = Uri.parse('https://api.cloudinary.com/v1_1/dkjq5ojmn/image/upload');
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = 'challenge_video_upload'; // Dùng tạm preset cũ vẫn xài được cho ảnh
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseData);

          setState(() {
            _currentAvatarUrl = jsonResponse['secure_url']; // Đổi link ảnh mới
            _isUploadingAvatar = false;
          });

          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tải ảnh lên thành công! Nhớ bấm Lưu thay đổi."), backgroundColor: Colors.green));
          }
        } else {
          setState(() { _isUploadingAvatar = false; });
          debugPrint("Lỗi Cloudinary: ${response.statusCode}");
        }
      } catch (e) {
        setState(() { _isUploadingAvatar = false; });
        debugPrint("Lỗi up ảnh: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
          'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
          'address': _addressController.text.trim(),
          'avatar': _currentAvatarUrl, // LƯU LINK AVATAR MỚI VÀO DB
        });

        await user.updateDisplayName(_nameController.text.trim());
        if (_currentAvatarUrl.isNotEmpty) {
          await user.updatePhotoURL(_currentAvatarUrl); // Update luôn vào Auth cho chắc cú
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật hồ sơ thành công!"), backgroundColor: Colors.green));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SplashScreen()), (route) => false);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Chỉnh sửa hồ sơ"), backgroundColor: const Color(0xFF2E3B55), elevation: 0),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- KHU VỰC AVATAR CÓ THỂ BẤM ĐƯỢC ---
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _currentAvatarUrl.isNotEmpty ? NetworkImage(_currentAvatarUrl) : null,
                      child: _isUploadingAvatar
                          ? const CircularProgressIndicator(color: Colors.white) // Đang up thì xoay xoay
                          : (_currentAvatarUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFCA311), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(controller: _nameController, label: "Họ và tên", icon: Icons.person_outline, validator: (val) => val!.isEmpty ? "Vui lòng nhập tên" : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: "Số điện thoại", icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(labelText: "Giới tính", prefixIcon: const Icon(Icons.wc), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: ['Nam', 'Nữ', 'Khác'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                      onChanged: (newValue) => setState(() => _selectedGender = newValue!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildTextField(controller: _ageController, label: "Tuổi", icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _heightController, label: "Chiều cao (cm)", icon: Icons.height, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: _weightController, label: "Cân nặng (kg)", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(controller: _addressController, label: "Địa chỉ", icon: Icons.location_on_outlined),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}