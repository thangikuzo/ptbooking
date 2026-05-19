import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import 'chat_screen.dart';

class PTTeachingScheduleScreen extends StatelessWidget {
  const PTTeachingScheduleScreen({super.key});

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

  // 🔥 HÀM TÍNH THỜI GIAN ĐÃ TRÔI QUA
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
      'last_sender_id': '', // Trường này lưu ID người gửi cuối cùng để phân biệt ai gửi
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return chatDoc.id;
  }

  Stream<QuerySnapshot> _chatStream(BookingModel booking) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('customer_id', isEqualTo: booking.userId)
        .where('pt_id', isEqualTo: booking.ptId)
        .limit(1)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Vui lòng đăng nhập")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch dạy của tôi"),
        backgroundColor: const Color(0xFF2E3B55),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pt_id', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'confirmed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("Bạn chưa có lịch dạy nào được chốt."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final booking = BookingModel.fromFirestore(docs[index]);

              return StreamBuilder<QuerySnapshot>(
                stream: _chatStream(booking),
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
                      // Tự động kiểm tra ai gửi để ghép chữ "Bạn: " hoặc "Tên: "
                      String prefix = (lastSenderId == currentUser.uid) ? "Bạn: " : "${booking.userName}: ";
                      displayMessage = "$prefix$lastMessage";
                      timeAgo = _formatTimeAgo(updatedAt);
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        "Học viên: ${booking.userName}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            "${_translateDay(booking.day)} (${booking.bookingDate}) | ${booking.timeSlot}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.message,
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
                              // HIỂN THỊ THỜI GIAN BÊN PHẢI
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
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () async {
                          final chatId = await _createOrGetChatRoom(booking);

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chatId: chatId),
                              ),
                            );
                          }
                        },
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