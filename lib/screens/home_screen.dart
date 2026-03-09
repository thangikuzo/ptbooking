import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo
    final Color primaryColor = const Color(0xFF2E3B55);
    final Color accentColor = const Color(0xFFFCA311);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Xin chào, User!", style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text("Tìm PT phù hợp ngay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thanh tìm kiếm
            TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm tên PT, bộ môn...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Banner quảng cáo
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Giảm giá 30%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 5),
                          Text("Cho gói tập đầu tiên", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  // Placeholder cho hình ảnh banner
                  Container(width: 120, height: 150, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. PT Nổi bật (Tiêu đề)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PT Nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                TextButton(onPressed: () {}, child: const Text("Xem tất cả")),
              ],
            ),

            // 4. Danh sách PT (Lướt ngang)
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: const Center(child: Icon(Icons.person, size: 50, color: Colors.grey)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PT Nguyễn Văn A", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const Text("Gym, Cardio", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}