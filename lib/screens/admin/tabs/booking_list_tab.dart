import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListTab extends StatelessWidget {
  const BookingListTab({super.key});

  Widget _buildStatus(String status) {
    Color color = Colors.grey;
    String text = status;
    if (status == 'pending') { color = Colors.orange; text = "Chờ duyệt"; }
    else if (status == 'confirmed') { color = Colors.green; text = "Đã chốt"; }
    else if (status == 'canceled') { color = Colors.red; text = "Đã hủy"; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Chưa có lịch đặt nào."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text("HV: ${data['user_name'] ?? 'Học viên'} ➔ PT: ${data['pt_name'] ?? 'HLV'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Ngày tập: ${data['booking_date']} | Khung giờ: ${data['time_slot']}"),
                trailing: _buildStatus(data['status'] ?? 'pending'),
              ),
            );
          },
        );
      },
    );
  }
}