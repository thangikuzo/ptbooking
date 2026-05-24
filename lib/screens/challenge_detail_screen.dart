import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/challenge_model.dart';
import '../services/auth_service.dart';
import '../widgets/comment_bottom_sheet.dart';
import 'leaderboard_screen.dart';
import '../constants/gamification_constants.dart';
import '../services/gamification_service.dart';

// Khuôn đúc Dữ liệu
class SubmissionItem {
  final String docId;
  final String userId;
  final String userName;
  final String avatarUrl;
  final String videoUrl;
  final int score;
  final String status;
  final String timeString;
  final VideoPlayerController controller;
  final List<String> likedBy;
  final int commentCount;

  SubmissionItem({
    required this.docId,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.score,
    required this.status,
    required this.timeString,
    required this.controller,
    required this.likedBy,
    required this.commentCount,
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
  bool _isFollowingPT = false;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _checkJoinedStatus();
    _checkFollowingStatus();
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
    var doc = await FirebaseFirestore.instance.collection('challenge_participants').doc('${currentUser.uid}_${widget.challenge.id}').get();
    if (doc.exists && mounted) setState(() => _isJoined = true);
  }

  Future<void> _checkFollowingStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (doc.exists) {
      List<String> following = List<String>.from((doc.data() as Map<String, dynamic>)['following'] ?? []);
      if (following.contains(widget.challenge.creatorId) && mounted) {
        setState(() => _isFollowingPT = true);
      }
    }
  }

  Future<void> _toggleFollowPT() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    DocumentReference ptRef = FirebaseFirestore.instance.collection('users').doc(widget.challenge.creatorId);

