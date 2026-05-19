import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_room_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return "${dateTime.day}/${dateTime.month}";
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Tin nhắn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF2E3B55),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 FIX LỖI: Chuyển lại thành 'customer_id' để nó tìm ra đúng phòng chat
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('customer_id', isEqualTo: currentUser.uid)
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
                  Icon(Icons.chat_bubble_outline_rounded, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa có cuộc trò chuyện nào.", style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chatRoom = ChatRoomModel.fromFirestore(docs[index]);

              String displayMessage = "Bắt đầu trò chuyện với PT";
              String timeAgo = "";
              bool isBold = false;

              if (chatRoom.lastMessage.isNotEmpty) {
                String prefix = (chatRoom.lastSenderId == currentUser.uid) ? "Bạn: " : "";
                displayMessage = "$prefix${chatRoom.lastMessage}";
                timeAgo = _formatTimeAgo(chatRoom.updatedAt);
                isBold = (chatRoom.lastSenderId != currentUser.uid);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF2E3B55).withOpacity(0.1),
                    child: Text(
                      chatRoom.ptName.isNotEmpty ? chatRoom.ptName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xFF2E3B55), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chatRoom.ptName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2937)),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      displayMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isBold ? Colors.black87 : Colors.grey[600],
                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chatRoom.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}