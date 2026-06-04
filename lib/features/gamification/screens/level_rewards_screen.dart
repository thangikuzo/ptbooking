import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';

class LevelRewardsScreen extends StatelessWidget {
  const LevelRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Lộ Trình Quà Cấp Độ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D5D9B), Color(0xFF4BA3E3)],
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          int currentLevel = userData?['level'] ?? 1;
          final List<Map<String, dynamic>> rewards = GamificationConstants.LEVEL_REWARDS;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              // HEADER ROAD BANNER
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B2447), Color(0xFF1D5D9B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        "CON ĐƯỜNG THĂNG TIẾN",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Hãy tích cực hoàn thành thử thách từ các PT để nâng cấp level của bạn và nhận các phần thưởng khung ảnh/khung chat độc quyền!",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // TIMELINE TRACK LIST
              ...List.generate(rewards.length, (index) {
                var reward = rewards[index];
                bool isUnlocked = currentLevel >= (reward['level'] as int);

                return FadeInUp(
                  duration: Duration(milliseconds: 200 + (index * 100)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Left Column: Connector Line + Nodes
                      Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: isUnlocked
                                  ? const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isUnlocked ? null : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              boxShadow: isUnlocked
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.25),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                "Lv ${reward['level']}",
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (index != rewards.length - 1)
                            Container(
                              width: 3.5,
                              height: 65,
                              decoration: BoxDecoration(
                                color: isUnlocked ? Colors.green.shade500.withOpacity(0.4) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Timeline Right Column: Reward Details Card
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnlocked ? Colors.green.withOpacity(0.2) : Colors.grey.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isUnlocked ? Colors.green.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Reward Icon
                              Container(
                                width: 55,
                                height: 55,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isUnlocked ? AppColors.primaryLight : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isUnlocked
                                    ? Image.asset(
                                        reward['image'],
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.star, color: AppColors.primary, size: 28),
                                      )
                                    : ColorFiltered(
                                        colorFilter: const ColorFilter.matrix(<double>[
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0,      0,      0,      1, 0,
                                        ]),
                                        child: Image.asset(
                                          reward['image'],
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.lock, color: Colors.grey, size: 28),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),

                              // Info Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward['title'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked ? AppColors.text : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isUnlocked ? "Đã mở khóa" : "Yêu cầu Cấp độ ${reward['level']}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isUnlocked ? Colors.green : Colors.grey.shade500,
                                        fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Lock / Check Status Icon
                              Icon(
                                isUnlocked ? Icons.check_circle : Icons.lock_outline,
                                color: isUnlocked ? Colors.green : Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
