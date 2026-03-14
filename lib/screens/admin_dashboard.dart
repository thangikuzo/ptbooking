import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

///////////////////////////////////////////////////////////////
/// CLOUDINARY FREE UPLOAD
///////////////////////////////////////////////////////////////
class CloudinaryService {
  static const cloudName = "duhxd8nte";
  static const uploadPreset = "pt_booking";

  static Future<String?> uploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final file =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (file == null) return null;

    final uri =
    Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return data['secure_url'];
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Upload thất bại")));
    return null;
  }
}

///////////////////////////////////////////////////////////////
/// ADMIN DASHBOARD
///////////////////////////////////////////////////////////////
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ADMIN DASHBOARD"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "PT"),
              Tab(text: "User"),
              Tab(text: "Booking"),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreatePTDialog(context),
          child: const Icon(Icons.add),
        ),

        body: const TabBarView(
          children: [
            _PTList(),
            _UserList(),
            _BookingList(),
          ],
        ),
      ),
    );
  }

  /////////////////////////////////////////////////////////////
  /// CREATE PT
  /////////////////////////////////////////////////////////////
  static void _showCreatePTDialog(BuildContext context) {
    final name = TextEditingController();
    final spec = TextEditingController();
    final price = TextEditingController();
    final exp = TextEditingController();

    String avatar = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Thêm PT",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              /// IMAGE
              GestureDetector(
                onTap: () async {
                  final url =
                  await CloudinaryService.uploadImage(context);
                  if (url != null) setState(() => avatar = url);
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: avatar.isNotEmpty
                      ? Image.network(avatar, fit: BoxFit.cover)
                      : const Center(child: Text("Chọn ảnh")),
                ),
              ),

              TextField(controller: name, decoration: const InputDecoration(labelText: "Tên")),
              TextField(controller: spec, decoration: const InputDecoration(labelText: "Chuyên môn")),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá")),
              TextField(controller: exp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Kinh nghiệm")),

              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').add({
                    'name': name.text.trim(),
                    'specialty': spec.text.trim(),
                    'price': int.tryParse(price.text) ?? 0,
                    'experience': int.tryParse(exp.text) ?? 0,
                    'avatar': avatar,
                    'role': 'PT',

                    /// LỊCH MẶC ĐỊNH
                    'schedule': {
                      'T2': false,
                      'T3': false,
                      'T4': false,
                      'T5': false,
                      'T6': false,
                      'T7': false,
                      'CN': false,
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text("Tạo PT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////
/// PT LIST — CRUD + SET LỊCH
///////////////////////////////////////////////////////////////
class _PTList extends StatelessWidget {
  const _PTList();

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }

  void _setSchedule(BuildContext context, String id, Map data) {
    Map<String, bool> schedule =
    Map<String, bool>.from(data['schedule'] ?? {});

    const days = {
      "T2": "Thứ 2",
      "T3": "Thứ 3",
      "T4": "Thứ 4",
      "T5": "Thứ 5",
      "T6": "Thứ 6",
      "T7": "Thứ 7",
      "CN": "Chủ nhật",
    };

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text("Chọn ngày PT rảnh"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: days.keys.map((key) {
              return CheckboxListTile(
                title: Text(days[key]!),
                value: schedule[key] ?? false,
                onChanged: (v) =>
                    setState(() => schedule[key] = v ?? false),
              );
            }).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(id)
                    .update({'schedule': schedule});
                Navigator.pop(context);
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
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'PT')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            final avatar = (data['avatar'] ?? '').toString();
            final name = (data['name'] ?? 'No name').toString();
            final spec = (data['specialty'] ?? '').toString();

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(name),
                subtitle: Text(spec),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month,
                          color: Colors.blue),
                      onPressed: () =>
                          _setSchedule(context, id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () => _delete(id),
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

///////////////////////////////////////////////////////////////
/// USER LIST
///////////////////////////////////////////////////////////////
class _UserList extends StatelessWidget {
  const _UserList();

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            return Card(
              child: ListTile(
                title: Text((data['name'] ?? '').toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////
/// BOOKING LIST
///////////////////////////////////////////////////////////////
class _BookingList extends StatelessWidget {
  const _BookingList();

  Future<void> _update(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'pending_approval')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            return Card(
              child: ListTile(
                title: Text("User: ${(data['userId'] ?? '').toString()}"),
                subtitle: Text("PT: ${(data['ptId'] ?? '').toString()}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.green),
                        onPressed: () => _update(id, 'approved')),
                    IconButton(
                        icon:
                        const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _update(id, 'rejected')),
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