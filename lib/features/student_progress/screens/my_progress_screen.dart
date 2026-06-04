import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ptbooking/features/pt_booking/models/booking_model.dart';
import 'package:ptbooking/features/pt_booking/screens/package_detail_screen.dart';

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

  Widget _buildActivePackagesSection(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gói tập đang hoạt động",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final booking = BookingModel.fromFirestore(doc);
              final progress = booking.sessionCount > 0
                  ? booking.completedSessions / booking.sessionCount
                  : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PackageDetailScreen(bookingId: booking.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: const Color(0xFF4BA3E3).withOpacity(0.1),
                                 shape: BoxShape.circle,
                               ),
                               child: const Icon(Icons.fitness_center, color: Color(0xFF4BA3E3), size: 20),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     booking.packageName.isNotEmpty ? booking.packageName : "Gói tập cá nhân",
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B2447)),
                                   ),
                                   const SizedBox(height: 2),
                                   Text(
                                     "PT: ${booking.ptName}",
                                     style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                   ),
                                 ],
                               ),
                             ),
                             const Icon(Icons.chevron_right, color: Colors.grey),
                           ],
                         ),
                         const SizedBox(height: 14),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               "Tiến độ: ${booking.completedSessions} / ${booking.sessionCount} buổi",
                               style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500),
                             ),
                             Text(
                               "${(progress * 100).toInt()}%",
                               style: const TextStyle(color: Color(0xFF4BA3E3), fontSize: 13, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                         const SizedBox(height: 6),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(10),
                           child: LinearProgressIndicator(
                             value: progress,
                             backgroundColor: Colors.grey[200],
                             color: const Color(0xFF4BA3E3),
                             minHeight: 6,
                           ),
                         ),
                       ],
                     ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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

          // Sắp xếp các nhận xét cũ từ PT
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildActivePackagesSection(context, currentUser.uid),
              if (sortedDocs.isNotEmpty) ...[
                _buildSummaryCard(sortedDocs.first.data() as Map<String, dynamic>),
                const SizedBox(height: 16),
                _buildNoteCard(sortedDocs.first.data() as Map<String, dynamic>),
                const SizedBox(height: 16),
                _buildScoreChart(sortedDocs.first.data() as Map<String, dynamic>),
                const SizedBox(height: 18),
                const Text("Lịch sử nhận xét của PT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2447))),
                const SizedBox(height: 10),
                ...sortedDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildHistoryCard(context, data);
                }),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "Bạn chưa có bảng đánh giá định kỳ nào từ PT.",
                    style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
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
    final ptName = data['pt_name']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Nhận xét từ PT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (ptName.isNotEmpty)
                Text(
                  "PT: $ptName",
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(note.isEmpty ? "Chưa có nhận xét." : note, style: const TextStyle(height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  void _showHistoryDetailBottomSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final totalScore = _toDouble(data['total_score']);
        final rank = data['rank'] ?? 'Chưa xếp loại';
        final note = data['note']?.toString() ?? '';
        final ptName = data['pt_name']?.toString() ?? '';

        Color rankColor = Colors.red;
        if (totalScore >= 8) {
          rankColor = Colors.green;
        } else if (totalScore >= 6.5) {
          rankColor = Colors.orange;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _periodText(data),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Xếp loại: $rank",
                        style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rankColor.withOpacity(0.1),
                      border: Border.all(color: rankColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        totalScore.toStringAsFixed(1),
                        style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (ptName.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "Đánh giá bởi PT: $ptName",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Điểm chi tiết",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
              ),
              const SizedBox(height: 12),
              _buildScoreItem("Chuyên cần", _toInt(data['attendance_score']), Icons.event_available),
              _buildScoreItem("Kỹ thuật", _toInt(data['technique_score']), Icons.fitness_center),
              _buildScoreItem("Thể lực", _toInt(data['stamina_score']), Icons.bolt),
              _buildScoreItem("Thái độ", _toInt(data['attitude_score']), Icons.psychology),
              _buildScoreItem("Dinh dưỡng", _toInt(data['nutrition_score']), Icons.restaurant_menu),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Nhận xét từ PT",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
              ),
              const SizedBox(height: 8),
              Text(
                note.isEmpty ? "Không có nhận xét cho tuần này." : note,
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2447),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ĐÓNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreItem(String title, int score, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4BA3E3), size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: score / 10,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF4BA3E3),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text("$score/10", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data) {
    final totalScore = _toDouble(data['total_score']);
    final rank = data['rank'] ?? 'Chưa xếp loại';
    final ptName = data['pt_name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showHistoryDetailBottomSheet(context, data),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                      Text(
                        "Điểm: ${totalScore.toStringAsFixed(1)} - $rank${ptName.isNotEmpty ? ' | PT: $ptName' : ''}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
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
