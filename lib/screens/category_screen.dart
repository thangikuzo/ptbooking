import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {"name": "Gym", "icon": Icons.fitness_center, "color": Colors.blue},
      {"name": "Yoga", "icon": Icons.self_improvement, "color": Colors.purple},
      {"name": "Cardio", "icon": Icons.directions_run, "color": Colors.red},
      {"name": "Boxing", "icon": Icons.sports_mma, "color": Colors.orange},
      {"name": "Pilates", "icon": Icons.accessibility_new, "color": Colors.teal},
      {"name": "Zumba", "icon": Icons.music_note, "color": Colors.pink},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh mục tập luyện"),
        backgroundColor: const Color(0xFF2E3B55),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Tỷ lệ chiều rộng/cao
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Container(
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (cat['color'] as Color).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'], size: 40, color: cat['color']),
                  const SizedBox(height: 10),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cat['color'],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}