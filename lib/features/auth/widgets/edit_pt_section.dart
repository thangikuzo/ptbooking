import 'package:flutter/material.dart';

class EditPtSection extends StatelessWidget {
  final TextEditingController specialtyController;
  final TextEditingController experienceController;
  final TextEditingController bioController;

  const EditPtSection({
    super.key,
    required this.specialtyController,
    required this.experienceController,
    required this.bioController,
  });

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        const Text(
          "Thông tin Huấn luyện viên",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: specialtyController,
          label: "Chuyên môn (VD: Gym, Yoga...)",
          icon: Icons.fitness_center,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: experienceController,
          label: "Số năm kinh nghiệm",
          icon: Icons.star_border,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: bioController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Giới thiệu bản thân",
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 30), // Đẩy icon lên trên cùng
              child: Icon(Icons.description_outlined),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
