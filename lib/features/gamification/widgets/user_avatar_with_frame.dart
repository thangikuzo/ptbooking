import 'package:flutter/material.dart';

class UserAvatarWithFrame extends StatelessWidget {
  final String? avatarUrl;
  final String? selectedFrame;
  final double size;

  const UserAvatarWithFrame({
    super.key,
    required this.avatarUrl,
    required this.selectedFrame,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // User Avatar Circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, size: size * 0.6, color: Colors.grey),
                  )
                : Icon(Icons.person, size: size * 0.6, color: Colors.grey),
          ),
        ),
        // Frame Overlay
        if (selectedFrame != null && selectedFrame!.isNotEmpty)
          Positioned(
            width: size * 1.35,
            height: size * 1.35,
            child: Image.asset(
              selectedFrame!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
