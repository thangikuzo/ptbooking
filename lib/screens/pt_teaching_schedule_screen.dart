import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import 'chat_screen.dart';

class PTTeachingScheduleScreen extends StatelessWidget {
  const PTTeachingScheduleScreen({super.key});

  String _translateDay(String day) {
    const days = {
      'monday': 'Thứ 2', 'tuesday': 'Thứ 3', 'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5', 'friday': 'Thứ 6', 'saturday': 'Thứ 7', 'sunday': 'Chủ Nhật',
    };
    return days[day] ?? day;
  }

  // 🔥 KHÔI PHỤC LẠI HÀM TÍNH THỜI GIAN
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<String> _createOrGetChatRoom(BookingModel booking) async {
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
      'last_sender_id': '',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return chatDoc.id;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Lịch dạy của tôi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF2E3B55),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pt_id', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'confirmed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFCA311)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa có ca dạy nào được chốt.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          // GỘP LỊCH THEO HỌC VIÊN
          Map<String, List<BookingModel>> userBookingsMap = {};
          for (var doc in docs) {
            final booking = BookingModel.fromFirestore(doc);
            if (!userBookingsMap.containsKey(booking.userId)) {
              userBookingsMap[booking.userId] = [];
            }
            userBookingsMap[booking.userId]!.add(booking);
          }

          List<String> userIds = userBookingsMap.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              String userId = userIds[index];
              List<BookingModel> bookings = userBookingsMap[userId]!;
              BookingModel firstBooking = bookings.first;

              // Gộp tiếp theo Ngày
              Map<String, List<BookingModel>> dateMap = {};
              for (var b in bookings) {
                if (!dateMap.containsKey(b.bookingDate)) dateMap[b.bookingDate] = [];
                dateMap[b.bookingDate]!.add(b);
              }

              List<String> sortedDates = dateMap.keys.toList();
              sortedDates.sort();

              // 🔥 LẮP LUỒNG ĐỌC TIN NHẮN (Mỗi học viên 1 luồng duy nhất)
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('customer_id', isEqualTo: userId)
                    .where('pt_id', isEqualTo: currentUser.uid)
                    .limit(1)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  String displayMessage = "Chưa có tin nhắn";
                  String timeAgo = "";
                  bool hasMessage = false;

                  if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
                    final chatData = chatSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final lastMessage = chatData['last_message'] ?? '';
                    final lastSenderId = chatData['last_sender_id'] ?? '';
                    final Timestamp? updatedAt = chatData['updated_at'] as Timestamp?;

                    if (lastMessage.toString().isNotEmpty) {
                      hasMessage = true;
                      String prefix = (lastSenderId == currentUser.uid) ? "Bạn: " : "${firstBooking.userName}: ";
                      displayMessage = "$prefix$lastMessage";
                      timeAgo = _formatTimeAgo(updatedAt);
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.green, size: 28),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Học viên: ${firstBooking.userName}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E2937)),
                                ),
                                const SizedBox(height: 12),

                                // Danh sách Lịch tập đã gộp
                                ...sortedDates.map((date) {
                                  List<BookingModel> dailyBookings = dateMap[date]!;
                                  dailyBookings.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
                                  String times = dailyBookings.map((e) => e.timeSlot).join(', ');
                                  String dayName = _translateDay(dailyBookings.first.day);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Icon(Icons.calendar_month, size: 14, color: Colors.orange),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "$dayName ($date): $times",
                                            style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const SizedBox(height: 4),
                                const Divider(height: 16, thickness: 0.5, color: Colors.black12),

                                // 🔥 KHU VỰC HIỂN THỊ TIN NHẮN
                                Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 14,
                                      color: hasMessage ? Colors.blueAccent : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        displayMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: hasMessage ? Colors.black87 : Colors.grey,
                                          fontWeight: hasMessage ? FontWeight.w500 : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (timeAgo.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        timeAgo,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Nút Chat bự bên phải
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent, size: 22),
                              onPressed: () async {
                                final chatId = await _createOrGetChatRoom(firstBooking);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}