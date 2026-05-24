import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'pt_detail_screen.dart';

class PTRankingScreen extends StatelessWidget {
  const PTRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("BẢNG XẾP HẠNG PT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
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
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.star), text: "Đánh giá"),
              Tab(icon: Icon(Icons.people), text: "Theo dõi"),
              Tab(icon: Icon(Icons.local_fire_department), text: "Năng nổ"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RankingList(orderBy: 'rating'),
            _RankingList(orderBy: 'followerCount'),
            _RankingList(orderBy: 'challengeCount'),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final String orderBy;

  const _RankingList({required this.orderBy});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'PT')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu", style: TextStyle(color: Colors.red.shade400)));
        }

        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("Chưa có dữ liệu xếp hạng."));
        }

        // Lọc và sắp xếp local để tránh lỗi thiếu Composite Index của Firestore
        List<UserModel> pts = docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        
        pts.sort((a, b) {
          if (orderBy == 'rating') {
            return b.rating.compareTo(a.rating);
          } else if (orderBy == 'followerCount') {
            return b.followerCount.compareTo(a.followerCount);
          } else {
            return b.challengeCount.compareTo(a.challengeCount);
          }
        });

        // Chỉ lấy top 10
        if (pts.length > 10) {
          pts = pts.sublist(0, 10);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pts.length,
          itemBuilder: (context, index) {
            UserModel pt = pts[index];
            
            // Xử lý Giao diện màu sắc Top 1, 2, 3
            Color rankColor;
            IconData rankIcon;
            if (index == 0) {
              rankColor = Colors.amber;
              rankIcon = Icons.emoji_events;
            } else if (index == 1) {
              rankColor = Colors.grey.shade400;
              rankIcon = Icons.military_tech;
            } else if (index == 2) {
              rankColor = Colors.orange.shade300;
              rankIcon = Icons.military_tech;
            } else {
              rankColor = Colors.green.shade100;
              rankIcon = Icons.star_border;
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PTDetailScreen(ptData: pt.toMap(), ptUid: pt.uid)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: index < 3 ? rankColor : Colors.grey.shade200, width: index < 3 ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: index < 3 ? rankColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Cột Rank
                    SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(rankIcon, color: index < 3 ? rankColor : Colors.green.shade300, size: index == 0 ? 32 : 28),
                          Text("#${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: index < 3 ? rankColor : Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Ảnh đại diện
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green.shade50,
                      backgroundImage: pt.avatar != null && pt.avatar!.isNotEmpty ? NetworkImage(pt.avatar!) : null,
                      child: (pt.avatar == null || pt.avatar!.isEmpty) ? const Icon(Icons.person, color: Colors.green) : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Thông tin PT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pt.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(pt.specialty ?? "Chuyên gia Thể hình", style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                        ],
                      ),
                    ),
                    
                    // Chỉ số Ranking
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (orderBy == 'rating') ...[
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(pt.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ] else if (orderBy == 'followerCount') ...[
                          const Icon(Icons.people, color: Colors.blue, size: 20),
                          Text("${pt.followerCount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ] else ...[
                          const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 20),
                          Text("${pt.challengeCount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
