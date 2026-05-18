import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart'; // Đã hướng về file độc lập của ông
import 'tabs/pending_pt_tab.dart';
import 'tabs/pt_list_tab.dart';
import 'tabs/user_list_tab.dart';
import 'tabs/booking_list_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("ADMIN DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          backgroundColor: const Color(0xFF2E3B55),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFFCA311),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Chờ duyệt"),
              Tab(text: "Huấn luyện viên (PT)"),
              Tab(text: "Học viên (User)"),
              Tab(text: "Lịch đặt (Booking)"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFCA311),
          onPressed: () => _showCreatePTDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: const TabBarView(
          children: [
            PendingPTTab(),
            PTListTab(),
            UserListTab(),
            BookingListTab(),
          ],
        ),
      ),
    );
  }

  static void _showCreatePTDialog(BuildContext context) {
    final name = TextEditingController();
    final spec = TextEditingController();
    final bio = TextEditingController();
    final exp = TextEditingController();
    String avatar = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (bottomSheetContext, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Thêm PT Trực Tiếp", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E3B55))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  // Gọi trực tiếp từ file service dùng chung của ông cực sạch
                  final url = await CloudinaryService.uploadImage();
                  if (url != null) setState(() => avatar = url);
                },
                child: Container(
                  height: 100, width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: avatar.isNotEmpty ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
                  ),
                  child: avatar.isEmpty ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey) : null,
                ),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: "Họ và tên")),
              TextField(controller: spec, decoration: const InputDecoration(labelText: "Chuyên môn")),
              TextField(controller: exp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số năm kinh nghiệm")),
              TextField(controller: bio, decoration: const InputDecoration(labelText: "Mô tả / Tiểu sử")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B55)),
                  onPressed: () async {
                    if (name.text.isEmpty) return;
                    await FirebaseFirestore.instance.collection('users').add({
                      'name': name.text.trim(),
                      'specialty': spec.text.trim(),
                      'experience': exp.text.trim(),
                      'bio': bio.text.trim(),
                      'avatar': avatar,
                      'role': 'PT',
                    });
                    if (bottomSheetContext.mounted) Navigator.pop(bottomSheetContext);
                  },
                  child: const Text("TẠO TÀI KHOẢN PT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}