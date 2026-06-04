import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/features/pt_booking/models/booking_model.dart';
import 'package:ptbooking/features/chat/screens/chat_screen.dart';

class UpcomingSessionBanner extends StatelessWidget {
  const UpcomingSessionBanner({super.key});

  DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timePart = timeStr.split('-').first.trim();
      final timeParts = timePart.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  String _getFriendlyDate(String bookingDate) {
    try {
      final dateParts = bookingDate.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final bookingDateTime = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (bookingDateTime == today) {
        return "Hôm nay";
      } else if (bookingDateTime == tomorrow) {
        return "Ngày mai";
      } else {
        return "$day/$month/$year";
      }
    } catch (e) {
      return bookingDate;
    }
  }

  Future<void> _messagePT(BuildContext context, BookingModel booking) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF4BA3E3))),
    );

    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('customer_id', isEqualTo: currentUser.uid)
          .where('pt_id', isEqualTo: booking.ptId)
          .limit(1)
          .get();

      String chatId;
      if (chatQuery.docs.isNotEmpty) {
        chatId = chatQuery.docs.first.id;
      } else {
        final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
          'customer_id': currentUser.uid,
          'customer_name': currentUser.displayName ?? 'Học viên',
          'pt_id': booking.ptId,
          'pt_name': booking.ptName,
          'booking_id': booking.id,
          'last_message': '',
          'updated_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });
        chatId = chatDoc.id;
      }

      if (context.mounted) {
        Navigator.pop(context); // Đóng dialog loading
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Đóng dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSessionDetails(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isConfirmed = booking.status == 'confirmed';
        final friendlyDate = _getFriendlyDate(booking.bookingDate);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chi tiết buổi tập",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B2447),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConfirmed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isConfirmed ? "Đã xác nhận" : "Chờ xác nhận",
                      style: TextStyle(
                        color: isConfirmed ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.person, "Huấn luyện viên", booking.ptName),
              _buildDetailRow(Icons.access_time, "Khung giờ", booking.timeSlot),
              _buildDetailRow(Icons.calendar_month, "Ngày tập", "$friendlyDate (${booking.bookingDate})"),
              if (booking.packageName.isNotEmpty)
                _buildDetailRow(Icons.fitness_center, "Gói đăng ký", booking.packageName),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Đóng",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _messagePT(context, booking);
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text("Nhắn tin PT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4BA3E3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4BA3E3), size: 20),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B2447),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildBannerContainer(
        title: "Đăng nhập để xem lịch",
        subtitle: "Đăng nhập tài khoản của bạn ngay",
        icon: Icons.login_rounded,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng chọn tab Tài khoản để đăng nhập")),
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerContainer(
            title: "Đang tải...",
            subtitle: "Đang tải thông tin lịch tập",
            icon: Icons.hourglass_empty_rounded,
            onTap: () {},
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final bookings = docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

        // Lọc và sắp xếp các buổi tập trong tương lai
        final now = DateTime.now();
        final threshold = now.subtract(const Duration(hours: 1)); // Giữ hiển thị trong vòng 1 tiếng khi buổi tập diễn ra

        final upcomingBookings = bookings.where((b) {
          final isPendingOrConfirmed = b.status == 'confirmed' || b.status == 'pending';
          if (!isPendingOrConfirmed) return false;

          final bookingDt = _parseDateTime(b.bookingDate, b.timeSlot);
          if (bookingDt == null) return false;

          return bookingDt.isAfter(threshold);
        }).toList();

        // Sắp xếp tăng dần theo thời gian
        upcomingBookings.sort((a, b) {
          final aDt = _parseDateTime(a.bookingDate, a.timeSlot)!;
          final bDt = _parseDateTime(b.bookingDate, b.timeSlot)!;
          return aDt.compareTo(bDt);
        });

        if (upcomingBookings.isEmpty) {
          return _buildBannerContainer(
            title: "Bạn chưa có lịch tập",
            subtitle: "Chọn một PT bên dưới và đặt lịch tập ngay nhé!",
            icon: Icons.calendar_month_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Hãy chọn PT trong mục \"PT Nổi bật\" bên dưới để đặt lịch"),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          );
        }

        final nextBooking = upcomingBookings.first;
        final friendlyDate = _getFriendlyDate(nextBooking.bookingDate);
        final statusLabel = nextBooking.status == 'pending' ? ' [Chờ duyệt]' : '';
        final bannerText = "${nextBooking.timeSlot.split('-').first.trim()} - $friendlyDate với PT ${nextBooking.ptName}$statusLabel";

        return _buildBannerContainer(
          title: nextBooking.status == 'pending' ? "Yêu cầu đặt lịch mới" : "Buổi tập tiếp theo",
          subtitle: bannerText,
          icon: Icons.calendar_today,
          onTap: () => _showSessionDetails(context, nextBooking),
        );
      },
    );
  }

  Widget _buildBannerContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B2447),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2447).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF4BA3E3), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF98A5C4), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
