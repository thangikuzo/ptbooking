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

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(studentId).get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      return data['name']?.toString() ?? fallbackName;
    }

    return fallbackName;
  }

  Future<void> _updateManyBookingsStatus(
      List<BookingModel> bookings,
      String newStatus,
      ) async {
    try {
      for (final booking in bookings) {
        await _bookingService.updateBookingStatus(booking.id, newStatus);
      }

      if (newStatus == 'confirmed') {
        final chatId = await _createOrGetChatRoom(booking: bookings.first);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã chấp nhận ${bookings.length} lịch tập!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(chatId: chatId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã từ chối ${bookings.length} yêu cầu."),
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

  Map<String, List<BookingModel>> _groupBookingsByUser(
      List<QueryDocumentSnapshot> docs,
      ) {
    final Map<String, List<BookingModel>> grouped = {};

    for (final doc in docs) {
      final booking = BookingModel.fromFirestore(doc);
      final userId = booking.userId;

      if (userId.isEmpty) continue;

      grouped.putIfAbsent(userId, () => []);
      grouped[userId]!.add(booking);
    }

    return grouped;
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

          final groupedBookings = _groupBookingsByUser(docs);
          final userIds = groupedBookings.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final userId = userIds[index];
              final bookings = groupedBookings[userId]!;
              final firstBooking = bookings.first;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: const Icon(
                          Icons.person,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getStudentName(
                                userId,
                                firstBooking.userName,
                              ),
                              builder: (context, userSnapshot) {
                                final name =
                                    userSnapshot.data ?? firstBooking.userName;

                                return Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),

                            Text(
                              "${bookings.length} yêu cầu đặt lịch",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            ...bookings.map((booking) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "• ${booking.bookingDate} (${_translateDay(booking.day)}) | ${booking.timeSlot}",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            onPressed: () => _updateManyBookingsStatus(
                              bookings,
                              'canceled',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _updateManyBookingsStatus(
                              bookings,
                              'confirmed',
                            ),
                          ),
                        ],
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