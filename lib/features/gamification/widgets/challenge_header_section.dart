import 'package:flutter/material.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/gamification/models/challenge_model.dart';
import 'package:ptbooking/features/gamification/screens/leaderboard_screen.dart';

class ChallengeHeaderSection extends StatelessWidget {
  final Challenge challenge;
  final String timeRemaining;
  final String? currentUserRole;
  final String? currentUserId;
  final bool isFollowingPT;
  final bool isJoined;
  final bool hasSubmitted;
  final int userRating;
  final VoidCallback onDistributeRewards;
  final VoidCallback onToggleFollow;
  final VoidCallback onJoinChallenge;
  final ValueChanged<int> onRateChallenge;

  const ChallengeHeaderSection({
    super.key,
    required this.challenge,
    required this.timeRemaining,
    required this.currentUserRole,
    required this.currentUserId,
    required this.isFollowingPT,
    required this.isJoined,
    required this.hasSubmitted,
    required this.userRating,
    required this.onDistributeRewards,
    required this.onToggleFollow,
    required this.onJoinChallenge,
    required this.onRateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: AppColors.primaryLight,
      child: Column(
        children: [
          Image.network(
            challenge.imageUrl,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 100),
          ),
          const SizedBox(height: 16),

          Text(challenge.description, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Colors.red),
              const SizedBox(width: 5),
              Text(
                timeRemaining,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardScreen(challengeTitle: challenge.id),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events, color: AppColors.primary),
              label: const Text(
                "XEM BẢNG XẾP HẠNG",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 2),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (currentUserRole == 'PT' &&
              timeRemaining == "Đã kết thúc" &&
              challenge.creatorId == currentUserId &&
              !challenge.isRewardsDistributed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDistributeRewards,
                icon: const Icon(Icons.card_giftcard),
                label: const Text("TRAO THƯỞNG & KẾT THÚC", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  '+${challenge.points} EXP',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (currentUserRole != 'PT' && challenge.creatorId.isNotEmpty)
                OutlinedButton.icon(
                  icon: Icon(isFollowingPT ? Icons.check : Icons.person_add, color: AppColors.primary),
                  label: Text(isFollowingPT ? "Đang theo dõi PT" : "Theo dõi PT"),
                  onPressed: onToggleFollow,
                ),
              if (currentUserRole != 'PT')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isJoined ? Colors.grey : AppColors.primary),
                  onPressed: isJoined ? null : onJoinChallenge,
                  child: Text(
                    isJoined ? "ĐÃ THAM GIA" : "THAM GIA",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          // Rating Section cho User đã nộp bài
          if (hasSubmitted && userRating == 0) ...[
            const Divider(height: 30),
            const Text("Đánh giá thử thách này", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  icon: const Icon(Icons.star_border, color: Colors.amber, size: 30),
                  onPressed: () => onRateChallenge(i + 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
