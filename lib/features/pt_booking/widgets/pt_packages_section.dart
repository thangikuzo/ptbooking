import 'package:flutter/material.dart';

class PTPackagesSection extends StatelessWidget {
  final List<Map<String, dynamic>> gymPackages;
  final String? selectedPackage;
  final ValueChanged<String> onPackageSelected;
  final Color primaryColor;
  final Color accentColor;
  final String Function(int) formatCurrency;

  const PTPackagesSection({
    super.key,
    required this.gymPackages,
    required this.selectedPackage,
    required this.onPackageSelected,
    required this.primaryColor,
    required this.accentColor,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Đăng ký khóa tập",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 16),
        Column(
          children: gymPackages.map((package) {
            bool isSelected = selectedPackage == package['name'];

            return GestureDetector(
              onTap: () {
                onPackageSelected(package['name'] as String);
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package['desc'] as String,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(package['price'] as int),
                          style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_off,
                      color: isSelected ? accentColor : Colors.grey[300],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
