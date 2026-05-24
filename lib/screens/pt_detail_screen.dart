import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import '../models/review_model.dart'; // 🔥 KÉO FILE MODEL MỚI VÀO
import '../services/booking_service.dart';
import '../services/wallet_service.dart';



class PTDetailScreen extends StatefulWidget {
  final String ptUid;
  final Map<String, dynamic> ptData;

  const PTDetailScreen({super.key, required this.ptUid, required this.ptData});

  @override
  State<PTDetailScreen> createState() => _PTDetailScreenState();
}

class _PTDetailScreenState extends State<PTDetailScreen> {
  final BookingService _bookingService = BookingService();
  final WalletService _walletService = WalletService();
  bool _isBooking = false;
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _walletService.ensureWallet(user.uid);
    }
  }

  DateTime? _selectedDate;
  String? _selectedDay;
  String? _selectedTimeSlot;
  String? _selectedPackage;
  List<String> _availableTimeSlots = [];

  final Map<String, String> _dayLabels = {
    'monday': 'Thứ 2',
    'tuesday': 'Thứ 3',
    'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5',
    'friday': 'Thứ 6',
    'saturday': 'Thứ 7',
    'sunday': 'Chủ Nhật',
  };

  final List<Map<String, dynamic>> _gymPackages = [
    {'name': 'Trải nghiệm 1 buổi', 'desc': 'Đánh giá thể trạng & tư vấn', 'sessions': 1, 'price': 300000},
    {'name': 'Gói 12 buổi', 'desc': 'Phù hợp mục tiêu ngắn hạn', 'sessions': 12, 'price': 3000000},
    {'name': 'Gói 24 buổi', 'desc': 'Cam kết thay đổi vóc dáng', 'sessions': 24, 'price': 5600000},
    {'name': 'Gói 36 buổi', 'desc': 'Tối ưu hình thể trọn vẹn', 'sessions': 36, 'price': 7900000},
  ];

  final Color primaryColor = const Color(0xFF18253E);
  final Color accentColor = const Color(0xFFFFA515);
  final Color bgColor = const Color(0xFFF8F9FA);

  Map<String, dynamic>? get _selectedPackageData {
    if (_selectedPackage == null) return null;
    return _gymPackages.firstWhere((package) => package['name'] == _selectedPackage, orElse: () => <String, dynamic>{});
  }

  String _formatDate(DateTime date) {
    return _bookingService.formatDate(date);
  }

  String _formatCurrency(int amount) {
    if (amount <= 0) return 'Liên hệ admin';
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  Future<void> _loadAvailableSlots(String dayName, DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });

    try {
      final slots = await _bookingService.getAvailableSlots(ptId: widget.ptUid, day: dayName, date: date);

      if (mounted) {
        setState(() {
          _availableTimeSlots = slots;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải giờ trống: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'CHỌN NGÀY BẮT ĐẦU TẬP',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, onSurface: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      List<String> weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      String dayName = weekdays[picked.weekday - 1];

      setState(() {
        _selectedDate = picked;
        _selectedDay = dayName;
        _selectedTimeSlot = null;
      });
      await _loadAvailableSlots(dayName, picked);
    }
  }

  void _viewCertificate(String? url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Chứng chỉ chuyên môn",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: url != null && url.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(child: Text("Lỗi tải hình ảnh chứng chỉ")),
                ),
              )
            : const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    "PT này chưa cập nhật hình ảnh chứng chỉ lên hệ thống.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "ĐÓNG",
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 HÀM BẬT POP-UP ĐỂ NHẬP ĐÁNH GIÁ MỚI
  void _showWriteReviewDialog() {
    int currentRating = 5;
    TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Đánh giá PT",
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chọn sao
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            currentRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Nhập text
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Chia sẻ trải nghiệm của bạn...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (reviewController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vui lòng nhập nội dung!"), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          setStateDialog(() => isSubmitting = true);
                          await _submitReviewToFirebase(currentRating.toDouble(), reviewController.text.trim());
                          if (context.mounted) Navigator.pop(context); // Đóng pop-up
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "GỬI",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔥 HÀM PUSH DATA ĐÁNH GIÁ LÊN FIREBASE
  Future<void> _submitReviewToFirebase(double rating, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để đánh giá"), backgroundColor: Colors.red));
      return;
    }

    try {
      // Lấy tên thật của User đang đăng nhập
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userName = userDoc.data()?['name'] ?? "Học viên";
      String userAvatar = userDoc.data()?['avatar'] ?? "";

      ReviewModel newReview = ReviewModel(
        id: '',
        ptId: widget.ptUid,
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        rating: rating,
        content: content,
      );

      await FirebaseFirestore.instance.collection('reviews').add(newReview.toMap());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cảm ơn bạn đã đánh giá!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _showBookingConfirmation() async {
    final package = _selectedPackageData;
    final sessionCount = (package?['sessions'] as int?) ?? 1;
    final paymentAmount = (package?['price'] as int?) ?? 0;

    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Xác nhận đặt lịch",
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PT: ${widget.ptData['name'] ?? "PT"}"),
                  const SizedBox(height: 8),
                  Text("Ngày: ${_formatDate(_selectedDate!)} (${_dayLabels[_selectedDay]})"),
                  const SizedBox(height: 8),
                  Text("Giờ tập: $_selectedTimeSlot"),
                  const SizedBox(height: 8),
                  Text("Gói: $_selectedPackage ($sessionCount buổi)"),
                  const SizedBox(height: 8),
                  Text("Sẽ giữ trong ví: ${_formatCurrency(paymentAmount)}"),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _bookPT() async {
    if (_selectedDate == null || _selectedDay == null || _selectedTimeSlot == null || _selectedPackage == null) {
      return;
    }

    final confirmed = await _showBookingConfirmation();
    if (!confirmed) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập lại!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isBooking = true);

    try {
      String realUserName = "Học viên";
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        realUserName = userDoc.data()!['name'] ?? "Học viên";
      }

      String dateStr = _formatDate(_selectedDate!);
      final package = _selectedPackageData;

      BookingModel newBooking = BookingModel(
        id: '',
        userId: user.uid,
        userName: realUserName,
        ptId: widget.ptUid,
        ptName: widget.ptData['name'] ?? "PT",
        bookingDate: dateStr,
        day: _selectedDay!,
        timeSlot: _selectedTimeSlot!,
        packageName: _selectedPackage!,
        sessionCount: (package?['sessions'] as int?) ?? 1,
        paymentAmount: (package?['price'] as int?) ?? 0,
        status: 'pending',
        paymentStatus: 'held',
      );

      await _bookingService.createBooking(newBooking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã đặt lịch và giữ tiền trong ví. Vui lòng chờ PT duyệt."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isBooking = false);
  }

  bool get _canSubmitBooking =>
      _selectedDate != null && _selectedTimeSlot != null && _selectedPackage != null && !_isBooking;

  String get _bookingButtonText {
    if (_selectedDate == null) return "CHỌN NGÀY TẬP";
    if (_isLoadingSlots) return "ĐANG TẢI GIỜ TRỐNG";
    if (_selectedTimeSlot == null) return "CHỌN GIỜ TẬP";
    if (_selectedPackage == null) return "CHỌN GÓI TẬP";
    return "XÁC NHẬN ĐẶT LỊCH";
  }

  Widget _buildTimeSlotPicker() {
    if (_selectedDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: accentColor),
            const SizedBox(width: 12),
            const Expanded(child: Text("Chọn ngày trước để xem các khung giờ còn trống.")),
          ],
        ),
      );
    }

    if (_isLoadingSlots) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
            const SizedBox(width: 12),
            Text("Đang tải giờ trống...", style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (_availableTimeSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: accentColor),
            const SizedBox(width: 12),
            const Expanded(child: Text("PT chưa mở giờ trống hoặc các khung giờ ngày này đã được đặt.")),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Chọn giờ tập",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableTimeSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;

            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: accentColor.withOpacity(0.18),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? accentColor : Colors.grey.shade300),
              onSelected: (_) {
                setState(() => _selectedTimeSlot = slot);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.ptData['name'] ?? 'Không tên';
    String specialty = widget.ptData['specialty'] ?? 'Chưa cập nhật';
    String bio = widget.ptData['bio'] ?? 'Chưa có thông tin giới thiệu.';
    String experience = widget.ptData['experience'] ?? '0';
    String avatar = widget.ptData['avatar'] ?? '';
    String? certUrl = widget.ptData['certificate_url'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Trainer Profile",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _walletService.watchWallet(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};
                final raw = data['balance'] ?? 0;
                final balance = raw is int
                    ? raw
                    : raw is double
                        ? raw.toInt()
                        : int.tryParse(raw.toString()) ?? 0;
                final formatted = '${balance.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
                return Text('Số dư: $formatted', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
              },
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
      extendBodyBehindAppBar: true,

      // 🔥 BỌC TẤT CẢ VÀO STREAMBUILDER ĐỂ LẮNG NGHE REVIEW TỪ FIREBASE
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').where('pt_id', isEqualTo: widget.ptUid).snapshots(),
        builder: (context, snapshot) {
          // 1. Chuyển đổi Data thành List<ReviewModel>
          List<ReviewModel> reviews = [];
          if (snapshot.hasData) {
            reviews = snapshot.data!.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
            // Lọc bằng Dart để tránh lỗi "Requires Index" của Firebase
            reviews.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          }

          // 2. Tự động tính Trung bình Sao
          double avgRating = 0.0;
          if (reviews.isNotEmpty) {
            double totalStars = reviews.fold(0, (sum, item) => sum + item.rating);
            avgRating = totalStars / reviews.length;
          } else {
            avgRating = 0.0;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 90),

                // ẢNH HERO PROFILE
                Container(
                  height: 330,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
                    ],
                    image: (avatar.isNotEmpty) ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
                  ),
                  child: Stack(
                    children: [
                      if (avatar.isEmpty) const Center(child: Icon(Icons.person, size: 80, color: Colors.grey)),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [primaryColor.withOpacity(0.95), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: accentColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    specialty,
                                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                // 🔥 ĐỔ SỐ SAO VÀ SỐ LƯỢNG THẬT VÀO ĐÂY
                                Text(
                                  "${avgRating.toStringAsFixed(1)} (${reviews.length} nhận xét)",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // STATS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatBox("$experience năm", "Kinh nghiệm"),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _viewCertificate(certUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.verified_user_rounded, color: accentColor, size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  "Xem chứng chỉ",
                                  style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // GIỚI THIỆU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Giới thiệu",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(bio, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CHỌN GÓI BUỔI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Đăng ký khóa tập",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedDate == null ? Colors.grey.shade200 : accentColor,
                              width: _selectedDate == null ? 1 : 1.5,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: accentColor, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ngày bắt đầu tập",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedDate == null
                                          ? "Bấm để chọn ngày kích hoạt"
                                          : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year} (${_dayLabels[_selectedDay]})",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTimeSlotPicker(),
                      const SizedBox(height: 24),

                      Text(
                        "Chọn gói số lượng buổi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 12),

                      Column(
                        children: _gymPackages.map((package) {
                          bool isSelected = _selectedPackage == package['name'];

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedPackage = package['name'] as String);
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? accentColor : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        package['name'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        package['desc'] as String,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(package['price'] as int),
                                        style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                                    color: isSelected ? accentColor : Colors.grey[300],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 🔥 KHU VỰC ĐÁNH GIÁ (TRUYỀN LIST REVIEW VÀO ĐÂY)
                _buildReviewSection(reviews),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),

      // BOTTOM BAR CONFIRM
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ElevatedButton(
          onPressed: _canSubmitBooking ? _bookPT : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: accentColor,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _bookingButtonText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // 🔥 VẼ LIST ĐÁNH GIÁ THẬT
  Widget _buildReviewSection(List<ReviewModel> reviews) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đánh giá",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              // NÚT BẤM ĐỂ HIỆN BẢNG VIẾT REVIEW
              TextButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: Icon(Icons.edit_note, color: accentColor, size: 18),
                label: Text(
                  "Viết đánh giá",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Text("Chưa có đánh giá nào. Hãy là người đầu tiên!", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...reviews
                .map(
                  (review) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: review.userAvatar.isNotEmpty ? NetworkImage(review.userAvatar) : null,
                              child: review.userAvatar.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  // Hiển thị sao thật của user đó
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < review.rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(review.content, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}
