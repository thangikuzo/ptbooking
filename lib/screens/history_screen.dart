import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử đặt lịch"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Demo 5 item
        itemBuilder: (context, index) {
          // Demo trạng thái
          String status = index == 0 ? "Sắp tới" : (index == 1 ? "Đã hủy" : "Hoàn thành");
          Color statusColor = index == 0 ? Colors.orange : (index == 1 ? Colors.red : Colors.green);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calendar_month, color: Color(0xFF2E3B55)),
              ),
              title: const Text("PT: Nguyễn Văn A", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text("10:00 AM - 14/02/2026"),
                  const SizedBox(height: 4),
                  Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}