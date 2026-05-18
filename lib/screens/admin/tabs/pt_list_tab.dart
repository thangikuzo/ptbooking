import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PTListTab extends StatelessWidget {
  const PTListTab({super.key});

  void _setSchedule(BuildContext context, String id, Map data) {
    Map<String, bool> schedule = Map<String, bool>.from(data['schedule'] ?? {});
    const days = {"T2": "Thứ 2", "T3": "Thứ 3", "T4": "Thứ 4", "T5": "Thứ 5", "T6": "Thứ 6", "T7": "Thứ 7", "CN": "Chủ nhật"};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text("Đặt lịch cố định tuần"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: days.keys.map((key) {
              return CheckboxListTile(
                title: Text(days[key]!),
                value: schedule[key] ?? false,
                onChanged: (v) => setState(() => schedule[key] = v ?? false),
              );
            }).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(id).update({'schedule': schedule});
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Lưu"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'PT').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Chưa có HLV nào."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (data['avatar'] != null && data['avatar'].toString().isNotEmpty) ? NetworkImage(data['avatar']) : null,
                  child: data['avatar'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(data['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Chuyên môn: ${data['specialty'] ?? 'Gym'}\nKinh nghiệm: ${data['experience'] ?? '0'} năm"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.calendar_month, color: Colors.blue), onPressed: () => _setSchedule(context, id, data)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(id).delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}