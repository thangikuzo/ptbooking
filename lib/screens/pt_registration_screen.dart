import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PTRegistrationScreen extends StatefulWidget {
  const PTRegistrationScreen({super.key});

  @override
  State<PTRegistrationScreen> createState() =>
      _PTRegistrationScreenState();
}

class _PTRegistrationScreenState
    extends State<PTRegistrationScreen> {

  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();

  File? _avatarFile;
  bool _isLoading = false;

  /// 📅 LỊCH
  final List<String> weekdays =
  ["T2","T3","T4","T5","T6","T7","CN"];

  final Set<int> selectedDays = {};

  /// ===================================================
  /// 🖼 CHỌN AVATAR
  /// ===================================================
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  /// ===================================================
  /// 🚀 SUBMIT
  /// ===================================================
  Future<void> _submitApplication() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String avatarUrl = "";

      /// 🔥 UPLOAD AVATAR
      if (_avatarFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("avatars/${user.uid}.jpg");

        await ref.putFile(_avatarFile!);

        avatarUrl = await ref.getDownloadURL();
      }

      /// 🔥 CONVERT LỊCH
      Map<String, bool> schedule = {
        for (var d in weekdays)
          d: selectedDays.contains(weekdays.indexOf(d))
      };

      /// 🔥 UPDATE FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({

        'role': 'pending_pt',

        'experience': _experienceController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'bio': _bioController.text.trim(),

        'avatar': avatarUrl,
        'schedule': schedule,

        'appliedAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Nộp hồ sơ thành công!"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  /// ===================================================
  /// 🧱 UI
  /// ===================================================
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
            children: [

              /// 🖼 AVATAR
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : null,
                  child: _avatarFile == null
                      ? const Icon(Icons.add_a_photo,
                      size: 30)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              /// EXPERIENCE
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                    labelText: "Số năm kinh nghiệm",
                    border: OutlineInputBorder()),
                validator: (v) =>
                v!.isEmpty ? "Nhập kinh nghiệm" : null,
              ),

              const SizedBox(height: 16),

              /// SPECIALTY
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                    labelText: "Chuyên môn",
                    border: OutlineInputBorder()),
                validator: (v) =>
                v!.isEmpty ? "Nhập chuyên môn" : null,
              ),

              const SizedBox(height: 16),

              /// BIO
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "Giới thiệu",
                    border: OutlineInputBorder()),
                validator: (v) =>
                v!.isEmpty ? "Nhập giới thiệu" : null,
              ),

              const SizedBox(height: 20),

              /// 📅 LỊCH
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Chọn lịch dạy",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                children: List.generate(
                  weekdays.length,
                      (i) {
                    final selected =
                    selectedDays.contains(i);

                    return ChoiceChip(
                      label: Text(weekdays[i]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? selectedDays.remove(i)
                              : selectedDays.add(i);
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              /// SUBMIT
              ElevatedButton(
                onPressed:
                _isLoading ? null : _submitApplication,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("GỬI HỒ SƠ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
