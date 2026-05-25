import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/challenge_model.dart';
import 'challenge_detail_screen.dart';
import 'pt_create_challenge_screen.dart';
import 'notification_screen.dart';
import 'pt_ranking_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = (doc.data() as Map<String, dynamic>)['role']?.toString();
        });

        // Trigger check for ended challenges to notify PT
        if (_userRole == 'PT') {
          _checkAndNotifyEndedChallenges(user.uid);
          _cleanupOldChallenges(user.uid);
        }
      }
    }
  }

  Future<void> _cleanupOldChallenges(String uid) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .where('creatorId', isEqualTo: uid)
          .where('isRewardsDistributed', isEqualTo: true)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        // Xóa tất cả submissions của challenge này
        var subSnap = await FirebaseFirestore.instance
            .collection('submissions')
            .where('challengeId', isEqualTo: doc.id)
            .get();
        for (var subDoc in subSnap.docs) {
          batch.delete(subDoc.reference);
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up challenges: $e');
    }
  }

  Future<void> _checkAndNotifyEndedChallenges(String uid) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('challenges').where('creatorId', isEqualTo: uid).get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        bool isRewardsDistributed = data['isRewardsDistributed'] ?? false;
        bool isNotified = data['isEndNotified'] ?? false;
        if (!isRewardsDistributed && !isNotified) {
          Timestamp? endTime = data['endTime'];
          if (endTime != null && endTime.toDate().isBefore(DateTime.now())) {
            // Đã kết thúc nhưng chưa phát thưởng -> Nhắc nhở
            await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
              'type': 'system',
              'message': 'Thử thách "${data['title']}" đã kết thúc! Hãy chấm điểm và trao thưởng cho Top 3 nhé.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            // Đánh dấu đã nhắc nhở
            await doc.reference.update({'isEndNotified': true});
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking ended challenges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đấu Trường Thử Thách",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white),
            tooltip: 'Bảng xếp hạng PT',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PTRankingScreen()));
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có thử thách nào đang diễn ra."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Challenge challenge = Challenge.fromFirestore(docs[index]);

              // Tính toán thời gian còn lại
              String timeRemaining = "Không giới hạn";
              bool isExpired = false;
              if (challenge.endTime != null) {
                DateTime end = challenge.endTime!.toDate();
                Duration diff = end.difference(DateTime.now());
                if (diff.isNegative) {
                  timeRemaining = "Đã kết thúc";
                  isExpired = true;
                } else {
                  timeRemaining = "Còn ${diff.inHours}h ${diff.inMinutes % 60}m";
                }
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChallengeDetailScreen(challenge: challenge)),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // 1. Ảnh
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            challenge.imageUrl.isNotEmpty
                                ? challenge.imageUrl
                                : 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 70, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 2. Chữ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 14,
                                    color: challenge.difficulty == 'Rất khó'
                                        ? Colors.red
                                        : (challenge.difficulty == 'Khó' ? Colors.orange : Colors.green),
                                  ),
                                  Text(challenge.difficulty, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 14, color: isExpired ? Colors.red : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeRemaining,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isExpired ? Colors.red : Colors.grey,
                                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 3. Điểm
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '+${challenge.points} EXP',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (challenge.rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    Text(
                                      challenge.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _userRole == 'PT'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PTCreateChallengeScreen()));
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "TẠO THỬ THÁCH",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
