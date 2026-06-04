import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/core/constants/app_colors.dart';
import 'package:ptbooking/features/pt_booking/models/booking_model.dart';
import 'package:ptbooking/features/pt_booking/models/session_model.dart';
import 'package:ptbooking/features/pt_booking/services/booking_service.dart';

class PackageDetailScreen extends StatefulWidget {
  final String bookingId;

  const PackageDetailScreen({super.key, required this.bookingId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final BookingService _bookingService = BookingService();
  bool _isProcessing = false;

  final Map<String, String> _dayLabels = {
    'monday': 'Thứ 2',
    'tuesday': 'Thứ 3',
    'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5',
    'friday': 'Thứ 6',
    'saturday': 'Thứ 7',
    'sunday': 'Chủ Nhật',
  };

  String _translateDay(String englishDay) {
    return _dayLabels[englishDay.toLowerCase()] ?? englishDay;
  }

  void _showSchedulingBottomSheet(BookingModel booking, SessionModel session) async {
    DateTime? selectedDate;
    String? selectedDay;
    String? selectedTimeSlot;
    List<String> availableSlots = [];
    bool isLoadingSlots = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> loadSlots(DateTime date) async {
              setModalState(() {
                isLoadingSlots = true;
                availableSlots = [];
                selectedTimeSlot = null;
              });
              try {
                List<String> weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
                final dayName = weekdays[date.weekday - 1];
                final slots = await _bookingService.getAvailableSlots(
                  ptId: booking.ptId,
                  day: dayName,
                  date: date,
                );
                setModalState(() {
                  availableSlots = slots;
                  selectedDay = dayName;
                  selectedDate = date;
                  isLoadingSlots = false;
                });
              } catch (e) {
                setModalState(() => isLoadingSlots = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi tải lịch: $e"), backgroundColor: Colors.red),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Lên lịch - Buổi ${session.sessionNumber}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Lên lịch tập với PT ${booking.ptName}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Pick Date Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primaryDark,
                                onPrimary: Colors.white,
                                onSurface: AppColors.primaryDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        loadSlots(picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      selectedDate == null
                          ? "CHỌN NGÀY TẬP"
                          : "Ngày: ${_bookingService.formatDate(selectedDate!)} (${_translateDay(selectedDay ?? '')})",
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Slots list
                  if (selectedDate != null) ...[
                    const Text(
                      "Khung giờ trống:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 10),
                    if (isLoadingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (availableSlots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "PT không có khung giờ nào trống trong ngày này. Vui lòng chọn ngày khác.",
                          style: TextStyle(color: Colors.red[400], fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: availableSlots.map((slot) {
                          final isSelected = selectedTimeSlot == slot;
                          return ChoiceChip(
                            label: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: isSelected ? AppColors.accent : Colors.grey[300]!),
                            onSelected: (selected) {
                              setModalState(() {
                                selectedTimeSlot = selected ? slot : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],

                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedTimeSlot == null
                              ? null
                              : () async {
                                  Navigator.pop(context); // Close bottom sheet
                                  _submitSchedule(booking.id, session.sessionNumber, selectedDate!, selectedDay!, selectedTimeSlot!);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("LÊN LỊCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitSchedule(String bookingId, int sessionNumber, DateTime date, String day, String timeSlot) async {
    setState(() => _isProcessing = true);
    try {
      final dateStr = _bookingService.formatDate(date);
      await _bookingService.scheduleSession(
        bookingId: bookingId,
        sessionNumber: sessionNumber,
        dateStr: dateStr,
        day: day,
        timeSlot: timeSlot,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lên lịch buổi học thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi lên lịch: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelSchedule(BookingModel booking, SessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy lịch học"),
        content: Text("Bạn có chắc chắn muốn hủy lịch buổi học thứ ${session.sessionNumber} (${session.date} lúc ${session.timeSlot})?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Không")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Có, Hủy lịch", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _bookingService.cancelSession(
          bookingId: booking.id,
          sessionNumber: session.sessionNumber,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã hủy lịch buổi học."), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Chi tiết Gói tập", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0.5,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Gói tập không tồn tại hoặc đã bị xóa."));
                }

                final booking = BookingModel.fromFirestore(snapshot.data!);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(booking),
                      const SizedBox(height: 20),
                      const Text(
                        "Lịch trình buổi tập",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSessionsTimeline(booking),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeaderCard(BookingModel booking) {
    final progress = booking.completedSessions / booking.sessionCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.packageName.isNotEmpty ? booking.packageName : "Gói tập cá nhân",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "PT: ${booking.ptName}",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tiến độ: ${booking.completedSessions} / ${booking.sessionCount} buổi",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.15),
              color: AppColors.accent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTimeline(BookingModel booking) {
    if (booking.sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Chưa có thông tin lịch học.",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: booking.sessions.length,
      itemBuilder: (context, index) {
        final session = booking.sessions[index];
        final isLast = index == booking.sessions.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line and dot indicator
            Column(
              children: [
                _buildTimelineDot(session.status),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: _getTimelineColor(session.status).withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Session detail card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: _getTimelineColor(session.status).withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Buổi ${session.sessionNumber}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSessionInfo(session),
                        ],
                      ),
                    ),
                    _buildSessionActionButton(booking, session),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineDot(String status) {
    Color color = _getTimelineColor(status);
    IconData icon;

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        break;
      case 'scheduled':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Color _getTimelineColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSessionInfo(SessionModel session) {
    if (session.status == 'completed') {
      return Text(
        "Hoàn thành: ${session.date} | ${session.timeSlot}",
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 13),
      );
    } else if (session.status == 'scheduled') {
      return Text(
        "Đã lên lịch: ${session.date} (${_translateDay(session.day)}) | ${session.timeSlot}",
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 13),
      );
    } else {
      return Text(
        "Chưa lên lịch tập",
        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13),
      );
    }
  }

  Widget _buildSessionActionButton(BookingModel booking, SessionModel session) {
    if (session.status == 'unscheduled') {
      return ElevatedButton(
        onPressed: () => _showSchedulingBottomSheet(booking, session),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          elevation: 0,
        ),
        child: const Text(
          "Đặt lịch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    } else if (session.status == 'scheduled') {
      return TextButton.icon(
        onPressed: () => _cancelSchedule(booking, session),
        icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
        label: const Text(
          "Hủy lịch",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    } else {
      return const Icon(Icons.check_circle_outline, color: Colors.green, size: 24);
    }
  }
}
