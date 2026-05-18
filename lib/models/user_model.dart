import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? avatar;
  final String role; // 'User', 'PT', 'Pending_PT', 'Admin'

  // Thông tin cá nhân cơ bản
  final String? phone;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? address;

  // Thông tin dành riêng cho PT
  final String? specialty;
  final String? experience;
  final String? bio;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.avatar,
    required this.role,
    this.phone,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.address,
    this.specialty,
    this.experience,
    this.bio,

  });

  // Ép kiểu từ dữ liệu Firebase về Object UserModel an toàn
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Ẩn danh',
      avatar: data['avatar']?.toString(),
      role: data['role']?.toString() ?? 'User',

      // Thêm ?.toString() vào để chống lỗi hiện chữ "null"
      phone: data['phone']?.toString(),
      gender: data['gender']?.toString(),
      address: data['address']?.toString(), // Đã bổ sung address bị thiếu
      specialty: data['specialty']?.toString(),
      experience: data['experience']?.toString(),
      bio: data['bio']?.toString(),

      // Xử lý bọc thép cho các trường Số (int, double)
      age: data['age'] is int ? data['age'] : int.tryParse(data['age']?.toString() ?? ''),
      height: data['height'] is num ? data['height'].toDouble() : double.tryParse(data['height']?.toString() ?? ''),
      weight: data['weight'] is num ? data['weight'].toDouble() : double.tryParse(data['weight']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,

      'avatar': avatar,
      'role': role,
      'phone': phone,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'address': address,
      'specialty': specialty,
      'experience': experience,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}