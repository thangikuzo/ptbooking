import 'package:flutter/material.dart';
import 'package:ptbooking/features/wallet/services/wallet_service.dart';
import 'package:ptbooking/features/wallet/screens/wallet_screen.dart';
import 'package:ptbooking/features/pt_booking/widgets/pt_header_section.dart';
import 'package:ptbooking/features/pt_booking/widgets/pt_stats_section.dart';
import 'package:ptbooking/features/pt_booking/widgets/pt_packages_section.dart';
import 'package:ptbooking/features/pt_booking/widgets/pt_schedule_section.dart';
import 'package:ptbooking/features/pt_booking/widgets/pt_reviews_section.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ptbooking/core/constants/app_colors.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart'; // 🔥 KÉO FILE MODEL MỚI VÀO
import '../services/booking_service.dart';



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

  final Color primaryColor = AppColors.primaryDark;
  final Color accentColor = AppColors.accent;
  final Color bgColor = AppColors.background;

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCompactCurrency(int amount) {
    if (amount >= 1000000) {
      final value = amount / 1000000;
      final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      return '${text}tr';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()}k';
    }
    return '$amountđ';
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
                  errorBuilder: (context, error, stackTrace) => const Center(child: Text("Lỗi tải hình ảnh chứng chỉ")),
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
    if (!mounted) return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isBooking = false);
  }

  Widget _buildWalletBalanceChip() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        },
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _walletService.watchWallet(user.uid),
          builder: (context, snapshot) {
            final balance = _toInt(snapshot.data?.data()?['balance']);

            return Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: accentColor, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    _formatCompactCurrency(balance),
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Trainer Profile",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          _buildWalletBalanceChip(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('pt_id', isEqualTo: widget.ptUid)
            .snapshots(),
        builder: (context, snapshot) {
          List<ReviewModel> reviews = [];
          if (snapshot.hasData) {
            reviews = snapshot.data!.docs
                .map((doc) => ReviewModel.fromFirestore(doc))
                .toList();
            reviews.sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );
          }

          double avgRating = 0.0;
          if (reviews.isNotEmpty) {
            double total = 0;
            for (var r in reviews) {
              total += r.rating;
            }
            avgRating = total / reviews.length;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                PTHeaderSection(
                  avatar: avatar,
                  name: name,
                  specialty: specialty,
                  avgRating: avgRating,
                  reviewsCount: reviews.length,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 10),
                PTStatsSection(
                  experience: experience,
                  certUrl: certUrl ?? '',
                  onViewCertificate: () => _viewCertificate(certUrl),
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Giới thiệu",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        bio,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PTPackagesSection(
                  gymPackages: _gymPackages,
                  selectedPackage: _selectedPackage,
                  onPackageSelected: (val) => setState(() => _selectedPackage = val),
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  formatCurrency: _formatCompactCurrency,
                ),
                PTScheduleSection(
                  selectedDate: _selectedDate,
                  selectedDay: _selectedDay,
                  selectedTimeSlot: _selectedTimeSlot,
                  availableTimeSlots: _availableTimeSlots,
                  isLoadingSlots: _isLoadingSlots,
                  dayLabels: _dayLabels,
                  onSelectDate: () => _selectDate(context),
                  onTimeSlotSelected: (val) => setState(() => _selectedTimeSlot = val),
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                PTReviewsSection(
                  reviews: reviews,
                  onWriteReview: _showWriteReviewDialog,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _selectedDate != null &&
              _selectedTimeSlot != null &&
              _selectedPackage != null
          ? FloatingActionButton.extended(
              onPressed: _isBooking ? null : _bookPT,
              backgroundColor: accentColor,
              label: _isBooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "ĐẶT LỊCH NGAY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
