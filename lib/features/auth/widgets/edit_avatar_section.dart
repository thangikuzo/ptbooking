import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ptbooking/features/gamification/screens/inventory_screen.dart';

class EditAvatarSection extends StatelessWidget {
  final File? imageFile;
  final String? avatarUrl;
  final String? selectedFrame;
  final VoidCallback onPickImage;
  final VoidCallback onFrameChanged;

  const EditAvatarSection({
    super.key,
    this.imageFile,
    this.avatarUrl,
    this.selectedFrame,
    required this.onPickImage,
    required this.onFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Avatar Image
              Container(
                margin: const EdgeInsets.all(16),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile!) as ImageProvider
                      : (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                  child: (imageFile == null && (avatarUrl == null || avatarUrl!.isEmpty))
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              // Frame Avatar (Khung viền bao quanh)
              if (selectedFrame != null && selectedFrame!.isNotEmpty)
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    selectedFrame!.replaceAll('.jpg', '.png'),
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              // Camera Icon Overlay
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF4BA3E3), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryScreen()));
            onFrameChanged();
          },
          icon: const Icon(Icons.shopping_bag, color: Colors.green),
          label: const Text(
            "Túi Đồ (Đổi khung Avatar)",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
