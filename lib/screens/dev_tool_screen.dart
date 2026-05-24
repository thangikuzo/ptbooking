import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';

class DevToolScreen extends StatefulWidget {
  const DevToolScreen({super.key});

  @override
  State<DevToolScreen> createState() => _DevToolScreenState();
}

class _DevToolScreenState extends State<DevToolScreen> {
  final GamificationService _gamificationService = GamificationService();
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<void> _addExp(int amount) async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await _gamificationService.addExp(uid, amount);
    setState(() => _isLoading = false);
    _showSnackBar('Đã cộng $amount EXP');
  }

  Future<void> _addBpExp(int amount) async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await _gamificationService.addBpExp(uid, amount);
    setState(() => _isLoading = false);
    _showSnackBar('Đã cộng $amount BP EXP');
  }

  Future<void> _simulateDailyLogin() async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    // Bỏ qua check ngày, ép cộng streak
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    var doc = await userRef.get();
    if (doc.exists) {
      int currentStreak = (doc.data() as Map<String, dynamic>)['loginStreak'] as int? ?? 0;
      currentStreak++;
      if (currentStreak > 7) currentStreak = 1;
      
      int expReward = currentStreak == 7 ? 50 : 10;
      int bpExpReward = currentStreak == 7 ? 25 : 5;

      await userRef.update({
        'loginStreak': currentStreak,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await _gamificationService.addExp(uid, expReward);
      await _gamificationService.addBpExp(uid, bpExpReward);

      _showSnackBar('Mô phỏng Đăng nhập: Streak $currentStreak (+$expReward EXP, +$bpExpReward BP EXP)');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _simulateChallengeReward() async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    // Thêm EXP và BP EXP
    await _gamificationService.addExp(uid, 500);
    await _gamificationService.addBpExp(uid, 100);

    // Tạo huy hiệu rác hạng nhất
    var badgeData = {
      'id': 'badge_rank1_test',
      'name': 'Huy hiệu Hạng 1 (Test)',
      'image': 'assets/badges/1st-place.png',
      'challengeName': 'Thử Thách Test (${DateTime.now().day}/${DateTime.now().month})',
      'receivedAt': Timestamp.now(),
    };

    await userRef.update({
      'unlockedBadges': FieldValue.arrayUnion([badgeData])
    });

    setState(() => _isLoading = false);
    _showSnackBar('Đã giả lập nhận thưởng Hạng 1 Thử Thách Test!');
  }

  Future<void> _clearBadges() async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    await userRef.update({
      'unlockedBadges': []
    });

    setState(() => _isLoading = false);
    _showSnackBar('Đã xóa TOÀN BỘ huy hiệu rác trong túi đồ!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools', style: TextStyle(color: Colors.white)), backgroundColor: Colors.black87),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Công cụ hỗ trợ Test Flow Gamification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text('Bơm 1.000 EXP (Lên 2 cấp)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () => _addExp(1000),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text('Bơm 10.000 EXP (Lên 20 cấp)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                onPressed: () => _addExp(10000),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Bơm 1.000 BP EXP (Max BP)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () => _addBpExp(1000),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Mô phỏng Đăng nhập hằng ngày (+1 Streak)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _simulateDailyLogin,
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Giả lập Trao Thưởng Thử Thách Hạng 1'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                onPressed: _simulateChallengeReward,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('XÓA SẠCH Huy Hiệu Rác Cũ'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: _clearBadges,
              ),
              const SizedBox(height: 30),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test Thông báo Đẩy (Streak)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await Future.delayed(const Duration(seconds: 3));
                  await NotificationService().showTestNotification(
                    'Giữ chuỗi 🔥 nhé!',
                    'Chỉ còn 8 tiếng nữa là hết ngày, hãy vào app ngay để không làm đứt chuỗi đăng nhập của bạn!'
                  );
                  setState(() => _isLoading = false);
                  _showSnackBar('Đã gửi thông báo đẩy (Test)');
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.mark_chat_unread),
                label: const Text('Test Thông báo Firebase (Thử thách)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
                    'type': 'comment',
                    'senderId': 'test_user',
                    'senderName': 'Người lạ',
                    'senderAvatar': '',
                    'targetId': 'test',
                    'message': 'đã bình luận về bài nộp của bạn: "Bài tập rất tốt!"',
                    'createdAt': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });
                  setState(() => _isLoading = false);
                  _showSnackBar('Đã đẩy 1 thông báo tương tác vào Database!');
                },
              ),
            ],
          ),
    );
  }
}
