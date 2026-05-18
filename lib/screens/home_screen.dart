import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // <-- DÙNG USER MODEL
import 'pt_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Text("Xin chào, Học viên!", style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text("Tìm PT phù hợp ngay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar (Giữ nguyên UI của ông)
            TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm PT...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Banner (Giữ nguyên)
            _buildBanner(accentColor),
            const SizedBox(height: 20),

            Text("PT Nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),

            // 3. DANH SÁCH PT - ĐÃ NÂNG CẤP MODEL
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'PT').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

                  var docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const Text("Chưa có PT nào.");

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      // Ép kiểu doc sang UserModel
                      UserModel pt = UserModel.fromFirestore(docs[index]);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PTDetailScreen(
                                ptUid: pt.uid,
                                ptData: pt.toMap(), // Vẫn truyền map cho PTDetail nhận (đến khi fix file đó)
                              ),
                            ),
                          );
                        },
                        child: _buildPTCard(pt, primaryColor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con để code Home nhìn sạch hơn
  Widget _buildPTCard(UserModel pt, Color primaryColor) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: (pt.avatar != null && pt.avatar!.isNotEmpty)
                  ? ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  pt.avatar!,
                  fit: BoxFit.cover, // Ảnh sẽ phủ kín khung xám
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              )
                  : const Center(child: Icon(Icons.person, size: 50, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pt.name, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor), maxLines: 1),
                Text(pt.specialty ?? "Chuyên môn", style: const TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBanner(Color accentColor) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: Text("BANNER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }
}