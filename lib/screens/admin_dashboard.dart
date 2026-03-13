import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Hàm duyệt PT
  Future<void> _approvePT(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'PT'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt thành PT!"), backgroundColor: Colors.green));
    }
  }

  // Hàm xóa User/PT
  Future<void> _deleteUser(BuildContext context, String uid) async {
    // Hiển thị hộp thoại xác nhận trước khi xóa
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa tài khoản này khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa tài khoản!"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý Hệ thống"),
          backgroundColor: const Color(0xFF2E3B55),
          bottom: const TabBar(
            indicatorColor: Colors.orangeAccent,
            tabs: [
              Tab(text: "Chờ duyệt"),
              Tab(text: "Danh sách PT"),
              Tab(text: "Khách hàng"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList('Pending_PT'), // Tab 1: Chờ duyệt
            _buildUserList('PT'),         // Tab 2: PT chính thức
            _buildUserList('User'),       // Tab 3: Khách hàng
          ],
        ),
      ),
    );
  }

  // Widget hiển thị danh sách theo Role
  Widget _buildUserList(String roleFilter) {
    return StreamBuilder<QuerySnapshot>(
      // Lắng nghe dữ liệu realtime từ Firestore
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: roleFilter).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        var users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            String uid = users[index].id;
            String name = userData['name'] ?? 'Không tên';
            String email = userData['email'] ?? '';
            String specialty = userData['specialty'] ?? ''; // Chuyên môn nếu có

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(roleFilter == 'Pending_PT' ? "Chuyên môn: $specialty\n$email" : email),
                isThreeLine: roleFilter == 'Pending_PT',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chỉ hiện nút Duyệt ở tab Pending_PT
                    if (roleFilter == 'Pending_PT')
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approvePT(context, uid),
                        tooltip: "Duyệt PT",
                      ),
                    // Nút Xóa (Ai cũng xóa được)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(context, uid),
                      tooltip: "Xóa tài khoản",
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