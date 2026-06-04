import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptbooking/features/student_progress/widgets/progress_header.dart';
import 'package:ptbooking/features/student_progress/widgets/progress_week_selector.dart';
import 'package:ptbooking/features/student_progress/widgets/progress_summary.dart';
import 'package:ptbooking/features/student_progress/widgets/progress_score_card.dart';
import 'package:ptbooking/features/student_progress/widgets/progress_note_box.dart';

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
  State<StudentProgressDetailScreen> createState() => _StudentProgressDetailScreenState();
}

class _StudentProgressDetailScreenState extends State<StudentProgressDetailScreen> {
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

  Future<void> _saveProgress() async {
    setState(() => isSaving = true);

    String ptName = 'PT';
    try {
      final ptSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.ptId).get();
      if (ptSnapshot.exists) {
        ptName = ptSnapshot.data()?['name']?.toString() ?? 'PT';
      }
    } catch (_) {}

    final docId = '${widget.studentId}_${widget.ptId}_${selectedYear}_${selectedMonth}_$selectedWeek';

    await FirebaseFirestore.instance.collection('student_progress').doc(docId).set({
      'pt_id': widget.ptId,
      'pt_name': ptName,
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
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã lưu đánh giá tuần."), backgroundColor: Colors.green));

      Navigator.pop(context);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 8.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 8.0;
  }

  Future<void> _fetchExistingProgress() async {
    final docId = '${widget.studentId}_${widget.ptId}_${selectedYear}_${selectedMonth}_$selectedWeek';
    try {
      final doc = await FirebaseFirestore.instance.collection('student_progress').doc(docId).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          attendance = _toDouble(data['attendance_score']);
          technique = _toDouble(data['technique_score']);
          stamina = _toDouble(data['stamina_score']);
          attitude = _toDouble(data['attitude_score']);
          nutrition = _toDouble(data['nutrition_score']);
          noteController.text = data['note']?.toString() ?? '';
        });
      } else if (mounted) {
        setState(() {
          attendance = 8;
          technique = 8;
          stamina = 8;
          attitude = 8;
          nutrition = 8;
          noteController.clear();
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _fetchExistingProgress();
  }

  @override
  void dispose() {
    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0B2447);
    const accentColor = Color(0xFF4BA3E3);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Đánh giá học viên"), backgroundColor: primaryColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProgressHeader(
            studentName: widget.studentName,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          ProgressWeekSelector(
            selectedWeek: selectedWeek,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            onWeekChanged: (val) {
              setState(() => selectedWeek = val ?? 1);
              _fetchExistingProgress();
            },
            onMonthChanged: (val) {
              setState(() => selectedMonth = val ?? DateTime.now().month);
              _fetchExistingProgress();
            },
            onYearChanged: (val) {
              setState(() => selectedYear = val ?? DateTime.now().year);
              _fetchExistingProgress();
            },
          ),
          const SizedBox(height: 16),
          ProgressSummary(
            computedScore: _computedScore,
            rank: rank,
            rankColor: rankColor,
          ),
          const SizedBox(height: 16),

          ProgressScoreCard(
            title: "Chuyên cần",
            subtitle: "Đi học đúng giờ, tham gia đủ buổi",
            icon: Icons.event_available,
            value: attendance,
            onChanged: (v) => setState(() => attendance = v),
          ),

          ProgressScoreCard(
            title: "Kỹ thuật",
            subtitle: "Thực hiện động tác đúng form",
            icon: Icons.fitness_center,
            value: technique,
            onChanged: (v) => setState(() => technique = v),
          ),

          ProgressScoreCard(
            title: "Thể lực",
            subtitle: "Sức bền, sức mạnh, khả năng hoàn thành bài tập",
            icon: Icons.bolt,
            value: stamina,
            onChanged: (v) => setState(() => stamina = v),
          ),

          ProgressScoreCard(
            title: "Thái độ luyện tập",
            subtitle: "Tinh thần, tập trung và hợp tác với PT",
            icon: Icons.psychology,
            value: attitude,
            onChanged: (v) => setState(() => attitude = v),
          ),

          ProgressScoreCard(
            title: "Dinh dưỡng",
            subtitle: "Tuân thủ chế độ ăn và sinh hoạt",
            icon: Icons.restaurant_menu,
            value: nutrition,
            onChanged: (v) => setState(() => nutrition = v),
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 10),
          ProgressNoteBox(noteController: noteController),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: isSaving ? null : _saveProgress,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "LƯU ĐÁNH GIÁ TUẦN",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
