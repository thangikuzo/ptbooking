import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final int sessionNumber; // 1, 2, ..., N
  String date;            // yyyy-MM-dd
  String timeSlot;        // hh:mm - hh:mm
  String day;             // monday, tuesday,...
  String status;          // 'unscheduled', 'scheduled', 'completed', 'canceled'
  DateTime? completedAt;

  SessionModel({
    required this.sessionNumber,
    this.date = '',
    this.timeSlot = '',
    this.day = '',
    this.status = 'unscheduled',
    this.completedAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionNumber: map['session_number'] as int? ?? 1,
      date: map['date']?.toString() ?? '',
      timeSlot: map['time_slot']?.toString() ?? '',
      day: map['day']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unscheduled',
      completedAt: map['completed_at'] != null
          ? (map['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_number': sessionNumber,
      'date': date,
      'time_slot': timeSlot,
      'day': day,
      'status': status,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
