import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Model để làm việc chuẩn Clean Architecture
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 🔥 UPDATE LOGIC: Gửi tin nhắn và cập nhật người gửi cuối cùng
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _currentUser == null) return;

    _messageController.clear();

    // 1. Đẩy tin nhắn mới vào sub-collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'sender_id': _currentUser!.uid,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật phòng chat bên ngoài kèm trường last_sender_id để kích hoạt preview xịn
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'last_message': text,
      'last_sender_id': _currentUser!.uid, // <-- THÊM DÒNG NÀY ĐỂ MÀN HÌNH NGOÀI BIẾT AI GỬI
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    final latestMessage = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    if (latestMessage.docs.isNotEmpty) {
      final data = latestMessage.docs.first.data();

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'last_message': data['text'] ?? '',
        'last_sender_id': data['sender_id'] ?? '', // Cập nhật lại id người gửi trước đó
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'last_message': '',
        'last_sender_id': '',
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _confirmDeleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa tin nhắn", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc muốn xóa tin nhắn này không? Chữa ngượng tí thôi mà!"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMessage(messageId);
    }
  }

  // Định dạng hiển thị giờ (HH:mm)
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "Vừa xong";
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Vui lòng đăng nhập")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Nền xám khói Premium làm nổi bật khung chat
      appBar: AppBar(
        title: const Text("Trò chuyện", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF2E3B55),
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('created_at', descending: true)
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
                        Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text("Chưa có tin nhắn. Nhắn tin hỏi thăm ngay!", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // ÉP KIỂU SANG MESSAGE MODEL AN TOÀN TUYỆT ĐỐI
                    final message = MessageModel.fromFirestore(docs[index]);
                    final bool isMe = message.senderId == _currentUser!.uid;

                    return GestureDetector(
                      onLongPress: isMe ? () => _confirmDeleteMessage(message.id) : null,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFFFCA311) : Colors.white,
                                // ĐUÔI NHỌN THẨM MỸ CAO CHO KHUNG CHAT
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isMe ? Colors.white : const Color(0xFF1E2937),
                                  height: 1.35,
                                ),
                              ),
                            ),
                            // HIỂN THỊ TIMESTAMP
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                              child: Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
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
          ),

          // THANH NHẬP LIỆU MODERNIZE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey, size: 26),
                    onPressed: () {}, // Đồ chơi giả lập nút đính kèm ảnh
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E3B55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}