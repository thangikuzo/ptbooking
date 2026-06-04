import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentBottomSheet extends StatefulWidget {
  final String submissionId;
  final String ownerId;

  const CommentBottomSheet({super.key, required this.submissionId, required this.ownerId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} năm trước";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} tháng trước";
    if (diff.inDays > 0) return "${diff.inDays} ngày trước";
    if (diff.inHours > 0) return "${diff.inHours} giờ trước";
    if (diff.inMinutes > 0) return "${diff.inMinutes} phút trước";
    return "Vừa xong";
  }

  Future<void> _sendComment() async {
    String text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() { _isSending = true; });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (user.uid == widget.ownerId) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bạn không thể tự bình luận vào bài của mình!")));
        return;
      }

      String userName = "Học viên";
      String avatar = "";
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] ?? "Học viên";
        avatar = userDoc.data()?['avatar'] ?? "";
      }

      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(widget.submissionId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userName,
        'avatar': avatar,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật số đếm
      await FirebaseFirestore.instance.collection('submissions').doc(widget.submissionId).update({
        'commentCount': FieldValue.increment(1)
      });

      // Tạo thông báo cho chủ video
      if (user.uid != widget.ownerId) {
        await FirebaseFirestore.instance.collection('users').doc(widget.ownerId).collection('notifications').add({
          'type': 'comment',
          'senderId': user.uid,
          'senderName': userName,
          'senderAvatar': avatar,
          'targetId': widget.submissionId,
          'message': 'đã bình luận về video của bạn: "$text"',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      _commentController.clear();
      if (mounted) setState(() { _isSending = false; });
    } catch (e) {
      if (mounted) setState(() { _isSending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const Text("Bình luận", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submissions')
                  .doc(widget.submissionId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Chưa có bình luận nào."));

                return ListView.builder(
                  reverse: true, // Hiển thị tin mới ở dưới
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String timeStr = "";
                    if (data['createdAt'] != null) {
                      DateTime dt = (data['createdAt'] as Timestamp).toDate();
                      timeStr = _timeAgo(dt);
                    }
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: data['avatar'] != '' ? NetworkImage(data['avatar']) : null,
                        child: data['avatar'] == '' ? const Icon(Icons.person) : null,
                      ),
                      title: Row(
                        children: [
                          Text(data['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      subtitle: Text(data['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
          if (FirebaseAuth.instance.currentUser?.uid == widget.ownerId)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text("Bạn không thể tự bình luận vào bài nộp của chính mình.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8, left: 16, right: 16, top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), offset: const Offset(0, -2), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Nhập bình luận...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _sendComment,
                        )
                ],
              ),
            )
        ],
      ),
    );
  }
}
