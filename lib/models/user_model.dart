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

  // Gamification (User & Battle Pass)
  final int level;
  final int exp;
  final int bpLevel;
  final int bpExp;
  final bool isVip;
  final Timestamp? lastLogin;
  final int loginStreak;

  // Tương tác
  final List<String> following;

  // Gamification Assets
  final List<String> unlockedFrames;
  final List<String> unlockedChatFrames;
  final List<Map<String, dynamic>> unlockedBadges;
  final List<Map<String, dynamic>> unlockedVouchers;
  final String? selectedFrame;
  final String? selectedChatFrame;

  // Thông tin dành riêng cho PT
  final String? specialty;
  final String? experience;
  final String? bio;
  final double rating;
  final int followerCount;
  final int challengeCount;
  final String? certificateUrl; // 🔥 BỔ SUNG TRƯỜNG CHỨNG CHỈ
  final String? cvUrl;          // 🔥 BỔ SUNG TRƯỜNG CV

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
    this.level = 1,
    this.exp = 0,
    this.bpLevel = 1,
    this.bpExp = 0,
    this.isVip = false,
    this.lastLogin,
    this.loginStreak = 0,
    this.following = const [],
    this.unlockedFrames = const [],
    this.unlockedChatFrames = const [],
    this.unlockedBadges = const [],
    this.unlockedVouchers = const [],
    this.selectedFrame,
    this.selectedChatFrame,
    this.specialty,
    this.experience,
    this.bio,
    this.rating = 0.0,
    this.followerCount = 0,
    this.challengeCount = 0,
    this.certificateUrl,
    this.cvUrl,
  });

  // Ép kiểu từ dữ liệu Firebase về Object UserModel an toàn
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // An toàn chuyển đổi unlockedBadges
    List<Map<String, dynamic>> parsedBadges = [];
    if (data['unlockedBadges'] != null) {
      if (data['unlockedBadges'] is List) {
        for (var item in data['unlockedBadges']) {
          if (item is Map) {
            parsedBadges.add(Map<String, dynamic>.from(item));
          } else if (item is String) {
            // Trường hợp dữ liệu cũ (chỉ có string đường dẫn) -> bọc lại thành map
            parsedBadges.add({"image": item, "challengeName": "Thử thách cũ"});
          }
        }
      }
    }

    List<Map<String, dynamic>> parsedVouchers = [];
    if (data['unlockedVouchers'] != null && data['unlockedVouchers'] is List) {
      for (var item in data['unlockedVouchers']) {
        if (item is Map) {
          parsedVouchers.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Ẩn danh',
      avatar: data['avatar']?.toString(),
      role: data['role']?.toString() ?? 'User',

      phone: data['phone']?.toString(),
      gender: data['gender']?.toString(),
      address: data['address']?.toString(),
      
      level: data['level'] as int? ?? 1,
      exp: data['exp'] as int? ?? 0,
      bpLevel: data['bpLevel'] as int? ?? 1,
      bpExp: data['bpExp'] as int? ?? 0,
      isVip: data['isVip'] as bool? ?? false,
      lastLogin: data['lastLogin'] as Timestamp?,
      loginStreak: data['loginStreak'] as int? ?? 0,
      following: List<String>.from(data['following'] ?? []),
      unlockedFrames: List<String>.from(data['unlockedFrames'] ?? []),
      unlockedChatFrames: List<String>.from(data['unlockedChatFrames'] ?? []),
      unlockedBadges: parsedBadges,
      unlockedVouchers: parsedVouchers,
      selectedFrame: data['selectedFrame']?.toString(),
      selectedChatFrame: data['selectedChatFrame']?.toString(),

      specialty: data['specialty']?.toString(),
      experience: data['experience']?.toString(),
      bio: data['bio']?.toString(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      followerCount: data['followerCount'] as int? ?? 0,
      challengeCount: data['challengeCount'] as int? ?? 0,
      specialty: data['specialty']?.toString(),
      experience: data['experience']?.toString(),
      bio: data['bio']?.toString(),
      certificateUrl: data['certificate_url']?.toString(), // 🔥 ĐỌC LINK CHỨNG CHỈ
      cvUrl: data['cv_url']?.toString(),                   // 🔥 ĐỌC LINK CV

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
      
      'level': level,
      'exp': exp,
      'bpLevel': bpLevel,
      'bpExp': bpExp,
      'isVip': isVip,
      'lastLogin': lastLogin,
      'loginStreak': loginStreak,
      'following': following,
      'unlockedFrames': unlockedFrames,
      'unlockedChatFrames': unlockedChatFrames,
      'unlockedBadges': unlockedBadges,
      'unlockedVouchers': unlockedVouchers,
      'selectedFrame': selectedFrame,
      'selectedChatFrame': selectedChatFrame,

      'specialty': specialty,
      'experience': experience,
      'bio': bio,
      'rating': rating,
      'followerCount': followerCount,
      'challengeCount': challengeCount,
      
      'certificate_url': certificateUrl,
      'cv_url': cvUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}