import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String userId;
  final String userName;
  final String ptId;
  final String ptName;
  final String bookingId;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatRoomModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.ptId,
    required this.ptName,
    required this.bookingId,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      // 🔥 FIX LỖI: Đọc đúng tên cột 'customer_id' trên Firebase
      userId: data['customer_id']?.toString() ?? '',
      userName: data['customer_name']?.toString() ?? 'Ẩn danh',
      ptId: data['pt_id']?.toString() ?? '',
      ptName: data['pt_name']?.toString() ?? 'PT',
      bookingId: data['booking_id']?.toString() ?? '',
      lastMessage: data['last_message']?.toString() ?? '',
      lastSenderId: data['last_sender_id']?.toString() ?? '',
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      updatedAt: data['updated_at'] != null ? (data['updated_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': userId, // 🔥 FIX LỖI: Trả lại tên cột cũ
      'customer_name': userName,
      'pt_id': ptId,
      'pt_name': ptName,
      'booking_id': bookingId,
      'last_message': lastMessage,
      'last_sender_id': lastSenderId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}