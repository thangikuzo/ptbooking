import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkDailyLogin(String userId) async {
    try {
      final docRef = _firestore.collection('gamification').doc(userId);
      final doc = await docRef.get();

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (doc.exists) {
        final lastLoginStr = doc.data()?['last_login_date'] as String?;
        if (lastLoginStr == todayStr) {
          // Already logged in today
          return false;
        }
      }

      // First login today -> Add 10 EXP
      await docRef.set({
        'last_login_date': todayStr,
        'exp': FieldValue.increment(10),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addExp(String userId, int exp) async {
    try {
      final docRef = _firestore.collection('gamification').doc(userId);
      await docRef.set({'exp': FieldValue.increment(exp)}, SetOptions(merge: true));
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addBpExp(String userId, int bpExp) async {
    try {
      final docRef = _firestore.collection('gamification').doc(userId);
      await docRef.set({'bp_exp': FieldValue.increment(bpExp)}, SetOptions(merge: true));
    } catch (e) {
      // Ignored
    }
  }
}
