import 'package:flutter/material.dart';
import 'package:ptbooking/features/chat/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? myChatFrame;
  final String? partnerChatFrame;
  final bool showDateHeader;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.myChatFrame,
    this.partnerChatFrame,
    required this.showDateHeader,
    this.onLongPress,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // NẾU KHÁC NGÀY THÌ VẼ CÁI NHÃN NGÀY THÁNG Ở ĐÂY
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatDateHeader(message.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // BONG BÓNG TIN NHẮN
        GestureDetector(
          onLongPress: onLongPress,
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
                    backgroundColor: const Color(0xFF0B2447).withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 16, color: Color(0xFF0B2447)),
                  ),
                  const SizedBox(width: 8),
                ],

                Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: EdgeInsets.symmetric(
                        horizontal: (isMe ? myChatFrame : partnerChatFrame) != null ? 36 : 16,
                        vertical: (isMe ? myChatFrame : partnerChatFrame) != null ? 24 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: (isMe ? myChatFrame : partnerChatFrame) != null
                            ? Colors.transparent // Nếu có khung thì trong suốt nền
                            : (isMe ? const Color(0xFF4BA3E3) : Colors.white),
                        image: (isMe ? myChatFrame : partnerChatFrame) != null
                            ? DecorationImage(
                                image: AssetImage(
                                  (isMe ? myChatFrame : partnerChatFrame)!.replaceAll('.jpg', '.png'),
                                ),
                                fit: BoxFit.fill,
                              )
                            : null,
                        borderRadius: (isMe ? myChatFrame : partnerChatFrame) != null
                            ? null
                            : BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                              ),
                        boxShadow: [
                          if ((isMe ? myChatFrame : partnerChatFrame) == null)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : const Color(0xFF0B2447),
                          height: 1.35,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                      child: Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
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
  }
}
