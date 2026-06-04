import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import '../models/challenge_model.dart';
import 'package:ptbooking/features/auth/services/auth_service.dart';
import 'package:ptbooking/core/widgets/comment_bottom_sheet.dart';
import 'leaderboard_screen.dart';
import 'package:ptbooking/core/constants/gamification_constants.dart';
import 'package:ptbooking/features/gamification/widgets/user_avatar_with_frame.dart';
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
  final List<String> likedBy;
  final int commentCount;
  
  // Chi tiết điểm tiêu chí
  final int scoreBienDo;
  final int scoreTuThe;
  final int scoreKiemSoat;
  final int scoreHoanThanh;

  SubmissionItem({
    required this.docId,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.score,
    required this.status,
    required this.timeString,
    required this.likedBy,
    required this.commentCount,
    required this.scoreBienDo,
    required this.scoreTuThe,
    required this.scoreKiemSoat,
    required this.scoreHoanThanh,
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

  Future<void> _fetchUserRole() async {
    try {
      String? role = await _authService.getUserRole();
      if (mounted) {
        setState(() {
          _currentUserRole = role;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _checkJoinedStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('challenge_participants')
        .doc('${currentUser.uid}_${widget.challenge.id}')
        .get();
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
      await userRef.update({
        'following': FieldValue.arrayRemove([widget.challenge.creatorId]),
      });
      await ptRef.update({'followerCount': FieldValue.increment(-1)});
      setState(() => _isFollowingPT = false);
    } else {
      await userRef.update({
        'following': FieldValue.arrayUnion([widget.challenge.creatorId]),
      });
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.challenge.creatorId)
          .collection('notifications')
          .add({
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
    await FirebaseFirestore.instance
        .collection('challenge_participants')
        .doc('${currentUser.uid}_${widget.challenge.id}')
        .set({'userId': currentUser.uid, 'challengeId': widget.challenge.id, 'joinedAt': FieldValue.serverTimestamp()});
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

        String timeStr = "Vừa tải lên";
        if (data['createdAt'] != null) {
          DateTime dt = (data['createdAt'] as Timestamp).toDate();
          timeStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        }

        if (currentUser != null && data['userId'] == currentUser.uid) {
          foundMySubmission = true;
        }

        loadedItems.add(
          SubmissionItem(
            docId: doc.id,
            userId: data['userId'] ?? '',
            userName: data['userName'] ?? 'Học viên ẩn danh',
            avatarUrl: data['avatarUrl'] ?? '',
            videoUrl: data['videoUrl'],
            score: data['score'] ?? 0,
            status: data['status'] ?? 'Đang chờ duyệt',
            timeString: timeStr,
            likedBy: List<String>.from(data['likedBy'] ?? []),
            commentCount: data['commentCount'] as int? ?? 0,
            scoreBienDo: data['scoreBienDo'] ?? 0,
            scoreTuThe: data['scoreTuThe'] ?? 0,
            scoreKiemSoat: data['scoreKiemSoat'] ?? 0,
            scoreHoanThanh: data['scoreHoanThanh'] ?? 0,
          ),
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn không thể tự thả tim cho bài nộp của chính mình!')));
      return;
    }

    bool isLiked = currentLikedBy.contains(currentUser.uid);
    DocumentReference docRef = FirebaseFirestore.instance.collection('submissions').doc(submissionId);

    if (isLiked) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([currentUser.uid]),
      });

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thử thách đã kết thúc, không thể tải video lên nữa!')));
      return;
    }
    if (_hasSubmitted || _isUploading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn đã nộp bài hoặc đang trong quá trình tải lên!')));
      return;
    }
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });
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
            'scoreBienDo': 0,
            'scoreTuThe': 0,
            'scoreKiemSoat': 0,
            'scoreHoanThanh': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'likedBy': [],
            'commentCount': 0,
          });

          await _loadSubmissionsFromFirebase();
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tải video lên thành công!'), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteSubmission(String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: const Text("Bạn có chắc chắn muốn xóa bài nộp này không?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("XÓA", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('submissions').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa video!'), backgroundColor: Colors.red));
          _loadSubmissionsFromFirebase();
        }
      } catch (e) {}
    }
  }

  void _showGradingDialog(BuildContext context, String docId, String userName,
      {int initialBienDo = 0, int initialTuThe = 0, int initialKiemSoat = 0, int initialHoanThanh = 0}) {
    int scoreBienDo = initialBienDo;
    int scoreTuThe = initialTuThe;
    int scoreKiemSoat = initialKiemSoat;
    int scoreHoanThanh = initialHoanThanh;

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
                      Text(
                        "$currentScore/10",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
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
              title: const Text(
                "Chấm điểm Video",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Đánh giá bài tập của $userName", style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 20),
                    buildCriteriaRow("Biên độ", scoreBienDo, (val) => setStateDialog(() => scoreBienDo = val)),
                    buildCriteriaRow("Tư thế", scoreTuThe, (val) => setStateDialog(() => scoreTuThe = val)),
                    buildCriteriaRow("Kiểm soát", scoreKiemSoat, (val) => setStateDialog(() => scoreKiemSoat = val)),
                    buildCriteriaRow(
                      "Mức độ hoàn thành",
                      scoreHoanThanh,
                      (val) => setStateDialog(() => scoreHoanThanh = val),
                    ),
                    const Divider(),
                    Center(
                      child: Text(
                        "Điểm trung bình: $totalScoreInt",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    if (scoreBienDo == 0 || scoreTuThe == 0 || scoreKiemSoat == 0 || scoreHoanThanh == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chấm điểm tất cả tiêu chí!'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lưu điểm thành công!'), backgroundColor: Colors.green),
                        );
                        _loadSubmissionsFromFirebase();
                      }
                    } catch (e) {}
                  },
                  child: const Text("LƯU ĐIỂM", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rateChallenge(int rating) async {
    setState(() => _userRating = rating);

    DocumentReference ref = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      int currentCount = (snapshot.data() as Map<String, dynamic>)['ratingCount'] as int? ?? 0;
      double currentRating = (snapshot.data() as Map<String, dynamic>)['rating'] as double? ?? 0.0;

      double newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
      transaction.update(ref, {'rating': newRating, 'ratingCount': currentCount + 1});
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole || _isLoadingFeed && _feedItems.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    String timeRemaining = "Không giới hạn";
    if (widget.challenge.endTime != null) {
      Duration diff = widget.challenge.endTime!.toDate().difference(DateTime.now());
      if (diff.isNegative) {
        timeRemaining = "Đã kết thúc";
      } else {
        timeRemaining = "Còn ${diff.inHours}h ${diff.inMinutes % 60}m";
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Chi Tiết Thử Thách",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D5D9B), Color(0xFF4BA3E3)],
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
            onPressed: () => _showRewardInfoDialog(),
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: 1 + (_isUploading ? 1 : 0) + _feedItems.length,
        itemBuilder: (context, index) {
          // --- 1. HERO HEADER WITH SAFE SPACING ---
          if (index == 0) {
            return FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Challenge Image with proper aspect ratio and curved corners
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Image.network(
                            widget.challenge.imageUrl.isNotEmpty
                                ? widget.challenge.imageUrl
                                : 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 180,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            ),
                          ),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 12,
                            right: 16,
                            child: Text(
                              widget.challenge.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.challenge.description,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                          ),
                          const SizedBox(height: 16),

                          // Badges Row
                          Row(
                            children: [
                              // Difficulty
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (widget.challenge.difficulty == 'Rất khó'
                                          ? Colors.red
                                          : (widget.challenge.difficulty == 'Khó' ? Colors.orange : Colors.green))
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 14,
                                      color: widget.challenge.difficulty == 'Rất khó'
                                          ? Colors.red
                                          : (widget.challenge.difficulty == 'Khó' ? Colors.orange : Colors.green),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.challenge.difficulty,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: widget.challenge.difficulty == 'Rất khó'
                                            ? Colors.red
                                            : (widget.challenge.difficulty == 'Khó' ? Colors.orange : Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Time remaining
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeRemaining,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Points EXP
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "+${widget.challenge.points} XP",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Action Rows
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LeaderboardScreen(challengeTitle: widget.challenge.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
                                  label: const Text(
                                    "BẢNG XẾP HẠNG",
                                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border, width: 1.5),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              if (_currentUserRole != 'PT' && widget.challenge.creatorId.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: Icon(_isFollowingPT ? Icons.check : Icons.person_add, color: AppColors.primary, size: 20),
                                  label: Text(_isFollowingPT ? "Đang theo dõi" : "Theo dõi PT", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  onPressed: _toggleFollowPT,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                              if (_currentUserRole != 'PT') ...[
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isJoined ? Colors.grey : AppColors.primary,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isJoined ? null : _joinChallenge,
                                  child: Text(
                                    _isJoined ? "ĐÃ THAM GIA" : "THAM GIA",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ]
                            ],
                          ),

                          // PT Admin actions
                          if (_currentUserRole == 'PT' &&
                              timeRemaining == "Đã kết thúc" &&
                              widget.challenge.creatorId == FirebaseAuth.instance.currentUser?.uid &&
                              !widget.challenge.isRewardsDistributed) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _distributeRewards,
                                icon: const Icon(Icons.card_giftcard),
                                label: const Text("TRAO THƯỞNG & KẾT THÚC THỬ THÁCH", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],

                          // Rating Section
                          if (_hasSubmitted && _userRating == 0) ...[
                            const Divider(height: 30),
                            const Center(child: Text("Đánh giá thử thách này", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (i) => IconButton(
                                  icon: const Icon(Icons.star_border, color: Colors.amber, size: 28),
                                  onPressed: () => _rateChallenge(i + 1),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- 2. UPLOADING SPINNER ---
          if (_isUploading && index == 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 12),
                    Text("Đang tải video bài nộp lên...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          // --- 3. SUBMISSIONS VIDEO CARD (LAZY LOADING STATEFUL WIDGET) ---
          final videoIndex = index - 1 - (_isUploading ? 1 : 0);
          if (videoIndex < 0 || videoIndex >= _feedItems.length) return const SizedBox.shrink();
          final item = _feedItems[videoIndex];

          bool isLikedByMe =
              FirebaseAuth.instance.currentUser != null &&
              item.likedBy.contains(FirebaseAuth.instance.currentUser!.uid);

          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: SubmissionVideoCard(
              item: item,
              currentUserRole: _currentUserRole,
              currentUserId: FirebaseAuth.instance.currentUser?.uid,
              isLikedByMe: isLikedByMe,
              isChallengeEnded: _isChallengeEnded(),
              onDelete: () => _deleteSubmission(item.docId),
              onToggleLike: () => _toggleLike(item.docId, item.userId, item.likedBy),
              onGrade: () => _showGradingDialog(
                context,
                item.docId,
                item.userName,
                initialBienDo: item.scoreBienDo,
                initialTuThe: item.scoreTuThe,
                initialKiemSoat: item.scoreKiemSoat,
                initialHoanThanh: item.scoreHoanThanh,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: (_currentUserRole != 'PT' && _isJoined)
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: _hasSubmitted
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text("BẠN ĐÃ NỘP BÀI", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: timeRemaining == "Đã kết thúc" ? null : _pickVideo,
                      icon: const Icon(Icons.video_call),
                      label: Text(
                        timeRemaining == "Đã kết thúc" ? "THỬ THÁCH ĐÃ ĐÓNG" : "TẢI VIDEO BÀI TẬP LÊN",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _showRewardInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Phần thưởng Thử thách",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
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
            child: const Text("Đóng", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String rank, String imagePath, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 35,
            height: 35,
            errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.amber, size: 35),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _distributeRewards() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('challengeId', isEqualTo: widget.challenge.id)
          .get();
      List<Map<String, dynamic>> allItems = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        List<dynamic> likedBy = data['likedBy'] ?? [];
        allItems.add({
          'userId': data['userId'],
          'score': data['score'] ?? 0,
          'likes': likedBy.length,
          'docRef': doc.reference,
        });
      }

      allItems.sort((a, b) {
        int scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
        if (scoreCompare != 0) return scoreCompare;
        return (b['likes'] as int).compareTo(a['likes'] as int);
      });

      WriteBatch batch = FirebaseFirestore.instance.batch();
      GamificationService gamificationService = GamificationService();

      int currentRank = 1;

      DateTime endTime = widget.challenge.endTime?.toDate() ?? DateTime.now();
      String timeString =
          "${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')}/${endTime.year}";

      for (int i = 0; i < allItems.length; i++) {
        if (i > 0) {
          if (allItems[i]['score'] < allItems[i - 1]['score'] || allItems[i]['likes'] < allItems[i - 1]['likes']) {
            currentRank++;
          }
        }

        if (currentRank > 3) break;

        String userId = allItems[i]['userId'];
        int expReward = 0;
        int bpExpReward = 0;
        String? badgeReward;

        if (currentRank == 1) {
          expReward = GamificationConstants.EXP_TOP_1_SCORE;
          badgeReward = GamificationConstants.LEADERBOARD_BADGES[1];
          bpExpReward = 20;
        } else if (currentRank == 2) {
          expReward = GamificationConstants.EXP_TOP_2_SCORE;
          badgeReward = GamificationConstants.LEADERBOARD_BADGES[2];
          bpExpReward = 10;
        } else if (currentRank == 3) {
          expReward = GamificationConstants.EXP_TOP_3_SCORE;
          badgeReward = GamificationConstants.LEADERBOARD_BADGES[3];
          bpExpReward = 5;
        }

        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

        batch.update(userRef, {
          'unlockedBadges': FieldValue.arrayUnion([
            {"image": badgeReward, "challengeName": "${widget.challenge.title} ($timeString)"},
          ]),
        });

        await gamificationService.addExp(userId, expReward);
        await gamificationService.addBpExp(userId, bpExpReward);
      }

      for (var item in allItems) {
        batch.delete(item['docRef']);
      }

      DocumentReference challengeRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
      batch.delete(challengeRef);

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã trao thưởng và xóa thử thách!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Lỗi trao thưởng: $e");
    }
  }
}

// --- SUBMISSIONS VIDEO CARD (LAZY LOADING STATEFUL WIDGET WITH RENDERED AVATAR FRAMES & DETAILED CRITERIA BARS) ---
class SubmissionVideoCard extends StatefulWidget {
  final SubmissionItem item;
  final String? currentUserRole;
  final String? currentUserId;
  final bool isLikedByMe;
  final bool isChallengeEnded;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;
  final VoidCallback onGrade;

  const SubmissionVideoCard({
    super.key,
    required this.item,
    required this.currentUserRole,
    required this.currentUserId,
    required this.isLikedByMe,
    required this.isChallengeEnded,
    required this.onDelete,
    required this.onToggleLike,
    required this.onGrade,
  });

  @override
  State<SubmissionVideoCard> createState() => _SubmissionVideoCardState();
}

class _SubmissionVideoCardState extends State<SubmissionVideoCard> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _selectedFrame;

  @override
  void initState() {
    super.initState();
    _fetchSubmitterFrame();
    _initVideoPlayer();
  }

  Future<void> _fetchSubmitterFrame() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(widget.item.userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _selectedFrame = doc.data()?['selectedFrame']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Lỗi đọc frame user: $e");
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo video: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User ListTile with equipped frame support
          ListTile(
            leading: UserAvatarWithFrame(
              avatarUrl: widget.item.avatarUrl,
              selectedFrame: _selectedFrame,
              size: 40,
            ),
            title: Text(widget.item.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(widget.item.timeString, style: const TextStyle(fontSize: 11)),
            trailing: widget.currentUserRole == 'PT'
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Xóa bài nộp", style: TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Video Container with Play/Pause button overlay
          GestureDetector(
            onTap: () {
              if (_isInitialized) {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                    _isPlaying = false;
                  } else {
                    _videoController!.play();
                    _isPlaying = true;
                  }
                });
              }
            },
            child: Container(
              color: Colors.black,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  
                  // Play/Pause Overlay Indicator
                  if (_isInitialized && !_isPlaying)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                ],
              ),
            ),
          ),

          // Video Progress Slider
          if (_isInitialized)
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),

          // Like / Comment Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onToggleLike,
                  child: Row(
                    children: [
                      Icon(widget.isLikedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 20),
                      const SizedBox(width: 6),
                      Text("${widget.item.likedBy.length}", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    if (widget.isChallengeEnded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thử thách đã kết thúc, không thể bình luận!')),
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentBottomSheet(submissionId: widget.item.docId, ownerId: widget.item.userId),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      const SizedBox(width: 6),
                      Text("${widget.item.commentCount}", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PT Evaluation details
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Chuyên môn: ",
                          style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                        Text(
                          widget.item.status == 'Đã chấm' ? '${widget.item.score} / 10 Điểm' : widget.item.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: widget.item.status == 'Đã chấm' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (widget.currentUserRole == 'PT')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.item.status == 'Đã chấm' ? Colors.blue.shade100 : Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(80, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: widget.onGrade,
                        child: Text(
                          widget.item.status == 'Đã chấm' ? "SỬA ĐIỂM" : "CHẤM ĐIỂM",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                
                // Detailed breakdown metrics (if graded)
                if (widget.item.status == 'Đã chấm') ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  _buildCriteriaBar("Biên độ động tác", widget.item.scoreBienDo),
                  const SizedBox(height: 6),
                  _buildCriteriaBar("Tư thế chuẩn xác", widget.item.scoreTuThe),
                  const SizedBox(height: 6),
                  _buildCriteriaBar("Kiểm soát thăng bằng", widget.item.scoreKiemSoat),
                  const SizedBox(height: 6),
                  _buildCriteriaBar("Mức độ hoàn thành", widget.item.scoreHoanThanh),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBar(String title, int val) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text("$val / 10", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val / 10.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
