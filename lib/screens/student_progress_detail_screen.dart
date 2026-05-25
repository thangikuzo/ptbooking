import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String ptId;

  const StudentProgressDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.ptId,
  });

  @override
  State<StudentProgressDetailScreen> createState() =>
      _StudentProgressDetailScreenState();
}

class _StudentProgressDetailScreenState
    extends State<StudentProgressDetailScreen> {
  final TextEditingController noteController = TextEditingController();



  int selectedWeek = 1;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  double attendance = 8;
  double technique = 8;
  double stamina = 8;
  double attitude = 8;
  double nutrition = 8;

  bool isSaving = false;

  double get _computedScore {
    return (attendance + technique + stamina + attitude + nutrition) / 5;
  }



  String get rank {
    if (_computedScore >= 9) return "Xuất sắc";
    if (_computedScore >= 8) return "Tốt";
    if (_computedScore >= 6.5) return "Khá";
    if (_computedScore >= 5) return "Trung bình";
    return "Cần cải thiện";
  }

  Color get rankColor {
    if (_computedScore >= 8) return Colors.green;
    if (_computedScore >= 6.5) return Colors.orange;
    return Colors.red;
  }

  @override


  Future<void> _saveProgress() async {
    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('student_progress').add({
      'pt_id': widget.ptId,
      'student_id': widget.studentId,
      'student_name': widget.studentName,

      'week': selectedWeek,
      'month': selectedMonth,
      'year': selectedYear,

      'attendance_score': attendance.toInt(),
      'technique_score': technique.toInt(),
      'stamina_score': stamina.toInt(),
      'attitude_score': attitude.toInt(),
      'nutrition_score': nutrition.toInt(),

      'total_score': _computedScore, // store as double
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'rank': rank,
      'note': noteController.text.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã lưu đánh giá tuần."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E3B55);
    const accentColor = Color(0xFFFCA311);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Đánh giá học viên"),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(primaryColor),
          const SizedBox(height: 16),
          _buildWeekSelector(),
          const SizedBox(height: 16),
          _buildSummary(),
          const SizedBox(height: 16),

          _buildScoreCard(
            title: "Chuyên cần",
            subtitle: "Đi học đúng giờ, tham gia đủ buổi",
            icon: Icons.event_available,
            value: attendance,
            onChanged: (v) => setState(() => attendance = v),
          ),

          _buildScoreCard(
            title: "Kỹ thuật",
            subtitle: "Thực hiện động tác đúng form",
            icon: Icons.fitness_center,
            value: technique,
            onChanged: (v) => setState(() => technique = v),
          ),

          _buildScoreCard(
            title: "Thể lực",
            subtitle: "Sức bền, sức mạnh, khả năng hoàn thành bài tập",
            icon: Icons.bolt,
            value: stamina,
            onChanged: (v) => setState(() => stamina = v),
          ),

          _buildScoreCard(
            title: "Thái độ luyện tập",
            subtitle: "Tinh thần, tập trung và hợp tác với PT",
            icon: Icons.psychology,
            value: attitude,
            onChanged: (v) => setState(() => attitude = v),
          ),

          _buildScoreCard(
            title: "Dinh dưỡng",
            subtitle: "Tuân thủ chế độ ăn và sinh hoạt",
            icon: Icons.restaurant_menu,
            value: nutrition,
            onChanged: (v) => setState(() => nutrition = v),
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 10),
          _buildNoteBox(),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: isSaving ? null : _saveProgress,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "LƯU ĐÁNH GIÁ TUẦN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bảng đánh giá tiến độ",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedWeek,
              decoration: const InputDecoration(labelText: "Tuần"),
              items: List.generate(5, (index) {
                final week = index + 1;
                return DropdownMenuItem(
                  value: week,
                  child: Text("Tuần $week"),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedWeek = value ?? 1;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: "Tháng"),
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text("Tháng $month"),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value ?? DateTime.now().month;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: "Năm"),
              items: [
                DateTime.now().year - 1,
                DateTime.now().year,
                DateTime.now().year + 1,
              ].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text("$year"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value ?? DateTime.now().year;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withOpacity(0.12),
              border: Border.all(color: rankColor, width: 3),
            ),
            child: Center(
              child: Text(
                _computedScore.toStringAsFixed(1),
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Điểm tổng quan tuần này",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  rank,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _computedScore / 10,
                    minHeight: 9,
                    backgroundColor: Colors.grey[200],
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFCA311).withOpacity(0.15),
                child: Icon(icon, color: const Color(0xFFFCA311)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "${value.toInt()}/10",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: const Color(0xFFFCA311),
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox() {
    return TextField(
      controller: noteController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Nhận xét chi tiết",
        hintText: "Ví dụ: Tuần này học viên chuyên cần tốt, cần cải thiện kỹ thuật squat...",
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}