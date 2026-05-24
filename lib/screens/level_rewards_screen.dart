import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/gamification_constants.dart';

class LevelRewardsScreen extends StatelessWidget {
  const LevelRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Phần thưởng Cấp độ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
          
          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          int currentLevel = userData?['level'] ?? 1;
          final List<Map<String, dynamic>> rewards = GamificationConstants.LEVEL_REWARDS;

          return Container(
            color: const Color(0xFFF1F8F5), // Nền xanh ngọc nhạt
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                var reward = rewards[index];
                bool isUnlocked = currentLevel >= (reward['level'] as int);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột Timeline
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.green : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: isUnlocked ? [const BoxShadow(color: Colors.green, blurRadius: 8, spreadRadius: 1)] : [],
                          ),
                          child: Center(
                            child: Text(
                              "Lv ${reward['level']}",
                              style: TextStyle(color: isUnlocked ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        if (index != rewards.length - 1)
                          Container(
                            width: 4,
                            height: 60,
                            color: isUnlocked ? Colors.green.withOpacity(0.5) : Colors.grey.shade300,
                          )
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Cột Quà
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUnlocked ? Colors.green.shade200 : Colors.grey.shade200, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: isUnlocked ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isUnlocked ? Colors.green.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isUnlocked
                                  ? Image.asset(reward['image'], errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.green, size: 30))
                                  : ColorFiltered(
                                      colorFilter: const ColorFilter.matrix(<double>[
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0,      0,      0,      1, 0,
                                      ]), // Grayscale filter
                                      child: Image.asset(reward['image'], errorBuilder: (context, error, stackTrace) => const Icon(Icons.lock, color: Colors.grey, size: 30)),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reward['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked ? Colors.green.shade800 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isUnlocked ? "Đã mở khóa" : "Cần đạt Lv ${reward['level']}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isUnlocked ? Colors.green : Colors.grey,
                                      fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
