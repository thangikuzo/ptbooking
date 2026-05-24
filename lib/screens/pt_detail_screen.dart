import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Model và Service chuẩn Clean Architecture
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class PTDetailScreen extends StatefulWidget {
  final String ptUid;
  final Map<String, dynamic> ptData;

  const PTDetailScreen({super.key, required this.ptUid, required this.ptData});

  @override
  State<PTDetailScreen> createState() => _PTDetailScreenState();
}

class _PTDetailScreenState extends State<PTDetailScreen> {
  Map<String, List<dynamic>> _ptSchedule = {};
  bool _isLoadingSchedule = true;
  bool _isBooking = false;
  bool _isCheckingSlots = false;

  DateTime? _selectedDate;
  List<String> _bookedSlots = [];
  String? _selectedDay;
  String? _selectedTime;

  final Map<String, String> _dayLabels = {
    'monday': 'Thứ 2', 'tuesday': 'Thứ 3', 'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5', 'friday': 'Thứ 6', 'saturday': 'Thứ 7', 'sunday': 'Chủ Nhật',
  };

  @override
  void initState() {
    super.initState();
    _loadPTSchedule();
  }

  // 1. Kéo lịch rảnh của PT từ Firestore về
  Future<void> _loadPTSchedule() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('schedules').doc(widget.ptUid).get();
      if (doc.exists && doc.data()?['availability'] != null) {
        Map<String, dynamic> data = doc.data()?['availability'];

        Map<String, List<dynamic>> filteredSchedule = {};
        data.forEach((key, value) {
          List<dynamic> times = value as List<dynamic>;
          if (times.isNotEmpty) filteredSchedule[key] = times;
        });

        setState(() {
          _ptSchedule = filteredSchedule;
          _isLoadingSchedule = false;
        });
      } else {
        setState(() => _isLoadingSchedule = false);
      }
    } catch (e) {
      debugPrint("Lỗi tải lịch PT: $e");
      setState(() => _isLoadingSchedule = false);
    }
  }

  // 2. Hàm mở bảng chọn ngày (DatePicker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'CHỌN NGÀY TẬP',
    );

    if (picked != null) {
      List<String> weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      String dayName = weekdays[picked.weekday - 1];

      setState(() {
        _selectedDate = picked;
        _selectedDay = dayName;
        _selectedTime = null;
      });

      if (!_ptSchedule.containsKey(dayName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PT không có lịch rảnh vào ${_dayLabels[dayName]}! Vui lòng chọn ngày khác."), backgroundColor: Colors.orange),
        );
        setState(() => _bookedSlots = []);
      } else {
        _checkBookedSlots(picked);
      }
    }
  }

  // 3. SỬ DỤNG BOOKING SERVICE: Kiểm tra giờ đã bị đặt
  Future<void> _checkBookedSlots(DateTime date) async {
    setState(() => _isCheckingSlots = true);
    try {
      // Gọi service thay vì chọc thẳng vào Firebase
      List<String> booked = await BookingService().getBookedSlots(widget.ptUid, date);
      setState(() {
        _bookedSlots = booked;
        _isCheckingSlots = false;
      });
    } catch (e) {
      debugPrint("Lỗi check trùng lịch: $e");
      setState(() => _isCheckingSlots = false);
    }
  }

  // 4. SỬ DỤNG BOOKING MODEL VÀ SERVICE: Đẩy lịch lên Firebase
  Future<void> _bookPT() async {
    if (_selectedDate == null || _selectedDay == null || _selectedTime == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập lại!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Lấy tên thật của Học viên từ bảng Users
      String realUserName = "Học viên";
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        realUserName = userDoc.data()!['name'] ?? "Học viên";
      }

      String dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      // ĐÓNG GÓI DATA VÀO MODEL
      BookingModel newBooking = BookingModel(
        id: '', // Firebase tự sinh ID nên để trống
        userId: user.uid,
        userName: realUserName,
        ptId: widget.ptUid,
        ptName: widget.ptData['name'] ?? "PT",
        bookingDate: dateStr,
        day: _selectedDay!,
        timeSlot: _selectedTime!,
        status: 'pending',
        paymentStatus: 'unpaid', // Đã khớp với Model
      );

      // GỌI SERVICE ĐẨY LÊN FIREBASE
      await BookingService().createBooking(newBooking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gửi yêu cầu đặt lịch thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    }

    setState(() => _isBooking = false);
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.ptData['name'] ?? 'Không tên';
    String specialty = widget.ptData['specialty'] ?? 'Chưa cập nhật';
    String bio = widget.ptData['bio'] ?? 'Chưa có thông tin giới thiệu.';
    String experience = widget.ptData['experience'] ?? '0';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Chi tiết PT"), backgroundColor: const Color(0xFF2E3B55)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THÔNG TIN PT ---
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (widget.ptData['avatar'] != null && widget.ptData['avatar'].toString().isNotEmpty)
                      ? NetworkImage(widget.ptData['avatar'])
                      : null,
                  child: (widget.ptData['avatar'] == null || widget.ptData['avatar'].toString().isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Chuyên môn: $specialty", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Kinh nghiệm: $experience năm", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text("${widget.ptData['followerCount'] ?? 0} người theo dõi", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text("Giới thiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(bio, style: const TextStyle(fontSize: 14, height: 1.5)),
            const Divider(height: 40),

            // --- LỊCH RẢNH (SCHEDULE) ---
            const Text("Chọn lịch tập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (_isLoadingSchedule)
              const Center(child: CircularProgressIndicator())
            else if (_ptSchedule.isEmpty)
              const Center(child: Text("PT này hiện chưa có lịch rảnh.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CHỌN NGÀY
                  const Text("1. Chọn ngày cụ thể", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      label: Text(
                        _selectedDate == null
                            ? "Bấm vào đây để chọn ngày"
                            : "Ngày: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year} (${_dayLabels[_selectedDay]})",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. CHỌN GIỜ
                  if (_selectedDay != null && _ptSchedule.containsKey(_selectedDay)) ...[
                    const Text("2. Chọn giờ (1 ca = 60 phút)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),

                    if (_isCheckingSlots)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: _ptSchedule[_selectedDay]!.map((time) {
                          bool isBooked = _bookedSlots.contains(time.toString());

                          return ChoiceChip(
                            label: Text(isBooked ? "$time (Đã đặt)" : time.toString()),
                            selected: _selectedTime == time,
                            selectedColor: Colors.blueAccent.withOpacity(0.3),
                            disabledColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isBooked ? Colors.grey : (_selectedTime == time ? Colors.blue[900] : Colors.black),
                              decoration: isBooked ? TextDecoration.lineThrough : null,
                            ),
                            onSelected: isBooked ? null : (selected) {
                              setState(() {
                                _selectedTime = selected ? time.toString() : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ]
                ],
              ),
          ],
        ),
      ),

      // --- NÚT ĐẶT LỊCH ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton(
          onPressed: (_selectedDate != null && _selectedTime != null && !_isBooking) ? _bookPT : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFFFCA311),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("ĐẶT LỊCH NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}