import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> blockingStatuses = ['pending', 'confirmed'];

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String buildSlotLockId({required String ptId, required String bookingDate, required String timeSlot}) {
    final safeSlot = timeSlot.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '-');
    return '${ptId}_${bookingDate}_$safeSlot';
  }

  Future<List<String>> getAvailableSlots({required String ptId, required String day, required DateTime date}) async {
    final scheduleDoc = await _firestore.collection('schedules').doc(ptId).get();
    if (!scheduleDoc.exists || scheduleDoc.data()?['is_active'] == false) {
      return [];
    }

    final availability = scheduleDoc.data()?['availability'];
    if (availability is! Map || availability[day] == null) {
      return [];
    }

    final slots = List<String>.from(availability[day] as List)..sort();
    final bookedSlots = await getBookedSlots(ptId, date);
    return slots.where((slot) => !bookedSlots.contains(slot)).toList();
  }

  Future<String> createBooking(BookingModel booking) async {
    final slotLockId = buildSlotLockId(
      ptId: booking.ptId,
      bookingDate: booking.bookingDate,
      timeSlot: booking.timeSlot,
    );
    final bookingRef = _firestore.collection('bookings').doc();
    final slotRef = _firestore.collection('booking_slots').doc(slotLockId);
    final walletRef = _firestore.collection('wallets').doc(booking.userId);
    final walletTransactionRef = _firestore.collection('wallet_transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final slotSnapshot = await transaction.get(slotRef);
      final walletSnapshot = await transaction.get(walletRef);

      if (slotSnapshot.exists) {
        final data = slotSnapshot.data() as Map<String, dynamic>;
        final status = data['status']?.toString() ?? '';
        if (blockingStatuses.contains(status)) {
          throw Exception('Khung gio nay da co nguoi dat. Vui long chon gio khac.');
        }
      }

      final walletData = walletSnapshot.data();
      final balance = walletData?['balance'] is int
          ? walletData!['balance'] as int
          : int.tryParse(walletData?['balance']?.toString() ?? '') ?? 0;

      if (booking.paymentAmount > 0 && balance < booking.paymentAmount) {
        throw Exception('So du vi khong du. Vui long nap them tien truoc khi dat lich.');
      }

      if (booking.paymentAmount > 0) {
        transaction.set(walletRef, {
          'balance': FieldValue.increment(-booking.paymentAmount),
          'held_balance': FieldValue.increment(booking.paymentAmount),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(walletTransactionRef, {
          'user_id': booking.userId,
          'user_name': booking.userName,
          'booking_id': bookingRef.id,
          'type': 'booking_hold',
          'amount': booking.paymentAmount,
          'status': 'confirmed',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(bookingRef, booking.toMap(slotLockIdOverride: slotLockId));
      transaction.set(slotRef, {
        'booking_id': bookingRef.id,
        'pt_id': booking.ptId,
        'booking_date': booking.bookingDate,
        'time_slot': booking.timeSlot,
        'status': booking.status,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }

  Future<void> updatePaymentStatus(String bookingId, String paymentStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'payment_status': paymentStatus,
      'payment_updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getBookedSlots(String ptId, DateTime date) async {
    final dateStr = formatDate(date);

    final lockedSlots = <String>{};
    final snapshot = await _firestore
        .collection('booking_slots')
        .where('pt_id', isEqualTo: ptId)
        .where('booking_date', isEqualTo: dateStr)
        .get();

    for (final doc in snapshot.docs) {
      final status = doc.data()['status']?.toString() ?? '';
      if (blockingStatuses.contains(status)) {
        lockedSlots.add(doc.data()['time_slot'].toString());
      }
    }

    final legacySnapshot = await _firestore
        .collection('bookings')
        .where('pt_id', isEqualTo: ptId)
        .where('booking_date', isEqualTo: dateStr)
        .get();

    for (final doc in legacySnapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? '';
      if (blockingStatuses.contains(status)) {
        lockedSlots.add(data['time_slot'].toString());
      }
    }

    return lockedSlots.toList()..sort();
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final walletTransactionRef = _firestore.collection('wallet_transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final bookingDoc = await transaction.get(bookingRef);

      if (!bookingDoc.exists || bookingDoc.data() == null) {
        return;
      }

      final data = bookingDoc.data()!;
      final paymentStatus = data['payment_status']?.toString() ?? '';
      final userId = data['user_id']?.toString() ?? '';
      final userName = data['user_name']?.toString() ?? '';
      final paymentAmount = data['payment_amount'] is int
          ? data['payment_amount'] as int
          : int.tryParse(data['payment_amount']?.toString() ?? '') ?? 0;
      final slotLockId =
          data['slot_lock_id']?.toString() ??
          buildSlotLockId(
            ptId: data['pt_id']?.toString() ?? '',
            bookingDate: data['booking_date']?.toString() ?? '',
            timeSlot: data['time_slot']?.toString() ?? '',
          );

      final updateData = <String, dynamic>{'status': newStatus};

      if (paymentStatus == 'held' && paymentAmount > 0 && userId.isNotEmpty) {
        final walletRef = _firestore.collection('wallets').doc(userId);

        if (newStatus == 'confirmed') {
          transaction.set(walletRef, {
            'held_balance': FieldValue.increment(-paymentAmount),
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          updateData['payment_status'] = 'paid';
          updateData['payment_updated_at'] = FieldValue.serverTimestamp();
          transaction.set(walletTransactionRef, {
            'user_id': userId,
            'user_name': userName,
            'booking_id': bookingId,
            'type': 'booking_capture',
            'amount': paymentAmount,
            'status': 'confirmed',
            'created_at': FieldValue.serverTimestamp(),
          });
        } else if (newStatus == 'canceled') {
          transaction.set(walletRef, {
            'balance': FieldValue.increment(paymentAmount),
            'held_balance': FieldValue.increment(-paymentAmount),
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          updateData['payment_status'] = 'refunded_to_wallet';
          updateData['payment_updated_at'] = FieldValue.serverTimestamp();
          transaction.set(walletTransactionRef, {
            'user_id': userId,
            'user_name': userName,
            'booking_id': bookingId,
            'type': 'booking_refund',
            'amount': paymentAmount,
            'status': 'confirmed',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(bookingRef, updateData);

      if (slotLockId.isNotEmpty) {
        transaction.set(_firestore.collection('booking_slots').doc(slotLockId), {
          'booking_id': bookingId,
          'pt_id': data['pt_id'],
          'booking_date': data['booking_date'],
          'time_slot': data['time_slot'],
          'status': newStatus,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }
}
