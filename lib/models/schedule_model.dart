import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String ptId;
  final Map<String, List<String>> availability;
  final bool isActive;

  ScheduleModel({
    required this.ptId,
    required this.availability,
    required this.isActive
  });

  // Kéo từ Firebase về
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Xử lý ép kiểu cẩn thận cho cái Map chứa List thời gian
    // Tránh lỗi "type 'List<dynamic>' is not a subtype of type 'List<String>'"
    Map<String, List<String>> parsedAvailability = {};
    if (data['availability'] != null) {
      Map<String, dynamic> rawAvail = data['availability'];
      rawAvail.forEach((key, value) {
        parsedAvailability[key] = List<String>.from(value);
      });
    }

    return ScheduleModel(
      ptId: data['pt_id'] ?? doc.id,
      availability: parsedAvailability,
      isActive: data['is_active'] ?? true,
    );
  }

  // Đẩy lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'pt_id': ptId,
      'availability': availability,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}