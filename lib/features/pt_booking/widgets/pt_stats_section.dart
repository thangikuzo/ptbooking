import 'package:flutter/material.dart';

class PTStatsSection extends StatelessWidget {
  final String experience;
  final String certUrl;
  final VoidCallback onViewCertificate;
  final Color primaryColor;
  final Color accentColor;

  const PTStatsSection({
    super.key,
    required this.experience,
    required this.certUrl,
    required this.onViewCertificate,
    required this.primaryColor,
    required this.accentColor,
  });

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatBox("$experience năm", "Kinh nghiệm"),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: onViewCertificate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.verified_user_rounded, color: accentColor, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      "Xem chứng chỉ",
                      style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
