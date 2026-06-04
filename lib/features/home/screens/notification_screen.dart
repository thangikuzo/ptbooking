import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} năm trước";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} tháng trước";
    if (diff.inDays > 0) return "${diff.inDays} ngày trước";
    if (diff.inHours > 0) return "${diff.inHours} giờ trước";
    if (diff.inMinutes > 0) return "${diff.inMinutes} phút trước";
    return "Vừa xong";
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAllAsRead(String uid) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thông báo")),
        body: const Center(child: Text("Vui lòng đăng nhập")),
      );
    }

    // Đánh dấu đã đọc khi mở màn hình
    _markAllAsRead(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thông báo",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D5D9B), Color(0xFF4BA3E3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có thông báo nào."));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String type = data['type'] ?? 'info';
              String senderName = data['senderName'] ?? 'Ai đó';
              String senderAvatar = data['senderAvatar'] ?? '';
              String message = data['message'] ?? '';
              bool isRead = data['isRead'] ?? true;

              DateTime? createdAt;
              if (data['createdAt'] != null) {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              }

              return Container(
                color: isRead ? Colors.white : Colors.green.shade50,
                child: ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundImage: senderAvatar.isNotEmpty ? NetworkImage(senderAvatar) : null,
                        child: senderAvatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: _getColorForType(type),
                          child: Icon(_getIconForType(type), size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: " $message"),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    createdAt != null ? _timeAgo(createdAt) : '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: !isRead ? const CircleAvatar(radius: 4, backgroundColor: Colors.green) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
