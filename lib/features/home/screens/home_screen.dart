import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ptbooking/core/widgets/daily_reward_dialog.dart';
import 'package:ptbooking/features/gamification/services/gamification_service.dart';

import 'package:ptbooking/features/home/widgets/home_header.dart';
import 'package:ptbooking/features/home/widgets/home_search_bar.dart';
import 'package:ptbooking/features/home/widgets/upcoming_session_banner.dart';
import 'package:ptbooking/features/home/widgets/promotion_banner.dart';
import 'package:ptbooking/features/home/widgets/home_categories_section.dart';
import 'package:ptbooking/features/home/widgets/home_featured_pts_section.dart';
import 'package:ptbooking/features/home/widgets/home_new_arrivals_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GamificationService _gamificationService = GamificationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _selectedCategory = 'Tất cả';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _checkDailyLogin();
  }

  Future<void> _checkDailyLogin() async {
    if (_currentUser != null) {
      bool receivedReward = await _gamificationService.checkDailyLogin(_currentUser!.uid);
      if (receivedReward && mounted) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
        if (doc.exists) {
          int streak = (doc.data() as Map<String, dynamic>)['loginStreak'] as int? ?? 1;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DailyRewardDialog(streak: streak);
            },
          );
        }
      }
    }
  }

  String get _userName {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    return "Học viên";
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tất cả', 'icon': Icons.grid_view_rounded, 'keywords': <String>[]},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'keywords': ['gym', 'tăng cơ', 'bodybuilding', 'strength']},
    {'name': 'Giảm cân', 'icon': Icons.local_fire_department, 'keywords': ['giảm cân', 'fat loss', 'cardio', 'dinh dưỡng']},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'keywords': ['yoga', 'stretching', 'thiền']},
    {'name': 'Boxing', 'icon': Icons.sports_mma, 'keywords': ['boxing', 'kickboxing', 'mma']},
    {'name': 'Pilates', 'icon': Icons.accessibility_new, 'keywords': ['pilates', 'core', 'phục hồi']},
    {'name': 'Crossfit', 'icon': Icons.timer, 'keywords': ['crossfit', 'hiit', 'conditioning']},
  ];

  Widget _buildSectionHeader(String title, bool showAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B2447)),
          ),
          if (showAction)
            TextButton(
              onPressed: () {},
              child: const Text(
                "Xem tất cả",
                style: TextStyle(color: Color(0xFF4BA3E3), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(currentUser: _currentUser, userName: _userName),
              HomeSearchBar(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
              const UpcomingSessionBanner(),
              const PromotionBanner(),
              HomeCategoriesSection(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              _buildSectionHeader("PT Nổi bật", true),
              HomeFeaturedPTsSection(
                searchText: _searchText,
                selectedCategory: _selectedCategory,
                categories: _categories,
              ),
              _buildSectionHeader("PT Mới gia nhập", false),
              const HomeNewArrivalsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
