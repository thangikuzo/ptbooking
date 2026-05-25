import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyProgressScreen extends StatelessWidget {
  const MyProgressScreen({super.key});

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _periodText(Map<String, dynamic> data) {
    final week = data['week'] ?? '?';
    final month = data['month'] ?? '?';
    final year = data['year'] ?? '?';
    return "Tuần $week - Tháng $month/$year";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Tiến độ của tôi"), backgroundColor: const Color(0xFF0B2447)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student_progress')
            .where('student_id', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa có bảng đánh giá tiến độ."));
          }

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['created_at_ms'];
            final bTime = bData['created_at_ms'];

            if (aTime is int && bTime is int) {
              return bTime.compareTo(aTime);
            }
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          final latestData = docs.first.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(latestData),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              _buildNoteCard(latestData),
              const SizedBox(height: 18),

              const Text("Lịch sử đánh giá theo tuần", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildHistoryCard(data);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final totalScore = _toDouble(data['total_score']);
    final rank = data['rank'] ?? 'Chưa xếp loại';

    Color rankColor = Colors.red;
    if (totalScore >= 8) {
      rankColor = Colors.green;
    } else if (totalScore >= 6.5) {
      rankColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0B2447), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: rankColor, width: 4),
            ),
            child: Center(
              child: Text(
                totalScore.toStringAsFixed(1),
                style: TextStyle(color: rankColor, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_periodText(data), style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  rank.toString(),
                  style: TextStyle(color: rankColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Đánh giá mới nhất từ PT", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart(Map<String, dynamic> data) {
    final scores = [
      {'title': 'Chuyên cần', 'score': _toInt(data['attendance_score']), 'icon': Icons.event_available},
      {'title': 'Kỹ thuật', 'score': _toInt(data['technique_score']), 'icon': Icons.fitness_center},
      {'title': 'Thể lực', 'score': _toInt(data['stamina_score']), 'icon': Icons.bolt},
      {'title': 'Thái độ', 'score': _toInt(data['attitude_score']), 'icon': Icons.psychology},
      {'title': 'Dinh dưỡng', 'score': _toInt(data['nutrition_score']), 'icon': Icons.restaurant_menu},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Điểm kỹ năng tuần này", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 16),

          ...scores.map((item) {
            final score = item['score'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF4BA3E3), size: 22),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 88,
                    child: Text(item['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: score / 10,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF4BA3E3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("$score/10", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> data) {
    final note = data['note']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nhận xét từ PT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Text(note.isEmpty ? "Chưa có nhận xét." : note, style: const TextStyle(height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final totalScore = _toDouble(data['total_score']);
    final rank = data['rank'] ?? 'Chưa xếp loại';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.15),
            child: const Icon(Icons.bar_chart, color: Colors.orange),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_periodText(data), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text("Điểm: ${totalScore.toStringAsFixed(1)} - $rank", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }
}
