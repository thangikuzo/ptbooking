import 'package:flutter/material.dart';

class EditFormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController addressController;

  const EditFormSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.addressController,
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

  Widget _buildGenderAgeRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              labelText: "Giới tính",
              prefixIcon: const Icon(Icons.wc),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['Nam', 'Nữ', 'Khác'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              if (val != null) {
                onGenderChanged(val);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: ageController,
            label: "Tuổi",
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: heightController,
            label: "Cao (cm)",
            icon: Icons.height,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: weightController,
            label: "Nặng (kg)",
            icon: Icons.monitor_weight_outlined,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTextField(controller: nameController, label: "Họ và tên", icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(
          controller: phoneController,
          label: "Số điện thoại",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildGenderAgeRow(),
        const SizedBox(height: 16),
        _buildBodyMetricsRow(),
        const SizedBox(height: 16),
        _buildTextField(controller: addressController, label: "Địa chỉ", icon: Icons.location_on_outlined),
      ],
    );
  }
}
