import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/chat/models/chat_room_model.dart';
import 'package:ptbooking/features/gamification/widgets/user_avatar_with_frame.dart';
import 'chat_screen.dart';
import 'ai_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return "${dateTime.day}/${dateTime.month}";
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Tin nhắn",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // =========================================================
          // 🔥 PHẦN 1: THẺ TRỢ LÝ AI (PREMIUM HIGH-TECH LOOK)
          // =========================================================
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatScreen()));
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Sleek dark/neon gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.cyanAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Trợ lý AI PT Gym",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Hỏi đáp giáo án, dinh dưỡng khoa học...",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.cyanAccent, size: 14),
                  ],
                ),
              ),
            ),
          ),

          // Dòng chữ nhỏ ngăn cách
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  "TIN NHẮN VỚI PT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              ],
            ),
          ),

          // =========================================================
          // 🔥 PHẦN 2: DANH SÁCH CHAT VỚI PT
          // =========================================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('customer_id', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Bạn chưa có cuộc trò chuyện nào.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final chatRoom = ChatRoomModel.fromFirestore(docs[index]);

                    String displayMessage = "Bắt đầu trò chuyện với PT";
                    String timeAgo = "";
                    bool isUnread = false;

                    if (chatRoom.lastMessage.isNotEmpty) {
                      String prefix = (chatRoom.lastSenderId == currentUser.uid) ? "Bạn: " : "";
                      displayMessage = "$prefix${chatRoom.lastMessage}";
                      timeAgo = _formatTimeAgo(chatRoom.updatedAt);
                      isUnread = (chatRoom.lastSenderId != currentUser.uid);
                    }

                    return FadeInUp(
                      duration: Duration(milliseconds: 200 + (index * 100)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: isUnread ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade100,
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatRoom.id)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // PT Dynamic Avatar Frame Loader
                                  _PTAvatarLoader(ptId: chatRoom.ptId),
                                  
                                  const SizedBox(width: 16),

                                  // Message Preview details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chatRoom.ptName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          displayMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isUnread ? Colors.black87 : Colors.grey.shade500,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Time and Unread Indicators
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (timeAgo.isNotEmpty)
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUnread ? AppColors.primary : Colors.grey.shade400,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: Colors.greenAccent, blurRadius: 4),
                                            ],
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 8), // Keep spacing consistent
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful Sub-widget to load PT's actual avatar and selected frame from Firestore
class _PTAvatarLoader extends StatefulWidget {
  final String ptId;
  final double size;

  const _PTAvatarLoader({required this.ptId, this.size = 48});

  @override
  State<_PTAvatarLoader> createState() => _PTAvatarLoaderState();
}

class _PTAvatarLoaderState extends State<_PTAvatarLoader> {
  String? _avatarUrl;
  String? _selectedFrame;

  @override
  void initState() {
    super.initState();
    _fetchPTDetails();
  }

  Future<void> _fetchPTDetails() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(widget.ptId).get();
      if (doc.exists && mounted) {
        setState(() {
          _avatarUrl = doc.data()?['avatar']?.toString();
          _selectedFrame = doc.data()?['selectedFrame']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải avatar PT: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatarWithFrame(
      avatarUrl: _avatarUrl,
      selectedFrame: _selectedFrame,
      size: widget.size,
    );
  }
}
