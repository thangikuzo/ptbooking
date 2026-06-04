import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/pt_booking/models/booking_model.dart';
import 'package:ptbooking/features/pt_booking/screens/package_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _translateDay(String day) {
    const days = {
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',
      'sunday': 'Chủ Nhật',
    };
    return days[day] ?? day;
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Chờ duyệt';
        break;
      case 'confirmed':
        color = AppColors.success;
        text = 'Đã chốt lịch';
        break;
      case 'canceled':
        color = AppColors.danger;
        text = 'Hủy/Từ chối';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Đã hoàn thành';
        break;
      default:
        color = Colors.grey;
        text = 'Không rõ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color = Colors.grey;
    String text = 'Chưa thanh toán';

    switch (status) {
      case 'held':
        color = Colors.indigo;
        text = 'Đã giữ tiền ví';
        break;
      case 'paid':
        color = AppColors.success;
        text = 'Đã thanh toán';
        break;
      case 'refunded_to_wallet':
        color = Colors.teal;
        text = 'Đã hoàn về ví';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập để xem lịch sử")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Lịch sử đặt lịch",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('user_id', isEqualTo: currentUser.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Bạn chưa có lịch đặt nào.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            );
          }

          // Calculate stats for dashboard
          int total = docs.length;
          int confirmed = docs.where((d) => d['status'] == 'confirmed').length;
          int completed = docs.where((d) => d['status'] == 'completed').length;

          return Column(
            children: [
              // 1. DASHBOARD OVERVIEW SUMMARY CARD
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("Tổng số gói", total.toString(), Colors.white),
                      Container(width: 1, height: 35, color: Colors.white24),
                      _buildStatColumn("Đang tập", confirmed.toString(), Colors.cyanAccent),
                      Container(width: 1, height: 35, color: Colors.white24),
                      _buildStatColumn("Đã hoàn thành", completed.toString(), Colors.orangeAccent),
                    ],
                  ),
                ),
              ),

              // SECTION HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      "DANH SÁCH LỊCH TẬP CHI TIẾT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  ],
                ),
              ),

              // 2. TIMELINE LIST VIEW
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    BookingModel booking = BookingModel.fromFirestore(docs[index]);
                    bool isDetailEnabled = (booking.status == 'confirmed' || booking.status == 'completed');

                    return FadeInUp(
                      duration: Duration(milliseconds: 200 + (index * 100)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isDetailEnabled
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PackageDetailScreen(bookingId: booking.id),
                                      ),
                                    );
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side gym icon wrapper with soft gradient
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.primaryLight, Colors.white],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 16),

                                  // Middle details section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "PT: ${booking.ptName}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Date Slot Row
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "${_translateDay(booking.day)} (${booking.bookingDate}) • ${booking.timeSlot}",
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Package Row
                                        if (booking.packageName.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.assignment_outlined, size: 13, color: Colors.grey.shade400),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Gói: ${booking.packageName} (${booking.sessionCount} buổi)",
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],

                                        const SizedBox(height: 12),
                                        
                                        // Badges Row
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildStatusBadge(booking.status),
                                            _buildPaymentBadge(booking.paymentStatus),
                                          ],
                                        ),
                                        
                                        // Dynamic link indicator
                                        if (isDetailEnabled) ...[
                                          const SizedBox(height: 10),
                                          const Divider(height: 10),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Xem lộ trình ca dạy",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary.withOpacity(0.9),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 8, color: AppColors.primary.withOpacity(0.9)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
