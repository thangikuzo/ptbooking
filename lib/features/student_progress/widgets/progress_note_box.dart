import 'package:flutter/material.dart';

class ProgressNoteBox extends StatelessWidget {
  final TextEditingController noteController;

  const ProgressNoteBox({
    super.key,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: noteController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Nhận xét chi tiết",
        hintText: "Ví dụ: Tuần này học viên chuyên cần tốt, cần cải thiện kỹ thuật squat...",
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
