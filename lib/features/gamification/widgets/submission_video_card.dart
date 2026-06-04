import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ptbooking/core/widgets/comment_bottom_sheet.dart';

class SubmissionItemData {
  final String docId;
  final String userId;
  final String userName;
  final String avatarUrl;
  final String videoUrl;
  final int score;
  final String status;
  final String timeString;
  final VideoPlayerController controller;
  final List<String> likedBy;
  final int commentCount;

  SubmissionItemData({
    required this.docId,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.score,
    required this.status,
    required this.timeString,
    required this.controller,
    required this.likedBy,
    required this.commentCount,
  });
}

class SubmissionVideoCard extends StatelessWidget {
  final SubmissionItemData item;
  final String? currentUserRole;
  final String? currentUserId;
  final bool isLikedByMe;
  final bool isChallengeEnded;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;
  final VoidCallback onGrade;

  const SubmissionVideoCard({
    super.key,
    required this.item,
    required this.currentUserRole,
    required this.currentUserId,
    required this.isLikedByMe,
    required this.isChallengeEnded,
    required this.onDelete,
    required this.onToggleLike,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              backgroundImage: item.avatarUrl.isNotEmpty ? NetworkImage(item.avatarUrl) : null,
              child: item.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
            ),
            title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.timeString),
            trailing: currentUserRole == 'PT'
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Xóa video này", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          AspectRatio(aspectRatio: item.controller.value.aspectRatio, child: VideoPlayer(item.controller)),

          // Nút Like, Comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: onToggleLike,
                  child: Row(
                    children: [
                      Icon(isLikedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      const SizedBox(width: 5),
                      Text("${item.likedBy.length}"),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                InkWell(
                  onTap: () {
                    if (isChallengeEnded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thử thách đã kết thúc, không thể bình luận!')),
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentBottomSheet(submissionId: item.docId, ownerId: item.userId),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 5),
                      Text("${item.commentCount}"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_border_purple500, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      "PT đánh giá: ",
                      style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                    Text(
                      item.status == 'Đã chấm' ? '${item.score} Điểm' : item.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.status == 'Đã chấm' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (currentUserRole == 'PT' && item.status != 'Đã chấm')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(80, 36),
                    ),
                    onPressed: onGrade,
                    child: const Text("CHẤM ĐIỂM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
