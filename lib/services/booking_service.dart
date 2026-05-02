import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Tạo đơn đặt lịch mới
  Future<void> createBooking(BookingModel booking) async {
    await _firestore.collection('bookings').add(booking.toMap());
  }

  // 2. Lấy danh sách các giờ đã bị đặt (Confirmed) trong 1 ngày của 1 PT
  Future<List<String>> getBookedSlots(String ptId, DateTime date) async {
    String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    var snapshot = await _firestore
        .collection('bookings')
        .where('pt_id', isEqualTo: ptId)
        .where('booking_date', isEqualTo: dateStr)
        .where('status', isEqualTo: 'confirmed')
        .get();

    return snapshot.docs.map((doc) => doc['time_slot'].toString()).toList();
  }

  // 3. (Dùng cho PT) Cập nhật trạng thái đơn
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({'status': newStatus});
  }
}