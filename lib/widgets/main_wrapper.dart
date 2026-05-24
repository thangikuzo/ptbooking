import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/account_screen.dart';
import '../screens/pt_booking_management_screen.dart';
import 'package:ptbooking/screens/pt_teaching_schedule_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/home_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/pt_booking_management_screen.dart';
import '../screens/pt_teaching_schedule_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';

class MainWrapper extends StatefulWidget {
  final String userRole;

  const MainWrapper({
    super.key,
    required this.userRole,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isFirstSnapshot = true;

  @override
  void initState() {
    super.initState();
    _initScreens();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((snapshot) {
        if (_isFirstSnapshot) {
          _isFirstSnapshot = false;
          return;
        }
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var data = change.doc.data();
            if (data != null) {
              String senderName = data['senderName'] ?? 'Ai đó';
              String message = data['message'] ?? 'đã gửi một thông báo.';
              NotificationService().showInteractionNotification(
                'Thông báo Thử thách',
                '$senderName $message',
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _initScreens() {
    if (widget.userRole == 'Admin') {
      _screens = [
        const AdminDashboard(),
        AccountScreen(userRole: widget.userRole),
      ];

      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Quản lý',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    } else if (widget.userRole == 'PT') {
      _screens = [
        const PTTeachingScheduleScreen(),
        const PTBookingManagementScreen(),
        const ChallengeScreen(),
        AccountScreen(userRole: widget.userRole),
      ];

      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Lịch dạy',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Học viên',
        ),
        BottomNavigationBarItem(
          icon: _NotificationBadgeIcon(iconData: Icons.emoji_events),
          label: 'Thử thách',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    } else {
      _screens = [
        const HomeScreen(),
        const ChatListScreen(),
        const ChallengeScreen(),
        const HistoryScreen(),
        AccountScreen(userRole: widget.userRole),
      ];

      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Tin nhắn',
        ),
        BottomNavigationBarItem(
          icon: _NotificationBadgeIcon(iconData: Icons.emoji_events_outlined),
          activeIcon: _NotificationBadgeIcon(iconData: Icons.emoji_events),
          label: 'Thử thách',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Lịch sử',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E3B55),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: _navItems,
      ),
    );
  }
}

class _NotificationBadgeIcon extends StatelessWidget {
  final IconData iconData;
  const _NotificationBadgeIcon({required this.iconData});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Icon(iconData);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(iconData),
            if (hasUnread)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}