import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart'; // <-- ĐÃ IMPORT MODEL

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _translateDay(String day) {
    const days = {
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',
      'sunday': 'Chủ Nhật',
    };
    return days[day] ?? day;
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'Đã chốt lịch';
        break;
      case 'canceled':
        color = Colors.red;
        text = 'Bị từ chối/Hủy';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Đã hoàn thành';
        break;
      default:
        color = Colors.grey;
        text = 'Không rõ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color = Colors.grey;
    String text = 'Chưa thanh toán';

    switch (status) {
      case 'held':
        color = Colors.blue;
        text = 'Đã giữ tiền trong ví';
        break;
      case 'paid':
        color = Colors.green;
        text = 'Đã thanh toán';
        break;
      case 'refunded_to_wallet':
        color = Colors.teal;
        text = 'Đã hoàn về ví';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập để xem lịch sử")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Lịch sử đặt lịch")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('user_id', isEqualTo: currentUser.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Bạn chưa có lịch đặt nào.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // --- SỰ KHÁC BIỆT NẰM Ở ĐÂY ---
              // Ép kiểu dữ liệu Firebase thành Đối tượng BookingModel
              BookingModel booking = BookingModel.fromFirestore(docs[index]);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fitness_center, color: Color(0xFF2E3B55)),
                  ),

                  // Lúc này gọi ra xài cực kỳ sướng và an toàn
                  title: Text(
                    "PT: ${booking.ptName}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          // Lấy ngày và giờ từ Model
                          Text("${_translateDay(booking.day)} (${booking.bookingDate}) | ${booking.timeSlot}"),
                        ],
                      ),
                      if (booking.packageName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Gói tập: ${booking.packageName} (${booking.sessionCount} buổi)",
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [_buildStatusBadge(booking.status), _buildPaymentBadge(booking.paymentStatus)],
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
