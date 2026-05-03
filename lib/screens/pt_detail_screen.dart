import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isCheckingSlots = false; // Hiệu ứng xoay khi đang check trùng lịch

  DateTime? _selectedDate; // Ngày cụ thể user chọn
  List<String> _bookedSlots = []; // Danh sách các giờ đã bị người khác đặt
  String? _selectedDay; // Tên thứ tiếng Anh (monday, tuesday...)
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
      print("Lỗi tải lịch PT: $e");
      setState(() => _isLoadingSchedule = false);
    }
  }

  // 2. Hàm mở bảng chọn ngày (DatePicker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)), // Cho phép đặt trước 30 ngày
      helpText: 'CHỌN NGÀY TẬP',
    );

    if (picked != null) {
      // Xác định ngày user chọn là Thứ mấy
      List<String> weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      String dayName = weekdays[picked.weekday - 1];

      setState(() {
        _selectedDate = picked;
        _selectedDay = dayName;
        _selectedTime = null; // Reset giờ khi đổi ngày
      });

      // Kiểm tra xem PT có rảnh thứ đó không
      if (!_ptSchedule.containsKey(dayName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PT không có lịch rảnh vào ${_dayLabels[dayName]}! Vui lòng chọn ngày khác."), backgroundColor: Colors.orange),
        );
        setState(() => _bookedSlots = []); // Xóa danh sách giờ bị trùng cũ
      } else {
        // Nếu rảnh, gọi hàm check xem đã có ai đặt giờ nào chưa
        _checkBookedSlots(picked);
      }
    }
  }

  // 3. Hàm truy vấn Firebase để tìm các giờ đã "Confirmed" trong ngày đó
  Future<void> _checkBookedSlots(DateTime date) async {
    setState(() => _isCheckingSlots = true);

    // Format ngày thành chuỗi yyyy-MM-dd để query
    String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('pt_id', isEqualTo: widget.ptUid)
          .where('booking_date', isEqualTo: dateStr) // Tìm đúng ngày đó
          .where('status', isEqualTo: 'confirmed')   // Chỉ lọc những đơn đã được PT chốt
          .get();

      setState(() {
        // Lấy ra danh sách các time_slot đã bị đặt
        _bookedSlots = snapshot.docs.map((doc) => doc['time_slot'].toString()).toList();
        _isCheckingSlots = false;
      });
    } catch (e) {
      print("Lỗi check trùng lịch: $e");
      setState(() => _isCheckingSlots = false);
    }
  }

  // 4. Hàm đẩy data lên bảng 'bookings'
  Future<void> _bookPT() async {
    if (_selectedDate == null || _selectedDay == null || _selectedTime == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập lại!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isBooking = true);

    try {
      String dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance.collection('bookings').add({
        'user_id': user.uid,
        'user_name': user.displayName ?? "Người dùng ",
        'pt_id': widget.ptUid,
        'pt_name': widget.ptData['name'] ?? "PT",
        'booking_date': dateStr,     // <-- LƯU THÊM NGÀY CỤ THỂ
        'day': _selectedDay,
        'time_slot': _selectedTime,
        'status': 'pending',
        'payment_status': 'unpaid',
        'created_at': FieldValue.serverTimestamp(),
      });

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
                  radius: 40, // Kích thước ảnh, ông có thể chỉnh to nhỏ tùy ý
                  backgroundColor: Colors.grey[200],
                  // Kiểm tra nếu map ptData có chứa link ảnh thì lấy link đó load lên
                  backgroundImage: (widget.ptData['avatar'] != null && widget.ptData['avatar'].toString().isNotEmpty)
                      ? NetworkImage(widget.ptData['avatar'])
                      : null,
                  // Nếu không có link ảnh thì vẫn hiện cái icon người mặc định
                  child: (widget.ptData['avatar'] == null || widget.ptData['avatar'].toString().isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Chuyên môn: $specialty", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Kinh nghiệm: $experience năm", style: const TextStyle(color: Colors.grey)),
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
                  // 1. CHỌN NGÀY TỪ BẢNG LỊCH
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

                  // 2. CHỌN GIỜ (Chỉ hiện khi đã chọn Ngày và check xong)
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
                          // Kiểm tra xem giờ này đã bị ai đặt chưa
                          bool isBooked = _bookedSlots.contains(time.toString());

                          return ChoiceChip(
                            label: Text(isBooked ? "$time (Đã đặt)" : time.toString()),
                            selected: _selectedTime == time,
                            selectedColor: Colors.blueAccent.withOpacity(0.3),
                            disabledColor: Colors.grey[200], // Màu xám cho nút bị khóa
                            labelStyle: TextStyle(
                              color: isBooked ? Colors.grey : (_selectedTime == time ? Colors.blue[900] : Colors.black),
                              decoration: isBooked ? TextDecoration.lineThrough : null, // Gạch ngang chữ nếu bị khóa
                            ),
                            // Nếu isBooked == true thì set onSelected = null để khóa nút
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