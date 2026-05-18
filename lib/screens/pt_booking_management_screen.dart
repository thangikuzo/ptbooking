import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'chat_screen.dart';

class PTBookingManagementScreen extends StatefulWidget {
  const PTBookingManagementScreen({super.key});

  @override
  State<PTBookingManagementScreen> createState() =>
      _PTBookingManagementScreenState();
}

class _PTBookingManagementScreenState
    extends State<PTBookingManagementScreen> {
  final BookingService _bookingService = BookingService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _translateDay(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday':
        return 'Thứ 2';
      case 'tuesday':
        return 'Thứ 3';
      case 'wednesday':
        return 'Thứ 4';
      case 'thursday':
        return 'Thứ 5';
      case 'friday':
        return 'Thứ 6';
      case 'saturday':
        return 'Thứ 7';
      case 'sunday':
        return 'Chủ nhật';
      default:
        return englishDay;
    }
  }

  Future<String> _createOrGetChatRoom({
    required BookingModel booking,
  }) async {
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('customer_id', isEqualTo: booking.userId)
        .where('pt_id', isEqualTo: booking.ptId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    }

    final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
      'customer_id': booking.userId,
      'customer_name': booking.userName,
      'pt_id': booking.ptId,
      'pt_name': booking.ptName,
      'booking_id': booking.id,
      'last_message': '',
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    return chatDoc.id;
  }

  Future<String> _getStudentName(String studentId, String fallbackName) async {
    if (studentId.isEmpty) return fallbackName;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      return data['name']?.toString() ?? fallbackName;
    }

    return fallbackName;
  }

  Future<void> _handleUpdateStatus(
      BookingModel booking,
      String newStatus,
      ) async {
    try {
      await _bookingService.updateBookingStatus(
        booking.id,
        newStatus,
      );

      if (newStatus == 'confirmed') {
        final chatId = await _createOrGetChatRoom(
          booking: booking,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã chấp nhận lịch tập!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã từ chối yêu cầu."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Vui lòng đăng nhập"),
        ),
      );
    }

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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("Không có yêu cầu nào mới."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final booking = BookingModel.fromFirestore(docs[index]);
              final studentId = booking.userId;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  title: FutureBuilder<String>(
                    future: _getStudentName(studentId, booking.userName),
                    builder: (context, userSnapshot) {
                      final name = userSnapshot.data ?? booking.userName;

                      return Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Ngày: ${booking.bookingDate} (${_translateDay(booking.day)})",
                      ),
                      Text(
                        "Giờ tập: ${booking.timeSlot}",
                      ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                        onPressed: () => _handleUpdateStatus(
                          booking,
                          'canceled',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => _handleUpdateStatus(
                          booking,
                          'confirmed',
                        ),
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