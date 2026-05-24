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
  final String packageName;
  final int sessionCount;
  final int paymentAmount;
  final String status;
  final String paymentStatus;
  final String? slotLockId;
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
    this.packageName = '',
    this.sessionCount = 1,
    this.paymentAmount = 0,
    required this.status,
    this.paymentStatus = 'unpaid',
    this.slotLockId,
    this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name']?.toString() ?? 'Ẩn danh',
      ptId: data['pt_id']?.toString() ?? '',
      ptName: data['pt_name']?.toString() ?? 'PT',
      bookingDate: data['booking_date']?.toString() ?? '',
      day: data['day']?.toString() ?? '',
      timeSlot: data['time_slot']?.toString() ?? '',
      packageName: data['package_name']?.toString() ?? '',
      sessionCount: data['session_count'] is int
          ? data['session_count']
          : int.tryParse(data['session_count']?.toString() ?? '') ?? 1,
      paymentAmount: data['payment_amount'] is int
          ? data['payment_amount']
          : int.tryParse(data['payment_amount']?.toString() ?? '') ?? 0,
      status: data['status']?.toString() ?? 'pending',
      paymentStatus: data['payment_status']?.toString() ?? 'unpaid',
      slotLockId: data['slot_lock_id']?.toString(),
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap({String? slotLockIdOverride}) {
    return {
      'user_id': userId,
      'user_name': userName,
      'pt_id': ptId,
      'pt_name': ptName,
      'booking_date': bookingDate,
      'day': day,
      'time_slot': timeSlot,
      'package_name': packageName,
      'session_count': sessionCount,
      'payment_amount': paymentAmount,
      'status': status,
      'payment_status': paymentStatus,
      'slot_lock_id': slotLockIdOverride ?? slotLockId,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
