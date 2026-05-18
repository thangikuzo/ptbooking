import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/challenge_model.dart';
import '../services/auth_service.dart';
import 'leaderboard_screen.dart';

// Khuôn đúc Dữ liệu
class SubmissionItem {
  final String docId;
  final String userName;
  final String avatarUrl;
  final String videoUrl;
  final int score;
  final String status;
  final String timeString;
  final VideoPlayerController controller;

  SubmissionItem({
    required this.docId,
    required this.userName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.score,
    required this.status,
    required this.timeString,
    required this.controller,
  });
}

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isJoined = false;
  List<SubmissionItem> _feedItems = [];
  bool _isLoadingFeed = true;
  bool _isUploading = false;
  String? _currentUserRole;
  bool _isLoadingRole = true;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _checkJoinedStatus();
    _loadSubmissionsFromFirebase();
  }

  @override
  void dispose() {
    for (var item in _feedItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      String? role = await _authService.getUserRole();
      if (mounted) setState(() { _currentUserRole = role; _isLoadingRole = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _checkJoinedStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance.collection('challenge_participants').doc('${currentUser.uid}_${widget.challenge.title}').get();
    if (doc.exists && mounted) setState(() => _isJoined = true);
  }

  Future<void> _joinChallenge() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    setState(() => _isJoined = true);
    await FirebaseFirestore.instance.collection('challenge_participants').doc('${currentUser.uid}_${widget.challenge.title}').set({
      'userId': currentUser.uid, 'challengeId': widget.challenge.title, 'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadSubmissionsFromFirebase() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('challengeId', isEqualTo: widget.challenge.title)
          .get();

      List<SubmissionItem> loadedItems = [];
      User? currentUser = FirebaseAuth.instance.currentUser;
      bool foundMySubmission = false;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        var controller = VideoPlayerController.networkUrl(Uri.parse(data['videoUrl']));
        await controller.initialize();

        String timeStr = "Vừa tải lên";
        if (data['createdAt'] != null) {
          DateTime dt = (data['createdAt'] as Timestamp).toDate();
          timeStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        }

        if (currentUser != null && data['userId'] == currentUser.uid) {
          foundMySubmission = true;
        }

        loadedItems.add(SubmissionItem(
          docId: doc.id,
          userName: data['userName'] ?? 'Học viên ẩn danh',
          avatarUrl: data['avatarUrl'] ?? '',
          videoUrl: data['videoUrl'],
          score: data['score'] ?? 0,
          status: data['status'] ?? 'Đang chờ duyệt',
          timeString: timeStr,
          controller: controller,
        ));
      }

      if (mounted) {
        setState(() {
          _feedItems = loadedItems;
          _isLoadingFeed = false;
          _hasSubmitted = foundMySubmission;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải Feed: $e");
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _isUploading = true; });
      try {
        var uri = Uri.parse('https://api.cloudinary.com/v1_1/dkjq5ojmn/video/upload');
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = 'challenge_video_upload';
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseData);
          String videoUrl = jsonResponse['secure_url'];

          User? currentUser = FirebaseAuth.instance.currentUser;
          String realName = 'Học viên';
          String realAvatar = '';
          if (currentUser != null) {
            var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
            if (userDoc.exists) {
              realName = userDoc.data()?['name'] ?? 'Học viên';
              realAvatar = userDoc.data()?['avatar'] ?? '';
            }
          }

          await FirebaseFirestore.instance.collection('submissions').add({
            'challengeId': widget.challenge.title,
            'userId': currentUser?.uid ?? 'unknown',
            'userName': realName,
            'avatarUrl': realAvatar,
            'videoUrl': videoUrl,
            'status': 'Đang chờ duyệt',
            'score': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await _loadSubmissionsFromFirebase();
          if (mounted) {
            setState(() { _isUploading = false; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tải video lên thành công!'), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) setState(() { _isUploading = false; });
        }
      } catch (e) {
        debugPrint("Lỗi up video: $e");
        if (mounted) setState(() { _isUploading = false; });
      }
    }
  }

  // --- HÀM XÓA VIDEO DÀNH CHO PT ---
  Future<void> _deleteSubmission(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa bài nộp này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("XÓA", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('submissions').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa video!'), backgroundColor: Colors.red));
          _loadSubmissionsFromFirebase();
        }
      } catch (e) {
        debugPrint("Lỗi xóa video: $e");
      }
    }
  }

  void _showGradingDialog(BuildContext context, String docId, String userName) {
    TextEditingController scoreController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Chấm điểm Video"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Đánh giá bài tập của $userName"),
                const SizedBox(height: 16),
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Nhập số điểm", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixText: "PT"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  int score = int.tryParse(scoreController.text.trim()) ?? 0;
                  Navigator.pop(context);

                  try {
                    await FirebaseFirestore.instance.collection('submissions').doc(docId).update({
                      'score': score,
                      'status': 'Đã chấm',
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chấm điểm thành công!'), backgroundColor: Colors.green));
                      _loadSubmissionsFromFirebase();
                    }
                  } catch (e) {
                    debugPrint("Lỗi chấm điểm: $e");
                  }
                },
                child: const Text("LƯU ĐIỂM", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole || _isLoadingFeed && _feedItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.challenge.title, style: const TextStyle(color: Colors.black)), backgroundColor: Colors.amber.shade200, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),

      // TỐI ƯU HÓA: MỘT LISTVIEW.BUILDER DUY NHẤT BAO TRỌN GÓI
      body: ListView.builder(
        itemCount: 1 + (_isUploading ? 1 : 0) + _feedItems.length,
        itemBuilder: (context, index) {

          // HEADER: CỤC VÀNG
          if (index == 0) {
            return Container(
              width: double.infinity, padding: const EdgeInsets.all(16.0), color: Colors.amber.shade200,
              child: Column(
                children: [
                  Image.network(widget.challenge.imageUrl, height: 120, fit: BoxFit.contain),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen(challengeTitle: widget.challenge.title)));
                      },
                      icon: const Icon(Icons.emoji_events, color: Colors.orange),
                      label: const Text("XEM BẢNG XẾP HẠNG", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange, width: 2), backgroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade700, width: 1)),
                        child: Text('${widget.challenge.points} PT', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (_currentUserRole == 'PT')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), onPressed: () {},
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18), label: const Text("QUẢN LÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.grey : Colors.green),
                          onPressed: _isJoined ? null : _joinChallenge,
                          child: Text(_isJoined ? "ĐÃ THAM GIA" : "THAM GIA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                    ],
                  )
                ],
              ),
            );
          }

          // VÒNG XOAY UPLOAD
          if (_isUploading && index == 1) {
            return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
          }

          // DANH SÁCH BÀI NỘP
          final videoIndex = index - 1 - (_isUploading ? 1 : 0);
          if (videoIndex < 0 || videoIndex >= _feedItems.length) return const SizedBox.shrink();
          final item = _feedItems[videoIndex];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: item.avatarUrl.isNotEmpty ? NetworkImage(item.avatarUrl) : null,
                    child: item.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
                  ),
                  title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.timeString),
                  // THÊM NÚT MENU XÓA DÀNH CHO PT
                  trailing: _currentUserRole == 'PT'
                      ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _deleteSubmission(item.docId);
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Xóa video này", style: TextStyle(color: Colors.red))])),
                    ],
                  )
                      : null,
                ),
                AspectRatio(aspectRatio: item.controller.value.aspectRatio, child: VideoPlayer(item.controller)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: Colors.grey.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_border_purple500, color: Colors.purple), const SizedBox(width: 8),
                          Text("PT đánh giá: ", style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                          Text(
                            item.status == 'Đã chấm' ? '${item.score} Điểm' : item.status,
                            style: TextStyle(fontWeight: FontWeight.bold, color: item.status == 'Đã chấm' ? Colors.green : Colors.orange),
                          ),
                        ],
                      ),
                      if (_currentUserRole == 'PT' && item.status != 'Đã chấm')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(80, 36)),
                          onPressed: () => _showGradingDialog(context, item.docId, item.userName),
                          child: const Text("CHẤM ĐIỂM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: (_currentUserRole != 'PT' && _isJoined)
          ? Container(
        padding: const EdgeInsets.all(16), color: Colors.grey.shade200,
        child: _hasSubmitted
            ? ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle),
          label: const Text("BẠN ĐÃ NỘP BÀI", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
        )
            : ElevatedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.video_call),
          label: const Text("TẢI VIDEO LÊN", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}