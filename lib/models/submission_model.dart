import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String avatarUrl;
  final String videoUrl;
  final String status; // 'Đang chờ duyệt', 'Đã chấm'
  final int score;
  final Timestamp? createdAt;
  
  // Gamification properties
  final List<String> likedBy; // Danh sách UID đã thả tim
  final int commentCount;

  SubmissionModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.status,
    required this.score,
    this.createdAt,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      challengeId: data['challengeId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Học viên ẩn danh',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Đang chờ duyệt',
      score: data['score'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'videoUrl': videoUrl,
      'status': status,
      'score': score,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'likedBy': likedBy,
      'commentCount': commentCount,
    };
  }

  int get likesCount => likedBy.length;
}
