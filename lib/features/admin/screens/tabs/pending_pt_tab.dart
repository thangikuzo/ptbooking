import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingPTTab extends StatelessWidget {
  const PendingPTTab({super.key});

  Future<void> _approvePT(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'PT'});
    await FirebaseFirestore.instance.collection('schedules').doc(uid).set({
      'pt_id': uid,
      'is_active': true,
      'availability': {
        'monday': [], 'tuesday': [], 'wednesday': [],
        'thursday': [], 'friday': [], 'saturday': [], 'sunday': [],
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã duyệt thành PT chính thức!"), backgroundColor: Colors.green));
    }
  }

  Future<void> _rejectPT(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'User'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã từ chối hồ sơ."), backgroundColor: Colors.red));
    }
  }

  void _showImageDialog(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: url.isNotEmpty ? InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)) : const Text("Không có hình ảnh"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Pending_PT').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Không có hồ sơ nào đang chờ duyệt."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final uid = docs[i].id;
            String certUrl = data['certificate_url']?.toString() ?? '';
            String cvUrl = data['cv_url']?.toString() ?? '';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name']?.toString() ?? 'Ẩn danh', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Chuyên môn: ${data['specialty'] ?? 'Chưa cập nhật'}"),
                    Text("Kinh nghiệm: ${data['experience'] ?? '0'} năm"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (certUrl.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.verified, size: 16),
                              label: const Text("Xem Chứng Chỉ", style: TextStyle(fontSize: 12)),
                              onPressed: () => _showImageDialog(context, certUrl, "Chứng chỉ hành nghề"),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (cvUrl.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.description, size: 16),
                              label: const Text("Xem Ảnh CV", style: TextStyle(fontSize: 12)),
                              onPressed: () => _showImageDialog(context, cvUrl, "Ảnh CV ứng viên"),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          label: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                          onPressed: () => _rejectPT(context, uid),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text("Phê duyệt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => _approvePT(context, uid),
                        ),
                      ],
                    )
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
