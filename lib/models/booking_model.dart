import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String ptId;
  final String ptName;
  final String bookingDate; // yyyy-MM-dd
  final String day;
  final String timeSlot;
  final String status;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.ptId,
    required this.ptName,
    required this.bookingDate,
    required this.day,
    required this.timeSlot,
    required this.status,
    this.createdAt,
  });

  // Ép Map từ Firebase thành Object BookingModel
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Ẩn danh',
      ptId: data['pt_id'] ?? '',
      ptName: data['pt_name'] ?? 'PT',
      bookingDate: data['booking_date'] ?? '',
      day: data['day'] ?? '',
      timeSlot: data['time_slot'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }

  // Ép Object thành Map để đẩy lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'pt_id': ptId,
      'pt_name': ptName,
      'booking_date': bookingDate,
      'day': day,
      'time_slot': timeSlot,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}