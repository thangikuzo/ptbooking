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

  // Hàm xử lý duyệt hoặc từ chối thông qua Service
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
        // Lọc các đơn 'pending' dành cho PT này
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
              // Ép kiểu sang BookingModel
              BookingModel booking = BookingModel.fromFirestore(docs[index]);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(booking.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Ngày: ${booking.bookingDate} (${booking.day})"),
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