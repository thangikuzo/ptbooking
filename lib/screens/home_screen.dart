import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'pt_detail_screen.dart';
import '../services/gamification_service.dart';
import '../widgets/daily_reward_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GamificationService _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _checkDailyLogin();
  }

  Future<void> _checkDailyLogin() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      bool receivedReward = await _gamificationService.checkDailyLogin(currentUser.uid);
      if (receivedReward && mounted) {
        // Lấy thông tin user để xem chuỗi (tùy chọn, hoặc gọi nhanh để lấy dữ liệu mới)
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          int streak = (doc.data() as Map<String, dynamic>)['loginStreak'] as int? ?? 1;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DailyRewardDialog(streak: streak);
            },
          );
        }
      }
    }
  }

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 🔥 TRẠNG THÁI LỌC CHUYÊN MÔN (Mặc định hiển thị Tất cả)
  String _selectedCategory = 'Tất cả';
  String _searchText = '';

  String get _userName {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    return "Học viên";
  }

  // 🔥 MẢNG DANH MỤC ĐỂ ĐỔ UI VÀ BẮT SỰ KIỆN LỌC
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tất cả', 'icon': Icons.grid_view_rounded, 'keywords': <String>[]},
    {
      'name': 'Gym',
      'icon': Icons.fitness_center,
      'keywords': ['gym', 'tăng cơ', 'bodybuilding', 'strength'],
    },
    {
      'name': 'Giảm cân',
      'icon': Icons.local_fire_department,
      'keywords': ['giảm cân', 'fat loss', 'cardio', 'dinh dưỡng'],
    },
    {
      'name': 'Yoga',
      'icon': Icons.self_improvement,
      'keywords': ['yoga', 'stretching', 'thiền'],
    },
    {
      'name': 'Boxing',
      'icon': Icons.sports_mma,
      'keywords': ['boxing', 'kickboxing', 'mma'],
    },
    {
      'name': 'Pilates',
      'icon': Icons.accessibility_new,
      'keywords': ['pilates', 'core', 'phục hồi'],
    },
    {
      'name': 'Crossfit',
      'icon': Icons.timer,
      'keywords': ['crossfit', 'hiit', 'conditioning'],
    },
  ];

  @override
  Widget build(BuildContext context) {
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

              // 3. Upcoming Session
              _buildUpcomingSession(),

              // 4. Promotion Banner
              _buildPromotionBanner(),

              // 5. Categories (Thanh lọc chuyên môn đã được cơ cấu lại)
              _buildCategories(),

              // 6. Featured PTs (Danh sách PT đã kết hợp lọc chuyên môn + tính sao)
              _buildSectionHeader("PT Nổi bật", true),
              _buildFeaturedPTs(),

              // 7. New Arrivals
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
                      : const Icon(Icons.person, color: Color(0xFF0B2447)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Xin chào, $_userName!",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
                  ),
                  Text("Tìm PT phù hợp ngay", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B2447)),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Tìm kiếm PT, bộ môn...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  String _normalizeText(String value) {
    var result = value.toLowerCase();
    const replacements = <String, List<String>>{
      'a': ['à', 'á', 'ả', 'ã', 'ạ', 'ă', 'ằ', 'ắ', 'ẳ', 'ẵ', 'ặ', 'â', 'ầ', 'ấ', 'ẩ', 'ẫ', 'ậ'],
      'e': ['è', 'é', 'ẻ', 'ẽ', 'ẹ', 'ê', 'ề', 'ế', 'ể', 'ễ', 'ệ'],
      'i': ['ì', 'í', 'ỉ', 'ĩ', 'ị'],
      'o': ['ò', 'ó', 'ỏ', 'õ', 'ọ', 'ô', 'ồ', 'ố', 'ổ', 'ỗ', 'ộ', 'ơ', 'ờ', 'ớ', 'ở', 'ỡ', 'ợ'],
      'u': ['ù', 'ú', 'ủ', 'ũ', 'ụ', 'ư', 'ừ', 'ứ', 'ử', 'ữ', 'ự'],
      'y': ['ỳ', 'ý', 'ỷ', 'ỹ', 'ỵ'],
      'd': ['đ'],
    };

    replacements.forEach((replacement, chars) {
      for (final char in chars) {
        result = result.replaceAll(char, replacement);
      }
    });

    return result;
  }

  List<UserModel> _filterPTs(List<UserModel> pts) {
    final query = _normalizeText(_searchText.trim());
    final selectedCategory = _categories.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    final keywords = List<String>.from(selectedCategory['keywords'] as List);

    return pts.where((pt) {
      final searchableText = _normalizeText([pt.name, pt.specialty ?? '', pt.bio ?? '', pt.experience ?? ''].join(' '));

      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesCategory =
          keywords.isEmpty || keywords.any((keyword) => searchableText.contains(_normalizeText(keyword)));

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildUpcomingSession() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2447),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B2447).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_today, color: Color(0xFF4BA3E3), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Buổi tập tiếp theo", style: TextStyle(color: Color(0xFF98A5C4), fontSize: 12)),
                Text(
                  "18:00 - Hôm nay với PT Minh Quân",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
          colors: [Color(0xFF4BA3E3), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4BA3E3).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
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
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B2447),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("Nhận ưu đãi ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 THANH CHỌN CATEGORY CÓ TRẠNG THÁI ĐỔI MÀU KHI SELECTED
  Widget _buildCategories() {
    return SizedBox(
      height: 140, // Đã fix chiều cao an toàn chống overflow chữ
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          bool isSelected = _selectedCategory == cat['name'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['name'] as String;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      // Nếu được chọn -> đổi sang nền Xanh Navy đậm, ngược lại nền trắng
                      color: isSelected ? const Color(0xFF0B2447) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF0B2447) : const Color(0xFFE1E3E4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      // Nếu được chọn -> đổi icon sang màu trắng tinh khôi
                      color: isSelected ? Colors.white : const Color(0xFF0B2447),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF4BA3E3)
                          : const Color(0xFF0B2447), // Chọn thì chữ màu cam rực rỡ
                    ),
                  ),
                ],
              ),
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
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
          ),
          if (showAction)
            TextButton(
              onPressed: () {},
              child: const Text(
                "Xem tất cả",
                style: TextStyle(color: Color(0xFF4BA3E3), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // 🔥 DANH SÁCH PT NỔI BẬT: ĐÃ ỐP LOGIC LỌC CHUYÊN MÔN VÀ TÍNH SAO THẬT
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

          // 1. Ép kiểu dữ liệu sang List<UserModel>
          List<UserModel> pts = docs.map((doc) => UserModel.fromFirestore(doc)).toList();

          // 2. Lọc theo category và nội dung search của học viên
          pts = _filterPTs(pts);

          // Trường hợp lọc xong không có ông PT nào khớp
          if (pts.isEmpty) {
            return const Center(
              child: Text(
                "Không tìm thấy HLV phù hợp.",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: pts.length,
            itemBuilder: (context, index) {
              UserModel pt = pts[index];

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
                            (pt.avatar != null && pt.avatar!.isNotEmpty)
                                ? Image.network(
                                    pt.avatar!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildErrorImage(),
                                  )
                                : _buildErrorImage(),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _buildPTCardRating(pt.uid), // 🔥 ĐÃ THAY BẰNG HÀM ĐẾM SAO REAL-TIME
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pt.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0B2447),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pt.specialty ?? "Huấn luyện viên",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF855300),
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
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 TIỂU COMPONENT: TỰ ĐỘNG ĐẾM SAO TRUNG BÌNH NGOÀI HOME
  Widget _buildPTCardRating(String ptUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('pt_id', isEqualTo: ptUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // 🔥 TRƯỜNG HỢP CHƯA CÓ ĐÁNH GIÁ -> HIỂN THỊ 0.0 VÀ SAO XÁM
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 14), // Đổi thành sao rỗng xám
              SizedBox(width: 4),
              Text(
                "0.0",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        }

        var reviewDocs = snapshot.data!.docs;
        double totalStars = 0.0;
        for (var doc in reviewDocs) {
          var data = doc.data() as Map<String, dynamic>;
          totalStars += data['rating'] is num ? (data['rating'] as num).toDouble() : 5.0;
        }
        double avgRating = totalStars / reviewDocs.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Color(0xFF4BA3E3), size: 14), // Có điểm thì sao vàng cam
            const SizedBox(width: 4),
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0B2447)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

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
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index == 0 ? "Phan Anh" : "Trần Long",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
                    ),
                    Text(
                      index == 0 ? "Chuyên gia Pilates • 5 năm" : "Giảm cân • Dinh dưỡng",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFDDB8), borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  "NEW",
                  style: TextStyle(color: Color(0xFF653E00), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
