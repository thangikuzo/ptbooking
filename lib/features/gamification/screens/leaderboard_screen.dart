import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/gamification/widgets/user_avatar_with_frame.dart';

class LeaderboardScreen extends StatefulWidget {
  final String challengeTitle;

  const LeaderboardScreen({super.key, required this.challengeTitle});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _scoreRanked = [];
  List<Map<String, dynamic>> _likeRanked = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndSortLeaderboard();
  }

  Future<void> _fetchAndSortLeaderboard() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('challengeId', isEqualTo: widget.challengeTitle)
          .get();
      var docs = snapshot.docs;

      List<Map<String, dynamic>> allItems = [];
      for (var doc in docs) {
        var data = doc.data();
        allItems.add({
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Ẩn danh',
          'avatarUrl': data['avatarUrl'] ?? '',
          'score': data['score'] ?? 0,
          'likeCount': (data['likedBy'] as List?)?.length ?? 0,
        });
      }

      // Clone và sort cho Chuyên môn (score)
      List<Map<String, dynamic>> byScore = List.from(allItems);
      byScore.sort((a, b) {
        int scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
        if (scoreCompare != 0) return scoreCompare;
        return (b['likeCount'] as int).compareTo(a['likeCount'] as int);
      });

      // Clone và sort cho Yêu thích (likes)
      List<Map<String, dynamic>> byLikes = List.from(allItems);
      byLikes.sort((a, b) {
        int likeCompare = (b['likeCount'] as int).compareTo(a['likeCount'] as int);
        if (likeCompare != 0) return likeCompare;
        return (b['score'] as int).compareTo(a['score'] as int);
      });

      if (mounted) {
        setState(() {
          _scoreRanked = byScore;
          _likeRanked = byLikes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải Leaderboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "BẢNG XẾP HẠNG",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
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
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.star), text: "Chuyên môn"),
              Tab(icon: Icon(Icons.favorite), text: "Yêu thích"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildRankView(_scoreRanked, isScoreRank: true),
                  _buildRankView(_likeRanked, isScoreRank: false),
                ],
              ),
      ),
    );
  }

  Widget _buildRankView(List<Map<String, dynamic>> list, {required bool isScoreRank}) {
    if (list.isEmpty) {
      return const Center(child: Text("Chưa có ai tham gia thử thách này."));
    }

    // Tách Top 3 ra làm Podium
    var top3 = list.take(3).toList();
    var rest = list.skip(3).toList();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // 1. VISUAL PODIUM FOR TOP 3
          if (top3.isNotEmpty)
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rank 2
                    if (top3.length > 1)
                      _buildPodiumUser(
                        user: top3[1],
                        rank: 2,
                        scoreText: isScoreRank ? "${top3[1]['score']}đ" : "${top3[1]['likeCount']} tim",
                        color: const Color(0xFF94A3B8),
                        height: 70,
                      ),
                    
                    const SizedBox(width: 16),

                    // Rank 1
                    _buildPodiumUser(
                      user: top3[0],
                      rank: 1,
                      scoreText: isScoreRank ? "${top3[0]['score']}đ" : "${top3[0]['likeCount']} tim",
                      color: const Color(0xFFF59E0B),
                      height: 100,
                    ),

                    const SizedBox(width: 16),

                    // Rank 3
                    if (top3.length > 2)
                      _buildPodiumUser(
                        user: top3[2],
                        rank: 3,
                        scoreText: isScoreRank ? "${top3[2]['score']}đ" : "${top3[2]['likeCount']} tim",
                        color: const Color(0xFFF97316),
                        height: 55,
                      ),
                  ],
                ),
              ),
            ),

          // 2. SCROLLABLE REST OF THE LIST (RANK 4+)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rest.length,
              itemBuilder: (context, index) {
                var item = rest[index];
                int rank = index + 4;

                // Tab yêu thích chỉ được 1 nửa thưởng exp
                int expReward = 0;
                if (rank == 1) expReward = 50;
                if (rank == 2) expReward = 30;
                if (rank == 3) expReward = 10;

                if (!isScoreRank) {
                  expReward = (expReward / 2).floor();
                }

                return FadeInUp(
                  duration: Duration(milliseconds: 200 + (index % 5 * 100)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Rank Number
                          SizedBox(
                            width: 32,
                            child: Text(
                              "#$rank",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          
                          // Dynamic Avatar Frame Loader for lower ranks too!
                          _LeaderboardAvatarLoader(userId: item['userId'], avatarUrl: item['avatarUrl']),
                          
                          const SizedBox(width: 16),

                          // Username + Gift info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['userName'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (expReward > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.card_giftcard, size: 10, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          "+$expReward EXP",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Score Text
                          Text(
                            isScoreRank ? "${item['score']} điểm" : "${item['likeCount']} tim",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isScoreRank ? Colors.amber.shade700 : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser({
    required Map<String, dynamic> user,
    required int rank,
    required String scoreText,
    required Color color,
    required double height,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown/Rank Badge at top
        if (rank == 1)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "#$rank",
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),

        // Avatar Loader
        _LeaderboardAvatarLoader(userId: user['userId'], avatarUrl: user['avatarUrl'], size: rank == 1 ? 55 : 46),

        const SizedBox(height: 8),
        
        // Name
        SizedBox(
          width: 80,
          child: Text(
            user['userName'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Score
        Text(
          scoreText,
          style: TextStyle(color: rank == 1 ? Colors.amber.shade700 : color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        
        const SizedBox(height: 8),

        // 3D-podium Base Column
        Container(
          width: 75,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Sub-widget that dynamically loads the user's selectedFrame in the background for rankings
class _LeaderboardAvatarLoader extends StatefulWidget {
  final String userId;
  final String avatarUrl;
  final double size;

  const _LeaderboardAvatarLoader({
    required this.userId,
    required this.avatarUrl,
    this.size = 40,
  });

  @override
  State<_LeaderboardAvatarLoader> createState() => _LeaderboardAvatarLoaderState();
}

class _LeaderboardAvatarLoaderState extends State<_LeaderboardAvatarLoader> {
  String? _selectedFrame;

  @override
  void initState() {
    super.initState();
    _fetchUserFrame();
  }

  Future<void> _fetchUserFrame() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _selectedFrame = doc.data()?['selectedFrame']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Lỗi load frame bảng xếp hạng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatarWithFrame(
      avatarUrl: widget.avatarUrl,
      selectedFrame: _selectedFrame,
      size: widget.size,
    );
  }
}
