import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class PTTeachingScheduleScreen extends StatelessWidget {
  const PTTeachingScheduleScreen({super.key});

  String _translateDay(String day) {
    const days = {
      'monday': 'Thứ 2', 'tuesday': 'Thứ 3', 'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5', 'friday': 'Thứ 6', 'saturday': 'Thứ 7', 'sunday': 'Chủ Nhật',
    };
    return days[day] ?? day;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch dạy của tôi"),
        backgroundColor: const Color(0xFF2E3B55),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Chỉ lấy những đơn đã 'confirmed'
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pt_id', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'confirmed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa có lịch dạy nào được chốt."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Sử dụng Model để bóc tách dữ liệu
              BookingModel booking = BookingModel.fromFirestore(docs[index]);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  title: Text("Học viên: ${booking.userName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        "${_translateDay(booking.day)} (${booking.bookingDate}) | ${booking.timeSlot}",
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                ),
              );
            },
          );
        },
      ),
    );
  }
}