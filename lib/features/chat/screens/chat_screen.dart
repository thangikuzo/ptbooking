import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ptbooking/features/chat/models/message_model.dart';
import 'package:ptbooking/features/chat/widgets/chat_bubble.dart';
import 'package:ptbooking/features/chat/widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _myChatFrame;
  String? _partnerChatFrame;

  @override
  void initState() {
    super.initState();
    _loadChatFrames();
  }

  Future<void> _loadChatFrames() async {
    if (_currentUser == null) return;
    try {
      var chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
      if (!chatDoc.exists) return;
      var data = chatDoc.data()!;
      String ptId = data['pt_id'] ?? '';
      String customerId = data['customer_id'] ?? '';

      String partnerId = (_currentUser!.uid == ptId) ? customerId : ptId;

      var myDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      var partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerId).get();

      if (mounted) {
        setState(() {
          _myChatFrame = myDoc.data()?['selectedChatFrame'];
          _partnerChatFrame = partnerDoc.data()?['selectedChatFrame'];
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải khung chat: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _currentUser == null) return;

    _messageController.clear();

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
      'sender_id': _currentUser!.uid,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'last_message': text,
      'last_sender_id': _currentUser!.uid,
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
        'last_sender_id': data['sender_id'] ?? '',
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
        content: const Text("Bạn có chắc muốn xóa tin nhắn này không?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMessage(messageId);
    }
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "Trò chuyện",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4BA3E3)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có tin nhắn. Nhắn tin hỏi thăm ngay!",
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Tin nhắn xếp từ dưới lên trên
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final currentMessage = MessageModel.fromFirestore(docs[index]);
                    final bool isMe = currentMessage.senderId == _currentUser!.uid;

                    bool showDateHeader = false;
                    if (index == docs.length - 1) {
                      showDateHeader = true;
                    } else {
                      final previousMessage = MessageModel.fromFirestore(docs[index + 1]);
                      if (!_isSameDay(currentMessage.createdAt, previousMessage.createdAt)) {
                        showDateHeader = true;
                      }
                    }

                    return ChatBubble(
                      message: currentMessage,
                      isMe: isMe,
                      myChatFrame: _myChatFrame,
                      partnerChatFrame: _partnerChatFrame,
                      showDateHeader: showDateHeader,
                      onLongPress: isMe ? () => _confirmDeleteMessage(currentMessage.id) : null,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
