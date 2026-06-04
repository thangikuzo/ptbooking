import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/features/auth/models/user_model.dart';
import 'package:ptbooking/features/pt_booking/screens/pt_detail_screen.dart';
import 'package:ptbooking/core/utils/string_utils.dart';

class HomeFeaturedPTsSection extends StatelessWidget {
  final String searchText;
  final String selectedCategory;
  final List<Map<String, dynamic>> categories;

  const HomeFeaturedPTsSection({
    super.key,
    required this.searchText,
    required this.selectedCategory,
    required this.categories,
  });

  List<UserModel> _filterPTs(List<UserModel> pts) {
    final query = StringUtils.normalizeText(searchText.trim());
    final selectedCat = categories.firstWhere(
      (cat) => cat['name'] == selectedCategory,
      orElse: () => categories.first,
    );
    final keywords = List<String>.from(selectedCat['keywords'] as List);

    return pts.where((pt) {
      final searchableText = StringUtils.normalizeText([pt.name, pt.specialty ?? '', pt.bio ?? '', pt.experience ?? ''].join(' '));

      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesCategory =
          keywords.isEmpty || keywords.any((keyword) => searchableText.contains(StringUtils.normalizeText(keyword)));

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildErrorImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  Widget _buildPTCardRating(String ptUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('pt_id', isEqualTo: ptUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 14),
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
            const Icon(Icons.star, color: Color(0xFF4BA3E3), size: 14),
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

  @override
  Widget build(BuildContext context) {
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

          List<UserModel> pts = docs.map((doc) => UserModel.fromFirestore(doc)).toList();
          pts = _filterPTs(pts);

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
                                    alignment: Alignment.topCenter,
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
                                child: _buildPTCardRating(pt.uid),
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
}
