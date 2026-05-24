import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'pt_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Lấy tên người dùng (Nếu chưa có thì để mặc định)
  String get _userName {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    return "Học viên";
  }

  @override
  Widget build(BuildContext context) {
    // KHÔNG dùng bottomNavigationBar ở đây vì MainWrapper đã quản lý
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top AppBar Custom
              _buildHeader(),

              // 2. Search Bar
              _buildSearchBar(),

              // 3. Upcoming Session (Tạm thời là UI tĩnh)
              _buildUpcomingSession(),

              // 4. Promotion Banner
              _buildPromotionBanner(),

              // 5. Categories
              _buildCategories(),

              // 6. Featured PTs (Đã nối Firebase)
              _buildSectionHeader("PT Nổi bật", true),
              _buildFeaturedPTs(),

              // 7. New Arrivals (UI mẫu)
              _buildSectionHeader("PT Mới gia nhập", false),
              _buildNewArrivals(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE1E3E4), width: 2),
                ),
                child: ClipOval(
                  child: (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty)
                      ? Image.network(_currentUser!.photoURL!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Color(0xFF18253E)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Xin chào, $_userName!",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18253E)),
                  ),
                  Text(
                    "Tìm PT phù hợp ngay",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF18253E)),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Tìm kiếm PT, bộ môn...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildUpcomingSession() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18253E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF18253E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today,
                color: Color(0xFFFFA515), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Buổi tập tiếp theo",
                    style: TextStyle(color: Color(0xFF98A5C4), fontSize: 12)),
                Text("18:00 - Hôm nay với PT Minh Quân",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA515), Color(0xFFFFC25C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFFFFA515).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.fitness_center, size: 140, color: Colors.white.withOpacity(0.3)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 200,
                  child: Text(
                    "Giảm 20% cho buổi tập đầu tiên",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF18253E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text("Nhận ưu đãi ngay",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Gym', 'icon': Icons.fitness_center},
      {'name': 'Yoga', 'icon': Icons.self_improvement},
      {'name': 'Boxing', 'icon': Icons.sports_mma},
      {'name': 'Pilates', 'icon': Icons.accessibility_new},
      {'name': 'Crossfit', 'icon': Icons.timer},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: Icon(categories[index]['icon'] as IconData,
                      color: const Color(0xFF18253E)),
                ),
                const SizedBox(height: 8),
                Text(categories[index]['name'] as String,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF18253E))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool showAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18253E))),
          if (showAction)
            TextButton(
              onPressed: () {},
              child: const Text("Xem tất cả",
                  style: TextStyle(
                      color: Color(0xFFFFA515), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔥 ĐỔ DỮ LIỆU PT TỪ FIREBASE VÀO GIAO DIỆN MỚI
  // ==========================================================
  Widget _buildFeaturedPTs() {
    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'PT').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có PT nào."));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              UserModel pt = UserModel.fromFirestore(docs[index]);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PTDetailScreen(ptUid: pt.uid, ptData: pt.toMap()),
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE1E3E4)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Stack(
                          children: [
                            // Render Ảnh PT từ Firebase
                            (pt.avatar != null && pt.avatar!.isNotEmpty)
                                ? Image.network(pt.avatar!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildErrorImage())
                                : _buildErrorImage(),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star, color: Color(0xFFFFA515), size: 14),
                                    Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pt.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF18253E))),
                            const SizedBox(height: 4),
                            Text(pt.specialty ?? "Chuyên gia Thể hình", maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF855300), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget hiển thị nếu PT chưa có ảnh đại diện
  Widget _buildErrorImage() {
    return Container(
      height: 160, width: double.infinity, color: Colors.grey[200],
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  // ==========================================================
  // DỮ LIỆU MẪU CHO MỤC PT MỚI (Có thể nối Firebase sau)
  // ==========================================================
  Widget _buildNewArrivals() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E3E4)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60, height: 60, color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(index == 0 ? "Phan Anh" : "Trần Long", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18253E))),
                    Text(index == 0 ? "Chuyên gia Pilates • 5 năm" : "Giảm cân • Dinh dưỡng",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFDDB8), borderRadius: BorderRadius.circular(20)),
                child: const Text("NEW", style: TextStyle(color: Color(0xFF653E00), fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }
}