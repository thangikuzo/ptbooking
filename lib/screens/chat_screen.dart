import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
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

  // =================================================================
  // Vẫn giữ code hàm Xóa tin nhắn (giấu bài lấy điểm source code)
  // =================================================================
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

  // 🔥 ĐỊNH DẠNG GIỜ (10:04)
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "Vừa xong";
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // 🔥 ĐỊNH DẠNG NGÀY CHO CÁI VÁCH NGĂN (Hôm nay, Hôm qua, 20/05/2026)
  String _formatDateHeader(DateTime? dateTime) {
    if (dateTime == null) return "Hôm nay";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return "Hôm nay";
    } else if (messageDate == yesterday) {
      return "Hôm qua";
    } else {
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    }
  }

  // 🔥 HÀM KIỂM TRA XEM 2 TIN NHẮN CÓ CÙNG NGÀY KHÔNG
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
        title: const Text("Trò chuyện", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
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
                  reverse: true, // Tin nhắn xếp từ dưới lên trên
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final currentMessage = MessageModel.fromFirestore(docs[index]);
                    final bool isMe = currentMessage.senderId == _currentUser!.uid;

                    // =======================================================
                    // 🔥 LOGIC HIỂN THỊ VÁCH NGĂN NGÀY THÁNG
                    // =======================================================
                    bool showDateHeader = false;
                    // Nếu là tin nhắn cũ nhất (nằm ở trên cùng cùng của danh sách)
                    if (index == docs.length - 1) {
                      showDateHeader = true;
                    } else {
                      // So sánh ngày của tin nhắn hiện tại với tin nhắn nằm NAY BÊN TRÊN NÓ (index + 1)
                      final previousMessage = MessageModel.fromFirestore(docs[index + 1]);
                      if (!_isSameDay(currentMessage.createdAt, previousMessage.createdAt)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        // NẾU KHÁC NGÀY THÌ VẼ CÁI NHÃN NGÀY THÁNG Ở ĐÂY
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _formatDateHeader(currentMessage.createdAt),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),

                        // BONG BÓNG TIN NHẮN
                        GestureDetector(
                          onLongPress: isMe ? () => _confirmDeleteMessage(currentMessage.id) : null,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // NẾU LÀ NGƯỜI KIA NHẮN, CHO THÊM CÁI AVATAR ẨN DANH NHỎ NHỎ CHO XỊN
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF2E3B55).withOpacity(0.1),
                                    child: const Icon(Icons.person, size: 16, color: Color(0xFF2E3B55)),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: (isMe ? _myChatFrame : _partnerChatFrame) != null ? 36 : 16,
                                          vertical: (isMe ? _myChatFrame : _partnerChatFrame) != null ? 24 : 12
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isMe ? _myChatFrame : _partnerChatFrame) != null
                                            ? Colors.transparent // Nếu có khung thì trong suốt nền
                                            : (isMe ? const Color(0xFFFCA311) : Colors.white),
                                        image: (isMe ? _myChatFrame : _partnerChatFrame) != null
                                            ? DecorationImage(
                                          image: AssetImage((isMe ? _myChatFrame : _partnerChatFrame)!.replaceAll('.jpg', '.png')),
                                          fit: BoxFit.fill,
                                        )
                                            : null,
                                        borderRadius: (isMe ? _myChatFrame : _partnerChatFrame) != null
                                            ? null
                                            : BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                                        ),
                                        boxShadow: [
                                          if ((isMe ? _myChatFrame : _partnerChatFrame) == null)
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Text(
                                        currentMessage.text,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isMe ? Colors.white : const Color(0xFF1E2937),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                                      child: Text(
                                        _formatTime(currentMessage.createdAt),
                                        style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // THANH NHẬP LIỆU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey, size: 26),
                    onPressed: () {},
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
                      decoration: const BoxDecoration(color: Color(0xFF2E3B55), shape: BoxShape.circle),
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