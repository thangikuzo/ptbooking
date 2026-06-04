import 'package:flutter/material.dart';

class HomeNewArrivalsSection extends StatelessWidget {
  const HomeNewArrivalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E3E4)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "https://i.pravatar.cc/150?img=${index + 10}",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index == 0 ? "Phan Anh" : "Trần Long",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
                    ),
                    Text(
                      index == 0 ? "Chuyên gia Pilates • 5 năm" : "Giảm cân • Dinh dưỡng",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFDDB8), borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  "NEW",
                  style: TextStyle(color: Color(0xFF653E00), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
