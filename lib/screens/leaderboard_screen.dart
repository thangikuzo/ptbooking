import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          .where('challengeId', isEqualTo: widget.challengeTitle) // challengeTitle thực chất đang chứa ID
          .get();
      var docs = snapshot.docs;

      List<Map<String, dynamic>> allItems = [];
      for (var doc in docs) {
        var data = doc.data();
        allItems.add({
          'userName': data['userName'] ?? 'Ẩn danh',
          'avatarUrl': data['avatarUrl'] ?? '',
          'score': data['score'] ?? 0,
          'likeCount': (data['likedBy'] as List?)?.length ?? 0,
        });
      }

      // Clone và sort cho Chuyên môn (score)
      List<Map<String, dynamic>> byScore = List.from(allItems);
      byScore.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Clone và sort cho Yêu thích (likes)
      List<Map<String, dynamic>> byLikes = List.from(allItems);
      byLikes.sort((a, b) => (b['likeCount'] as int).compareTo(a['likeCount'] as int));

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
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : TabBarView(
                children: [
                  _buildRankList(_scoreRanked, isScoreRank: true),
                  _buildRankList(_likeRanked, isScoreRank: false),
                ],
              ),
      ),
    );
  }

  Widget _buildRankList(List<Map<String, dynamic>> list, {required bool isScoreRank}) {
    if (list.isEmpty) {
      return const Center(child: Text("Chưa có ai tham gia thử thách này."));
    }

    return Container(
      color: const Color(0xFFF6F8FC), // Nền xanh nhạt
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          var item = list[index];
          int rank = index + 1;

          Color rankColor;
          IconData rankIcon;

          if (rank == 1) {
            rankColor = Colors.amber;
            rankIcon = Icons.emoji_events;
          } else if (rank == 2) {
            rankColor = Colors.grey.shade400;
            rankIcon = Icons.military_tech;
          } else if (rank == 3) {
            rankColor = Colors.orange.shade300;
            rankIcon = Icons.military_tech;
          } else {
            rankColor = Colors.green.shade100;
            rankIcon = Icons.star_border;
          }

          // Logic tính phần thưởng Gamification
          int expReward = 0;
          if (rank == 1)
            expReward = 50;
          else if (rank == 2)
            expReward = 30;
          else if (rank == 3)
            expReward = 10;

          // Tab yêu thích chỉ được 1 nửa thưởng
          if (!isScoreRank) {
            expReward = (expReward / 2).floor();
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: rank <= 3 ? rankColor : Colors.transparent, width: 2),
            ),
            elevation: rank <= 3 ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thứ hạng
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(rankIcon, color: rank <= 3 ? rankColor : Colors.green.shade300, size: rank == 1 ? 32 : 28),
                        Text(
                          "#$rank",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: rank <= 3 ? rankColor : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green.shade50,
                    backgroundImage: item['avatarUrl'] != '' ? NetworkImage(item['avatarUrl']) : null,
                    child: item['avatarUrl'] == '' ? const Icon(Icons.person, color: Colors.green) : null,
                  ),
                  const SizedBox(width: 16),

                  // Tên + Quà
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['userName'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (expReward > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  "+$expReward EXP",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Chỉ số
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isScoreRank ? "${item['score']} điểm" : "${item['likeCount']} tim",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isScoreRank ? Colors.amber.shade700 : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      if (isScoreRank && item['score'] == 0)
                        const Text("(Chưa chấm)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
