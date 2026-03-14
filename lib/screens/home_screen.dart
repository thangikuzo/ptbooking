import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../models/pt_model.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PT> ptList = [];
  bool isLoading = false;

  Future<void> fetchPTByDays(List<String> days) async {
    if (days.isEmpty) {
      setState(() {
        ptList = [];
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'PT')
        .get();

    List<PT> result = [];

    for (var doc in snapshot.docs) {
      final pt = PT.fromDoc(doc);
      bool match = days.any((d) => pt.schedule[d] == true);
      if (match) result.add(pt);
    }

    setState(() {
      ptList = result;
      isLoading = false;
    });
  }

  void _showBookingDialog(PT pt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text("Thuê PT ${pt.name}"),
        content: Text(
            "Giá ${pt.price ~/ 1000}k/buổi\nBạn sẽ được chuyển đến trang thanh toán."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    pt: pt,
                    onPaymentSuccess: () => _createPendingBooking(pt),
                  ),
                ),
              );
            },
            child: const Text("Thanh toán"),
          ),
        ],
      ),
    );
  }

  Future<void> _createPendingBooking(PT pt) async {
    await FirebaseFirestore.instance.collection('bookings').add({
      'ptId': pt.id,
      'price': pt.price,
      'status': 'pending_approval',
      'createdAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'completed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã gửi yêu cầu thuê PT")),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6B6B);
    const accent = Color(0xFFFFD93D);
    const bg = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bg,

      /// 🔥 APPBAR CAO CẤP
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Tìm PT Phù Hợp",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF6B6B)],
            ),
          ),
        ),
      ),

      body: Column(
        children: [

          /// 📅 CHỌN NGÀY
          FadeInDown(
            child: MultiWeekdaySelector(
              onChanged: fetchPTByDays,
              primaryColor: primary,
            ),
          ),

          /// 📋 DANH SÁCH PT
          Expanded(
            child: isLoading
                ? _buildShimmer()
                : ptList.isEmpty
                ? _emptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ptList.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 100 * i),
                child: _ptCard(ptList[i], primary, accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// ⭐ CARD PT PREMIUM
  /// =========================================================

  Widget _ptCard(PT pt, Color primary, Color accent) {
    return GestureDetector(
      onTap: () => _showBookingDialog(pt),
      child: Container(
        height: 210,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [

              /// 🖼️ ẢNH NỀN
              Positioned.fill(
                child: pt.avatar.isNotEmpty
                    ? Image.network(pt.avatar, fit: BoxFit.cover)
                    : Container(color: Colors.grey),
              ),

              /// 🌑 GRADIENT
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black45,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// ⭐ RATING
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        pt.rating?.toStringAsFixed(1) ?? "4.8",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              /// 📋 THÔNG TIN
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      Text(
                        pt.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      Text(
                        pt.specialty,
                        style: TextStyle(color: Colors.grey[300]),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.work,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${pt.experience ?? 0} năm KN",
                            style:
                            const TextStyle(color: Colors.white70),
                          ),

                          const Spacer(),

                          Text(
                            "${pt.price ~/ 1000}k",
                            style: TextStyle(
                              fontSize: 22,
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () => _showBookingDialog(pt),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Thuê ngay"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// ✨ SHIMMER
  /// =========================================================

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 210,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// 📭 EMPTY STATE
  /// =========================================================

  Widget _emptyState() {
    return const Center(
      child: Text(
        "Chọn ngày để tìm PT phù hợp",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

/// =========================================================
/// 📅 SELECTOR NGÀY
/// =========================================================

class MultiWeekdaySelector extends StatefulWidget {
  final Function(List<String>) onChanged;
  final Color primaryColor;

  const MultiWeekdaySelector({
    super.key,
    required this.onChanged,
    required this.primaryColor,
  });

  @override
  State<MultiWeekdaySelector> createState() =>
      _MultiWeekdaySelectorState();
}

class _MultiWeekdaySelectorState
    extends State<MultiWeekdaySelector> {
  final weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: weekdays.length,
        itemBuilder: (_, i) {
          final isSel = selected.contains(i);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(weekdays[i]),
              selected: isSel,
              selectedColor: widget.primaryColor,
              labelStyle: TextStyle(
                color: isSel ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (v) {
                setState(() {
                  v ? selected.add(i) : selected.remove(i);
                });

                widget.onChanged(
                    selected.map((e) => weekdays[e]).toList());
              },
            ),
          );
        },
      ),
    );
  }
}