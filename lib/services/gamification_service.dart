import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/gamification_constants.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tính điểm thưởng từ Thử thách
  int calculateChallengeRewards(String difficulty, int rank) {
    int baseExp = 0;
    if (rank == 1) baseExp = 50;
    else if (rank == 2) baseExp = 30;
    else if (rank == 3) baseExp = 10;
    else return 0; // Không nằm trong Top 3 thì không được EXP từ rank

    int difficultyBonus = 0;
    if (difficulty == 'Khó') difficultyBonus = 5;
    else if (difficulty == 'Rất khó') difficultyBonus = 10;

    return baseExp + difficultyBonus;
  }

  // Cộng EXP và xử lý Level Up
  Future<void> addExp(String userId, int expAmount) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        
        // CHỈ ÁP DỤNG CHO USER
        if (data['role'] == 'PT' || data['role'] == 'Admin') return;

        int currentLevel = data['level'] as int? ?? 1;
        int currentExp = data['exp'] as int? ?? 0;

        int newExp = currentExp + expAmount;
        int expNeeded = currentLevel * 500; // Công thức: Cấp x 500
        
        int newLevel = currentLevel;
        List<String> newFrames = [];
        List<String> newChatFrames = [];
        List<Map<String, dynamic>> newBadges = [];
        List<Map<String, dynamic>> newVouchers = [];

        while (newExp >= expNeeded) {
          newExp -= expNeeded;
          newLevel++;
          expNeeded = newLevel * 500;

          // Phát quà
          for (var reward in GamificationConstants.LEVEL_REWARDS) {
            if (reward['level'] == newLevel) {
              if (reward['type'] == 'frame_avatar') newFrames.add(reward['image']);
              if (reward['type'] == 'frame_chat') newChatFrames.add(reward['image']);
              if (reward['type'] == 'badge') {
                newBadges.add({"image": reward['image'], "challengeName": "Thưởng Cấp $newLevel"});
              }
              if (reward['type'] == 'voucher') {
                newVouchers.add({
                  'title': reward['title'],
                  'discount': reward['discount'],
                  'image': reward['image'],
                  'code': 'VCH_${DateTime.now().millisecondsSinceEpoch}_${reward['discount']}',
                  'receivedAt': Timestamp.now(),
                  'expiresAt': (reward['discount'] as int) >= 30 ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))) : null,
                });
              }
            }
          }
        }

        Map<String, dynamic> updateData = {
          'level': newLevel,
          'exp': newExp,
        };

        if (newFrames.isNotEmpty) updateData['unlockedFrames'] = FieldValue.arrayUnion(newFrames);
        if (newChatFrames.isNotEmpty) updateData['unlockedChatFrames'] = FieldValue.arrayUnion(newChatFrames);
        if (newBadges.isNotEmpty) updateData['unlockedBadges'] = FieldValue.arrayUnion(newBadges);
        if (newVouchers.isNotEmpty) updateData['unlockedVouchers'] = FieldValue.arrayUnion(newVouchers);

        transaction.update(userRef, updateData);
      });
    } catch (e) {
      debugPrint("Lỗi khi cộng EXP: $e");
    }
  }

  // Cộng BP EXP và xử lý Level Up BP
  Future<void> addBpExp(String userId, int bpExpAmount) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // CHỈ ÁP DỤNG CHO USER
        if (data['role'] == 'PT' || data['role'] == 'Admin') return;

        int currentBpLevel = data['bpLevel'] as int? ?? 1;
        int currentBpExp = data['bpExp'] as int? ?? 0;

        int newBpExp = currentBpExp + bpExpAmount;
        int bpExpNeeded = 50; // Mỗi cấp BP cần 50 điểm
        
        int newBpLevel = currentBpLevel;
        bool isVip = data['isVip'] ?? false;
        List<String> newFrames = [];
        List<String> newChatFrames = [];
        List<Map<String, dynamic>> newBadges = [];
        List<Map<String, dynamic>> newVouchers = [];

        while (newBpExp >= bpExpNeeded && newBpLevel < 50) {
          newBpExp -= bpExpNeeded;
          newBpLevel++;

          // Phát quà BP Free
          for (var reward in GamificationConstants.BATTLEPASS_REWARDS_FREE) {
            if (reward['level'] == newBpLevel) {
              if (reward['type'] == 'frame_avatar') newFrames.add(reward['image']);
              if (reward['type'] == 'frame_chat') newChatFrames.add(reward['image']);
              if (reward['type'] == 'badge') newBadges.add({"image": reward['image'], "challengeName": "Battle Pass Cấp $newBpLevel"});
              if (reward['type'] == 'voucher') {
                newVouchers.add({
                  'title': reward['title'],
                  'discount': reward['discount'],
                  'image': reward['image'],
                  'code': 'VCH_${DateTime.now().millisecondsSinceEpoch}_${reward['discount']}',
                  'receivedAt': Timestamp.now(),
                  'expiresAt': (reward['discount'] as int) >= 30 ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))) : null,
                });
              }
            }
          }

          // Phát quà BP VIP
          if (isVip) {
            for (var reward in GamificationConstants.BATTLEPASS_REWARDS_VIP) {
              if (reward['level'] == newBpLevel) {
                if (reward['type'] == 'frame_avatar') newFrames.add(reward['image']);
                if (reward['type'] == 'frame_chat') newChatFrames.add(reward['image']);
                if (reward['type'] == 'badge') newBadges.add({"image": reward['image'], "challengeName": "VIP BP Cấp $newBpLevel"});
                if (reward['type'] == 'voucher') {
                  newVouchers.add({
                    'title': reward['title'],
                    'discount': reward['discount'],
                    'image': reward['image'],
                    'code': 'VCH_${DateTime.now().millisecondsSinceEpoch}_${reward['discount']}',
                    'receivedAt': Timestamp.now(),
                    'expiresAt': (reward['discount'] as int) >= 30 ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))) : null,
                  });
                }
              }
            }
          }
        }

        if (newBpLevel >= 50) {
          newBpLevel = 50;
          if (newBpExp > 0) newBpExp = 0; // max cap
        }

        Map<String, dynamic> updateData = {
          'bpLevel': newBpLevel,
          'bpExp': newBpExp,
        };

        if (newFrames.isNotEmpty) updateData['unlockedFrames'] = FieldValue.arrayUnion(newFrames);
        if (newChatFrames.isNotEmpty) updateData['unlockedChatFrames'] = FieldValue.arrayUnion(newChatFrames);
        if (newBadges.isNotEmpty) updateData['unlockedBadges'] = FieldValue.arrayUnion(newBadges);
        if (newVouchers.isNotEmpty) updateData['unlockedVouchers'] = FieldValue.arrayUnion(newVouchers);

        transaction.update(userRef, updateData);
      });
    } catch (e) {
      debugPrint("Lỗi khi cộng BP EXP: $e");
    }
  }

  // Xử lý đăng nhập hằng ngày
  Future<bool> checkDailyLogin(String userId) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot snapshot = await userRef.get();
      
      if (!snapshot.exists) return false;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      
      // CHỈ ÁP DỤNG CHO USER
      if (data['role'] == 'PT' || data['role'] == 'Admin') return false;

      Timestamp? lastLoginTs = data['lastLogin'] as Timestamp?;
      int currentStreak = data['loginStreak'] as int? ?? 0;

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      if (lastLoginTs != null) {
        DateTime lastLogin = lastLoginTs.toDate();
        DateTime lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

        if (lastLoginDate.isAtSameMomentAs(today)) {
          return false;
        }

        DateTime yesterday = today.subtract(const Duration(days: 1));
        if (lastLoginDate.isAtSameMomentAs(yesterday)) {
          currentStreak++; 
        } else {
          currentStreak = 1; 
        }
      } else {
        currentStreak = 1; 
      }

      if (currentStreak > 7) {
        currentStreak = 1;
      }

      int expReward = 10;
      int bpExpReward = 5;
      if (currentStreak == 7) {
        expReward = 50; 
        bpExpReward = 25;
      }

      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'loginStreak': currentStreak,
      });

      await addExp(userId, expReward);
      await addBpExp(userId, bpExpReward);

      return true;

    } catch (e) {
      debugPrint("Lỗi check Daily Login: $e");
      return false;
    }
  }
}