    if (_isFollowingPT) {
      await userRef.update({'following': FieldValue.arrayRemove([widget.challenge.creatorId])});
      await ptRef.update({'followerCount': FieldValue.increment(-1)});
      setState(() => _isFollowingPT = false);
    } else {
      await userRef.update({'following': FieldValue.arrayUnion([widget.challenge.creatorId])});
      await ptRef.update({'followerCount': FieldValue.increment(1)});
      setState(() => _isFollowingPT = true);

      // Tạo thông báo cho PT
      String realName = "Học viên";
      String avatar = "";
      var myDoc = await userRef.get();
      if (myDoc.exists) {
        realName = (myDoc.data() as Map<String, dynamic>)['name'] ?? "Học viên";
        avatar = (myDoc.data() as Map<String, dynamic>)['avatar'] ?? "";
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.challenge.creatorId).collection('notifications').add({
        'type': 'follow',
        'senderId': currentUser.uid,
        'senderName': realName,
        'senderAvatar': avatar,
        'targetId': '',
        'message': 'đã bắt đầu theo dõi bạn.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  bool _isChallengeEnded() {
    if (widget.challenge.endTime == null) return false;
    return widget.challenge.endTime!.toDate().isBefore(DateTime.now());
  }

  Future<void> _joinChallenge() async {
    if (_isChallengeEnded()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thử thách đã kết thúc!')));
      return;
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    setState(() => _isJoined = true);
    await FirebaseFirestore.instance.collection('challenge_participants').doc('${currentUser.uid}_${widget.challenge.id}').set({
      'userId': currentUser.uid, 'challengeId': widget.challenge.id, 'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadSubmissionsFromFirebase() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('challengeId', isEqualTo: widget.challenge.id)
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
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Học viên ẩn danh',
          avatarUrl: data['avatarUrl'] ?? '',
          videoUrl: data['videoUrl'],
          score: data['score'] ?? 0,
          status: data['status'] ?? 'Đang chờ duyệt',
          timeString: timeStr,
          controller: controller,
          likedBy: List<String>.from(data['likedBy'] ?? []),
          commentCount: data['commentCount'] as int? ?? 0,
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
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _toggleLike(String submissionId, String ownerId, List<dynamic> currentLikedBy) async {
    if (_isChallengeEnded()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thử thách đã kết thúc!')));
      return;
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    if (ownerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không thể tự thả tim cho bài nộp của chính mình!')));
      return;
    }

    bool isLiked = currentLikedBy.contains(currentUser.uid);
    DocumentReference docRef = FirebaseFirestore.instance.collection('submissions').doc(submissionId);

    if (isLiked) {
      await docRef.update({'likedBy': FieldValue.arrayRemove([currentUser.uid])});
    } else {
      await docRef.update({'likedBy': FieldValue.arrayUnion([currentUser.uid])});
      
      // Tạo thông báo cho chủ video
      String realName = "Học viên";
      String avatar = "";
      var myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (myDoc.exists) {
        realName = (myDoc.data() as Map<String, dynamic>)['name'] ?? "Học viên";
        avatar = (myDoc.data() as Map<String, dynamic>)['avatar'] ?? "";
      }

      await FirebaseFirestore.instance.collection('users').doc(ownerId).collection('notifications').add({
        'type': 'like',
        'senderId': currentUser.uid,
        'senderName': realName,
        'senderAvatar': avatar,
        'targetId': submissionId,
        'message': 'đã thích video bài tập của bạn.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    _loadSubmissionsFromFirebase();
  }

  Future<void> _pickVideo() async {
    if (_isChallengeEnded()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thử thách đã kết thúc, không thể tải video lên nữa!')));
      return;
    }
    if (_hasSubmitted || _isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã nộp bài hoặc đang trong quá trình tải lên!')));
      return;
    }
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
            'challengeId': widget.challenge.id,
            'userId': currentUser?.uid ?? 'unknown',
            'userName': realName,
            'avatarUrl': realAvatar,
            'videoUrl': videoUrl,
            'status': 'Đang chờ duyệt',
            'score': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'likedBy': [],
            'commentCount': 0,
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
      } catch (e) {}
    }
  }

  void _showGradingDialog(BuildContext context, String docId, String userName) {
    int scoreBienDo = 0;
    int scoreTuThe = 0;
    int scoreKiemSoat = 0;
    int scoreHoanThanh = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Widget buildCriteriaRow(String title, int currentScore, Function(int) onScoreChanged) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("$currentScore/10", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(10, (index) {
                      int boxScore = index + 1;
                      bool isSelected = boxScore <= currentScore;
                      return GestureDetector(
                        onTap: () => onScoreChanged(boxScore),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            int totalScoreInt = ((scoreBienDo + scoreTuThe + scoreKiemSoat + scoreHoanThanh) / 4).round();

            return AlertDialog(
              title: const Text("Chấm điểm Video", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Đánh giá bài tập của $userName", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    buildCriteriaRow("Biên độ", scoreBienDo, (val) => setStateDialog(() => scoreBienDo = val)),
                    buildCriteriaRow("Tư thế", scoreTuThe, (val) => setStateDialog(() => scoreTuThe = val)),
                    buildCriteriaRow("Kiểm soát", scoreKiemSoat, (val) => setStateDialog(() => scoreKiemSoat = val)),
                    buildCriteriaRow("Mức độ hoàn thành", scoreHoanThanh, (val) => setStateDialog(() => scoreHoanThanh = val)),
                    const Divider(),
                    Center(child: Text("Điểm trung bình: $totalScoreInt", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    if (scoreBienDo == 0 || scoreTuThe == 0 || scoreKiemSoat == 0 || scoreHoanThanh == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chấm điểm tất cả tiêu chí!'), backgroundColor: Colors.red));
                      return;
                    }
                    Navigator.pop(context);

                    try {
                      await FirebaseFirestore.instance.collection('submissions').doc(docId).update({
                        'score': totalScoreInt,
                        'scoreBienDo': scoreBienDo,
                        'scoreTuThe': scoreTuThe,
                        'scoreKiemSoat': scoreKiemSoat,
                        'scoreHoanThanh': scoreHoanThanh,
                        'status': 'Đã chấm',
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chấm điểm thành công!'), backgroundColor: Colors.green));
                        _loadSubmissionsFromFirebase();
                      }
                    } catch (e) {}
                  },
                  child: const Text("LƯU ĐIỂM", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _rateChallenge(int rating) async {
    setState(() => _userRating = rating);
    
    // Cập nhật Firebase rating (logic đơn giản)
    DocumentReference ref = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      int currentCount = (snapshot.data() as Map<String, dynamic>)['ratingCount'] as int? ?? 0;
      double currentRating = (snapshot.data() as Map<String, dynamic>)['rating'] as double? ?? 0.0;
      
      double newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
      transaction.update(ref, {
        'rating': newRating,
        'ratingCount': currentCount + 1,
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole || _isLoadingFeed && _feedItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    }

    String timeRemaining = "Không giới hạn";
    if (widget.challenge.endTime != null) {
      Duration diff = widget.challenge.endTime!.toDate().difference(DateTime.now());
      if (diff.isNegative) timeRemaining = "Đã kết thúc";
      else timeRemaining = "Còn ${diff.inHours}h ${diff.inMinutes % 60}m";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            tooltip: "Xem phần thưởng",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Phần thưởng Thử thách", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Khi sự kiện kết thúc, Top 3 sẽ nhận được:"),
                      const SizedBox(height: 16),
                      _buildRewardRow("Top 1", GamificationConstants.LEADERBOARD_BADGES[1]!, "Huy hiệu & 50 EXP"),
                      const SizedBox(height: 8),
                      _buildRewardRow("Top 2", GamificationConstants.LEADERBOARD_BADGES[2]!, "Huy hiệu & 30 EXP"),
                      const SizedBox(height: 8),
                      _buildRewardRow("Top 3", GamificationConstants.LEADERBOARD_BADGES[3]!, "Huy hiệu & 10 EXP"),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: 1 + (_isUploading ? 1 : 0) + _feedItems.length,
        itemBuilder: (context, index) {

          // HEADER
          if (index == 0) {
            return Container(
              width: double.infinity, padding: const EdgeInsets.all(16.0), color: Colors.amber.shade50,
              child: Column(
                children: [
                  Image.network(widget.challenge.imageUrl, height: 120, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 100)),
                  const SizedBox(height: 16),

                  Text(widget.challenge.description, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: Colors.red),
                      const SizedBox(width: 5),
                      Text(timeRemaining, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen(challengeTitle: widget.challenge.id)));
                      },
                      icon: const Icon(Icons.emoji_events, color: Colors.orange),
                      label: const Text("XEM BẢNG XẾP HẠNG", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange, width: 2), backgroundColor: Colors.white),
                    ),
                  ),
                  if (_currentUserRole == 'PT' && timeRemaining == "Đã kết thúc" && widget.challenge.creatorId == FirebaseAuth.instance.currentUser?.uid && !widget.challenge.isRewardsDistributed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _distributeRewards,
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text("TRAO THƯỞNG & KẾT THÚC", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade700, width: 1)),
                        child: Text('+${widget.challenge.points} EXP', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (_currentUserRole != 'PT' && widget.challenge.creatorId.isNotEmpty)
                        OutlinedButton.icon(
                          icon: Icon(_isFollowingPT ? Icons.check : Icons.person_add, color: _isFollowingPT ? Colors.green : Colors.blue),
                          label: Text(_isFollowingPT ? "Đang theo dõi PT" : "Theo dõi PT"),
                          onPressed: _toggleFollowPT,
                        ),
                      if (_currentUserRole != 'PT')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.grey : Colors.green),
                          onPressed: _isJoined ? null : _joinChallenge,
                          child: Text(_isJoined ? "ĐÃ THAM GIA" : "THAM GIA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),

                  // Rating Section cho User đã nộp bài
                  if (_hasSubmitted && _userRating == 0) ...[
                    const Divider(height: 30),
                    const Text("Đánh giá thử thách này", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => IconButton(
                        icon: const Icon(Icons.star_border, color: Colors.amber, size: 30),
                        onPressed: () => _rateChallenge(i + 1),
                      )),
                    )
                  ]
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

          bool isLikedByMe = FirebaseAuth.instance.currentUser != null && item.likedBy.contains(FirebaseAuth.instance.currentUser!.uid);

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
                  trailing: _currentUserRole == 'PT'
                      ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _deleteSubmission(item.docId);
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Xóa video này", style: TextStyle(color: Colors.red))])),
                    ],
                  ) : null,
                ),
                AspectRatio(aspectRatio: item.controller.value.aspectRatio, child: VideoPlayer(item.controller)),
                
                // Nút Like, Comment
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleLike(item.docId, item.userId, item.likedBy),
                        child: Row(children: [
                          Icon(isLikedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          const SizedBox(width: 5),
                          Text("${item.likedBy.length}"),
                        ]),
                      ),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          if (_isChallengeEnded()) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thử thách đã kết thúc, không thể bình luận!')));
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => CommentBottomSheet(submissionId: item.docId, ownerId: item.userId),
                          );
                        },
                        child: Row(children: [
                          const Icon(Icons.chat_bubble_outline),
                          const SizedBox(width: 5),
                          Text("${item.commentCount}"),
                        ]),
                      ),
                    ],
                  ),
                ),

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
          onPressed: timeRemaining == "Đã kết thúc" ? null : _pickVideo,
          icon: const Icon(Icons.video_call),
          label: Text(timeRemaining == "Đã kết thúc" ? "THỬ THÁCH ĐÃ ĐÓNG" : "TẢI VIDEO LÊN", style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildRewardRow(String rank, String imagePath, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, width: 40, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.amber, size: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(description, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _distributeRewards() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.green)));
    
    try {
      var snapshot = await FirebaseFirestore.instance.collection('submissions').where('challengeId', isEqualTo: widget.challenge.id).get();
      List<Map<String, dynamic>> allItems = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        List<dynamic> likedBy = data['likedBy'] ?? [];
        allItems.add({
          'userId': data['userId'], 
          'score': data['score'] ?? 0,
          'likes': likedBy.length,
          'docRef': doc.reference
        });
      }
      
      // Sắp xếp theo điểm, rồi đến likes
      allItems.sort((a, b) {
        int scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
        if (scoreCompare != 0) return scoreCompare;
        return (b['likes'] as int).compareTo(a['likes'] as int);
      });

      WriteBatch batch = FirebaseFirestore.instance.batch();
      GamificationService gamificationService = GamificationService();
      
      int currentRank = 1;
      
      DateTime endTime = widget.challenge.endTime?.toDate() ?? DateTime.now();
      String timeString = "${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')}/${endTime.year}";

      for (int i = 0; i < allItems.length; i++) {
        if (i > 0) {
          if (allItems[i]['score'] < allItems[i - 1]['score'] || allItems[i]['likes'] < allItems[i - 1]['likes']) {
            currentRank++;
          }
        }
        
        if (currentRank > 3) break; // Chỉ thưởng Top 3
        
        String userId = allItems[i]['userId'];
        int expReward = 0;
        int bpExpReward = 0;
        String? badgeReward;
        
        if (currentRank == 1) { expReward = GamificationConstants.EXP_TOP_1_SCORE; badgeReward = GamificationConstants.LEADERBOARD_BADGES[1]; bpExpReward = 20; }
        else if (currentRank == 2) { expReward = GamificationConstants.EXP_TOP_2_SCORE; badgeReward = GamificationConstants.LEADERBOARD_BADGES[2]; bpExpReward = 10; }
        else if (currentRank == 3) { expReward = GamificationConstants.EXP_TOP_3_SCORE; badgeReward = GamificationConstants.LEADERBOARD_BADGES[3]; bpExpReward = 5; }

        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        
        batch.update(userRef, {
          'unlockedBadges': FieldValue.arrayUnion([
            {"image": badgeReward, "challengeName": "${widget.challenge.title} ($timeString)"}
          ])
        });

        // Kích hoạt logic lên cấp bằng GamificationService
        await gamificationService.addExp(userId, expReward);
        await gamificationService.addBpExp(userId, bpExpReward);
      }

      // Xóa tất cả submissions
      for (var item in allItems) {
        batch.delete(item['docRef']);
      }

      // Xóa thử thách
      DocumentReference challengeRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
      batch.delete(challengeRef);
      
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã trao thưởng và xóa thử thách!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Thoát về màn hình trước
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Lỗi trao thưởng: $e");
    }
  }
}