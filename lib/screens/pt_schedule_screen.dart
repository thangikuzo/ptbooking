import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';

class PTScheduleScreen extends StatefulWidget {
  const PTScheduleScreen({super.key});

  @override
  State<PTScheduleScreen> createState() => _PTScheduleScreenState();
}

class _PTScheduleScreenState extends State<PTScheduleScreen> {
  bool _isLoading = false;

  // Các khung giờ mặc định để chọn
  final List<String> _timeSlots = [
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
  ];

  // Map lưu trữ các khung giờ đã chọn cho từng thứ
  Map<String, List<String>> _selectedAvailability = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  final Map<String, String> _dayLabels = {
    'monday': 'Thứ 2',
    'tuesday': 'Thứ 3',
    'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5',
    'friday': 'Thứ 6',
    'saturday': 'Thứ 7',
    'sunday': 'Chủ Nhật',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  // Load lại lịch cũ nếu đã có trong DB
  Future<void> _loadCurrentSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('schedules').doc(user.uid).get();
      if (doc.exists && doc.data()?['availability'] != null) {
        setState(() {
          Map<String, dynamic> data = doc.data()?['availability'];
          data.forEach((key, value) {
            _selectedAvailability[key] = List<String>.from(value);
          });
        });
      }
    }
  }

  Future<void> _saveSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    // --- THÊM ĐOẠN CHECK NULL NÀY VÀO ---
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi: Chưa đăng nhập!"), backgroundColor: Colors.red));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Lúc này Dart biết chắc chắn user không null nữa, gọi user.uid thoải mái
      await FirebaseFirestore.instance.collection('schedules').doc(user.uid).set({
        'pt_id': user.uid,
        'availability': _selectedAvailability,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã lưu lịch làm việc!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      print("Lỗi lưu lịch: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt giờ làm việc"),

        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(onPressed: _saveSchedule, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _selectedAvailability.keys.map((dayKey) {
          return _buildDaySection(dayKey);
        }).toList(),
      ),
    );
  }

  Widget _buildDaySection(String dayKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_dayLabels[dayKey]!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          children: _timeSlots.map((slot) {
            bool isSelected = _selectedAvailability[dayKey]!.contains(slot);
            return FilterChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedAvailability[dayKey]!.add(slot);
                    _selectedAvailability[dayKey]!.sort(); // Sắp xếp cho thứ tự đẹp
                  } else {
                    _selectedAvailability[dayKey]!.remove(slot);
                  }
                });
              },
            );
          }).toList(),
        ),
        const Divider(height: 30),
      ],
    );
  }
}
