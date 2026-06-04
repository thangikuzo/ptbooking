import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int points;
  
  final String creatorId; // UID của PT tạo thử thách
  final String difficulty; // "Bình thường", "Khó", "Rất khó"
  final Timestamp? startTime;
  final Timestamp? endTime;
  final double rating; // Đánh giá của người dùng
  final int ratingCount; // Số lượng lượt đánh giá
  final bool isRewardsDistributed;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.points,
    required this.creatorId,
    required this.difficulty,
    this.startTime,
    this.endTime,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isRewardsDistributed = false,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      points: data['points'] as int? ?? 0,
      creatorId: data['creatorId']?.toString() ?? '',
      difficulty: data['difficulty']?.toString() ?? 'Bình thường',
      startTime: data['startTime'] as Timestamp?,
      endTime: data['endTime'] as Timestamp?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      isRewardsDistributed: data['isRewardsDistributed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'points': points,
      'creatorId': creatorId,
      'difficulty': difficulty,
      'startTime': startTime,
      'endTime': endTime,
      'rating': rating,
      'ratingCount': ratingCount,
      'isRewardsDistributed': isRewardsDistributed,
    };
  }
}
