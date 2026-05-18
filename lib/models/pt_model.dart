import 'package:cloud_firestore/cloud_firestore.dart';

class PT {
  final String id;
  final String name;
  final String specialty;
  final String avatar;
  final int price;
  final double? rating;
  final int? experience;
  final Map<String, bool> schedule; // <-- thay dynamic bằng bool cho chính xác

  PT({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatar,
    required this.price,
    this.rating,
    this.experience,
    required this.schedule,
  });

  factory PT.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Log để debug nếu cần
    // print("Parsing PT id: ${doc.id}, data: $data");

    Map<String, bool> parsedSchedule = {};
    final scheduleData = data['schedule'];
    if (scheduleData is Map) {
      scheduleData.forEach((key, value) {
        if (key is String && value is bool) {
          parsedSchedule[key] = value;
        } else {
          print("Invalid schedule entry in ${doc.id}: key=$key, value=$value");
        }
      });
    } else if (scheduleData != null) {
      print("Schedule không phải Map ở document ${doc.id}: $scheduleData");
    }

    return PT(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      specialty: data['specialty'] as String? ?? '',
      avatar: data['avatar'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble(),
      experience: (data['experience'] as num?)?.toInt(),
      schedule: parsedSchedule,
    );
  }
}