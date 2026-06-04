import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:ptbooking/features/auth/widgets/edit_avatar_section.dart';
import 'package:ptbooking/features/auth/widgets/edit_form_section.dart';
import 'package:ptbooking/features/auth/widgets/edit_pt_section.dart';
import 'package:ptbooking/features/auth/widgets/edit_save_button.dart';

import 'package:ptbooking/features/home/screens/splash_screen.dart';
import 'package:ptbooking/features/gamification/screens/inventory_screen.dart';

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
  String? _selectedFrame;
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
        _selectedFrame = user.selectedFrame;
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
        await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).update(updateData);

        await firebaseUser.updateDisplayName(_nameController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Cập nhật hồ sơ thành công!"), backgroundColor: Colors.green));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Chỉnh sửa hồ sơ"), backgroundColor: const Color(0xFF0B2447)),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    EditAvatarSection(
                      avatarUrl: _avatarUrl,
                      imageFile: _imageFile,
                      onPickImage: _pickImage,
                      onFrameChanged: () {},
                    ),
                    const SizedBox(height: 32),
                    EditFormSection(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      selectedGender: _selectedGender,
                      onGenderChanged: (val) => setState(() => _selectedGender = val),
                      ageController: _ageController,
                      heightController: _heightController,
                      weightController: _weightController,
                      addressController: _addressController,
                    ),
                    if (_userRole == 'PT')
                      EditPtSection(
                        specialtyController: _specialtyController,
                        experienceController: _experienceController,
                        bioController: _bioController,
                      ),
                    const SizedBox(height: 40),
                    EditSaveButton(
                      isLoading: _isLoading,
                      onSave: _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
