import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class PTBookingManagementScreen extends StatefulWidget {
  const PTBookingManagementScreen({super.key});

  @override
  State<PTBookingManagementScreen> createState() => _PTBookingManagementScreenState();
}

class _PTBookingManagementScreenState extends State<PTBookingManagementScreen> {
  final BookingService _bookingService = BookingService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _translateDay(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday': return 'Thứ 2';
      case 'tuesday': return 'Thứ 3';
      case 'wednesday': return 'Thứ 4';
      case 'thursday': return 'Thứ 5';
      case 'friday': return 'Thứ 6';
      case 'saturday': return 'Thứ 7';
      case 'sunday': return 'Chủ nhật';
      default: return englishDay;
    }
  }
  Future<void> _handleUpdateStatus(String bookingId, String newStatus) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'confirmed' ? "Đã chấp nhận lịch tập!" : "Đã từ chối yêu cầu."),
            backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Lỗi cập nhật: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Yêu cầu đặt lịch"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pt_id', isEqualTo: _currentUser!.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("Không có yêu cầu nào mới."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              BookingModel booking = BookingModel.fromFirestore(docs[index]);

              // Lấy ID của học viên trực tiếp từ document để dò tìm (đề phòng Model chưa có)
              String studentId = docs[index]['user_id'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  // --- TUYỆT CHIÊU KÉO TÊN THẬT TỪ FIREBASE ---
                  title: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                    builder: (context, userSnapshot) {
                      // Đang load data
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Đang tải tên...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey));
                      }

                      // Nếu tìm thấy học viên
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        String realName = userData['name']?.toString() ?? "Học viên ẩn danh";
                        return Text(realName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                      }

                      // Lỡ học viên xóa acc hoặc lỗi
                      return Text(booking.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                    },
                  ),
                  // ---------------------------------------------

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Ngày: ${booking.bookingDate} (${_translateDay(booking.day)})"),
                      Text("Giờ tập: ${booking.timeSlot}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleUpdateStatus(booking.id, 'canceled'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleUpdateStatus(booking.id, 'confirmed'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}