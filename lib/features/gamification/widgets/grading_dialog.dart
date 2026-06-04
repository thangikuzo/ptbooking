import 'package:flutter/material.dart';

class GradingDialog extends StatefulWidget {
  final String userName;
  final Function(int, int, int, int) onSaveScore;

  const GradingDialog({
    super.key,
    required this.userName,
    required this.onSaveScore,
  });

  @override
  State<GradingDialog> createState() => _GradingDialogState();
}

class _GradingDialogState extends State<GradingDialog> {
  int scoreBienDo = 0;
  int scoreTuThe = 0;
  int scoreKiemSoat = 0;
  int scoreHoanThanh = 0;

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

  @override
  Widget build(BuildContext context) {
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
            Text("Đánh giá bài tập của ${widget.userName}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            buildCriteriaRow("Biên độ", scoreBienDo, (val) => setState(() => scoreBienDo = val)),
            buildCriteriaRow("Tư thế", scoreTuThe, (val) => setState(() => scoreTuThe = val)),
            buildCriteriaRow("Kiểm soát", scoreKiemSoat, (val) => setState(() => scoreKiemSoat = val)),
            buildCriteriaRow(
              "Mức độ hoàn thành",
              scoreHoanThanh,
              (val) => setState(() => scoreHoanThanh = val),
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
          onPressed: () {
            if (scoreBienDo == 0 || scoreTuThe == 0 || scoreKiemSoat == 0 || scoreHoanThanh == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vui lòng chấm điểm tất cả tiêu chí!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onSaveScore(scoreBienDo, scoreTuThe, scoreKiemSoat, scoreHoanThanh);
          },
          child: const Text("LƯU ĐIỂM", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
