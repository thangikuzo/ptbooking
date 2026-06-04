import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeHeader extends StatelessWidget {
  final User? currentUser;
  final String userName;

  const HomeHeader({
    super.key,
    required this.currentUser,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE1E3E4), width: 2),
                ),
                child: ClipOval(
                  child: (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty)
                      ? Image.network(currentUser!.photoURL!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Color(0xFF0B2447)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Xin chào, $userName!",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
                  ),
                  Text("Tìm PT phù hợp ngay", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B2447)),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
