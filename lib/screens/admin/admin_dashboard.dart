// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'tabs/pending_pt_tab.dart';
import 'tabs/pt_list_tab.dart';
import 'tabs/user_list_tab.dart';
import 'tabs/booking_list_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1E2937);     // Xanh đen sâu
    const Color accent = Color(0xFFF97316);      // Cam nổi bật hơn
    const Color bg = Color(0xFFF8FAFC);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ==================== HEADER PREMIUM ====================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield_outlined, color: primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ADMIN",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Quản trị viên hệ thống",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primary,
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================== PILL TAB BAR ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    unselectedLabelColor: primary.withOpacity(0.7),
                    labelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    indicator: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: "HỒ SƠ MỚI"),
                      Tab(text: "HLV (PT)"),
                      Tab(text: "HỌC VIÊN"),
                      Tab(text: "LỊCH ĐẶT"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================== TAB CONTENT ====================
              const Expanded(
                child: TabBarView(
                  children: [
                    PendingPTTab(),
                    PTListTab(),
                    UserListTab(),
                    BookingListTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}