import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Đổi sang dùng Firebase Auth
import 'dart:async';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {'sender': 'ai', 'text': 'Chào bạn! Mình là Trợ lý AI hệ thống phòng Gym. Bạn cần tư vấn về giáo án tập luyện hay thông tin PT nào không?'}
  ];

  bool _isLoading = false;
  String? _sessionId; // Lưu sessionId

  @override
  void initState() {
    super.initState();
    _setupFirebaseSessionId();
  }

  // 🔥 LẤY UID CỦA TÀI KHOẢN FIREBASE LÀM SESSION ID
  void _setupFirebaseSessionId() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      if (currentUser != null) {
        // Dùng UID vĩnh viễn của user làm chìa khóa trí nhớ cho AI
        _sessionId = currentUser.uid;
      } else {
        // Fallback: Lỡ có khách vãng lai lọt vào
        _sessionId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sessionId == null) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final url = Uri.parse('http://10.0.2.2:5678/webhook/chat-api');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'sessionId': _sessionId,  // Truyền cái UID của Firebase lên n8n
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply = data['output'] ?? data['response'] ?? "Xin lỗi, mình không hiểu rõ.";

        setState(() {
          _messages.add({'sender': 'ai', 'text': aiReply});
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Lỗi ${response.statusCode}: ${response.body}'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Lỗi kết nối: $e'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text("Trợ lý AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF2E3B55), shape: BoxShape.circle),
                          child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFCA311) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : const Color(0xFF1E2937),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text("AI đang suy nghĩ...", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Nhập câu hỏi cho AI...",
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