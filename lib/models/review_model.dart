// File: lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String ptId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating; // Số sao (1 đến 5)
  final String content; // Nội dung đánh giá
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.ptId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.content,
    this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      ptId: data['pt_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name']?.toString() ?? 'Học viên',
      userAvatar: data['user_avatar']?.toString() ?? '',
      // Xử lý an toàn cho kiểu số
      rating: data['rating'] is num ? (data['rating'] as num).toDouble() : 5.0,
      content: data['content']?.toString() ?? '',
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pt_id': ptId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}