import 'package:flutter/material.dart';

class HomeCategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const HomeCategoriesSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140, // Đã fix chiều cao an toàn chống overflow chữ
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          bool isSelected = selectedCategory == cat['name'];

          return GestureDetector(
            onTap: () {
              onCategorySelected(cat['name'] as String);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      // Nếu được chọn -> đổi sang nền Xanh Navy đậm, ngược lại nền trắng
                      color: isSelected ? const Color(0xFF0B2447) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF0B2447) : const Color(0xFFE1E3E4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      // Nếu được chọn -> đổi icon sang màu trắng tinh khôi
                      color: isSelected ? Colors.white : const Color(0xFF0B2447),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF4BA3E3)
                          : const Color(0xFF0B2447), // Chọn thì chữ màu cam rực rỡ
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
