import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'splash_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();

  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedGender = 'Nam';
  String? _userRole;
  String? _avatarUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    UserModel? user = await _authService.getUserData();
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
        _ageController.text = user.age?.toString() ?? '';
        _heightController.text = user.height?.toString() ?? '';
        _weightController.text = user.weight?.toString() ?? '';
        _addressController.text = user.address ?? '';

        _specialtyController.text = user.specialty ?? '';
        _experienceController.text = user.experience ?? '';
        _bioController.text = user.bio ?? '';

        _selectedGender = user.gender ?? 'Nam';
        _userRole = user.role;
        _avatarUrl = user.avatar;
        _isFetching = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_imageFile == null) return _avatarUrl;

    final url = Uri.parse('https://api.cloudinary.com/v1_1/dh4rmz7z0/image/upload');
    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'avatar_preset'
      ..fields['folder'] = 'pt_booking/avatars'
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonMap = jsonDecode(responseData);
      return jsonMap['secure_url'];
    } else {
      throw Exception("Lỗi khi up ảnh lên Cloudinary");
    }
  }

  // --- HÀM LƯU ĐÃ ĐƯỢC FIX LỖI "MẤT TRÍ NHỚ" DỮ LIỆU ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        // 1. Up ảnh lấy link trước
        String? finalAvatarUrl = await _uploadToCloudinary();

        // 2. CHỈ TẠO MAP NHỮNG TRƯỜNG CẦN CẬP NHẬT TRÊN MÀN HÌNH NÀY
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'age': int.tryParse(_ageController.text.trim()),
          'height': double.tryParse(_heightController.text.trim()),
          'weight': double.tryParse(_weightController.text.trim()),
          'address': _addressController.text.trim(),
        };

        // Nếu có avatar mới hoặc avatar cũ thì mới thêm vào map
        if (finalAvatarUrl != null) {
          updateData['avatar'] = finalAvatarUrl;
        }
        // Nếu là PT thì mới cập nhật thêm 3 trường này
        if (_userRole == 'PT') {
          updateData['specialty'] = _specialtyController.text.trim();
          updateData['experience'] = _experienceController.text.trim();
          updateData['bio'] = _bioController.text.trim();
        }

        // 3. Đẩy đúng cái Map này lên, Firebase sẽ CHỈ sửa những dòng này, CÒN LẠI GIỮ NGUYÊN
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update(updateData);

        await firebaseUser.updateDisplayName(_nameController.text.trim());

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
      appBar: AppBar(title: const Text("Chỉnh sửa hồ sơ"), backgroundColor: const Color(0xFF2E3B55)),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 32),
              _buildTextField(controller: _nameController, label: "Họ và tên", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: "Số điện thoại", icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildGenderAgeRow(),
              const SizedBox(height: 16),
              _buildBodyMetricsRow(),
              const SizedBox(height: 16),
              _buildTextField(controller: _addressController, label: "Địa chỉ", icon: Icons.location_on_outlined),

              if (_userRole == 'PT') ...[
                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 16),
                const Text("Thông tin Huấn luyện viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3B55))),
                const SizedBox(height: 16),
                _buildTextField(controller: _specialtyController, label: "Chuyên môn (VD: Gym, Yoga...)", icon: Icons.fitness_center),
                const SizedBox(height: 16),
                _buildTextField(controller: _experienceController, label: "Số năm kinh nghiệm", icon: Icons.star_border, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Giới thiệu bản thân",
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 30), // Đẩy icon lên trên cùng
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!) as ImageProvider
                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ? NetworkImage(_avatarUrl!)
                : null,
            child: (_imageFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFCA311), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)
          ),
        ],
      ),
    );
  }

  Widget _buildGenderAgeRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(labelText: "Giới tính", prefixIcon: const Icon(Icons.wc), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ['Nam', 'Nữ', 'Khác'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedGender = val!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildTextField(controller: _ageController, label: "Tuổi", icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
      ],
    );
  }

  Widget _buildBodyMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildTextField(controller: _heightController, label: "Cao (cm)", icon: Icons.height, keyboardType: TextInputType.number)),
        const SizedBox(width: 16),
        Expanded(child: _buildTextField(controller: _weightController, label: "Nặng (kg)", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}