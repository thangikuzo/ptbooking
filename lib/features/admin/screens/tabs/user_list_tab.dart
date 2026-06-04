import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListTab extends StatelessWidget {
  const UserListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', whereIn: ['User', 'user']).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Không có học viên nào."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0B2447),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(data['name'] ?? 'Học viên ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(id).delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
