import 'package:flutter/material.dart';


class ProgressLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // each entry should contain 'total_score' and optionally 'week'
  const ProgressLineChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('Chưa có dữ liệu tiến độ', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: CustomPaint(
        painter: _LineChartPainter(data),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paintLine = Paint()
      ..color = const Color(0xFF2E3B55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintDot = Paint()..color = const Color(0xFFFFA515);

    final scores = data.map((d) {
        final val = d["total_score"];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }).toList();
    final maxScore = (scores.reduce((a, b) => a > b ? a : b)) + 1.0;
    final padding = 16.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;

    // Map data points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final score = scores[i];
      final dx = data.length > 1 ? padding + (i / (data.length - 1)) * chartWidth : size.width / 2;
      final dy = padding + chartHeight * (1 - (score / maxScore));
      points.add(Offset(dx, dy));

      // Draw week labels
      final weekText = (data[i]['week'] ?? (i + 1)).toString();
      final textPainter = TextPainter(
        text: TextSpan(text: weekText, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(dx - textPainter.width / 2, size.height - 15));
    }

    // Draw lines
    if (points.length > 1) {
      final path = Path();
      for (int i = 0; i < points.length; i++) {
        if (i == 0) {
          path.moveTo(points[i].dx, points[i].dy);
        } else {
          path.lineTo(points[i].dx, points[i].dy);
        }
      }
      canvas.drawPath(path, paintLine);
    }

    // Draw dots
    for (final p in points) {
      canvas.drawCircle(p, 4, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
