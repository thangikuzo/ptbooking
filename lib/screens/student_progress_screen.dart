import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_progress_detail_screen.dart';

class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Đánh giá tiến độ học viên"), backgroundColor: const Color(0xFF0B2447)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pt_id', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'confirmed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có học viên nào để đánh giá."));
          }

          final Map<String, Map<String, dynamic>> students = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['user_id']?.toString() ?? '';

            if (userId.isEmpty) continue;

            students[userId] = {
              'user_id': userId,
              'user_name': data['user_name'] ?? 'Học viên',
              'total_sessions': (students[userId]?['total_sessions'] ?? 0) + 1,
            };
          }

          final studentList = students.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: studentList.length,
            itemBuilder: (context, index) {
              final student = studentList[index];

              return _buildStudentCard(
                context: context,
                ptId: currentUser.uid,
                studentId: student['user_id'],
                name: student['user_name'],
                totalSessions: student['total_sessions'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentCard({
    required BuildContext context,
    required String ptId,
    required String studentId,
    required String name,
    required int totalSessions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.15),
            child: const Icon(Icons.person, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$totalSessions buổi đã đăng ký", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentProgressDetailScreen(studentId: studentId, studentName: name, ptId: ptId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4BA3E3)),
            child: const Text("Đánh giá", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
