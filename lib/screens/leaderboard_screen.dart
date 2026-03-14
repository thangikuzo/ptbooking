import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  final String challengeTitle;

  const LeaderboardScreen({super.key, required this.challengeTitle});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _rankedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndSortLeaderboard();
  }

  Future<void> _fetchAndSortLeaderboard() async {
    try {
      // 1. Chỉ lấy những bài nộp của Thử thách này
      var snapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('challengeId', isEqualTo: widget.challengeTitle)
          .get();

      // 2. LỌC BẰNG DART: Lấy ra những bài ĐÃ CHẤM ĐIỂM
      var gradedDocs = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['status'] == 'Đã chấm')
          .toList();

      // 3. SẮP XẾP BẰNG DART: Điểm từ Cao xuống Thấp
      gradedDocs.sort((a, b) {
        int scoreA = a['score'] ?? 0;
        int scoreB = b['score'] ?? 0;
        return scoreB.compareTo(scoreA); // Đảo ngược B lên trước A để xếp giảm dần
      });

      if (mounted) {
        setState(() {
          _rankedUsers = gradedDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi Leaderboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm chọn màu Huy chương
  Color _getMedalColor(int index) {
    if (index == 0) return Colors.amber; // Vàng
    if (index == 1) return Colors.grey.shade400; // Bạc
    if (index == 2) return Colors.brown.shade300; // Đồng
    return Colors.blue.shade100; // Khuyến khích
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Bảng Xếp Hạng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber.shade400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rankedUsers.isEmpty
          ? const Center(child: Text("Chưa có ai được chấm điểm!", style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rankedUsers.length,
        itemBuilder: (context, index) {
          var data = _rankedUsers[index];
          bool isTop3 = index < 3;

          return Card(
            elevation: isTop3 ? 4 : 1, // Top 3 thì nổi bật hơn
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isTop3 ? BorderSide(color: _getMedalColor(index), width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
                        ? NetworkImage(data['avatarUrl'])
                        : null,
                    child: (data['avatarUrl'] == null || data['avatarUrl'].toString().isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  // Gắn số Hạng (1, 2, 3...)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: _getMedalColor(index), shape: BoxShape.circle),
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              title: Text(data['userName'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text("Hoàn thành xuất sắc"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${data['score']}', style: TextStyle(color: _getMedalColor(index), fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Điểm', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}