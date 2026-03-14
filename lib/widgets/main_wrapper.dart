import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import '../screens/home_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/history_screen.dart';
import '../screens/account_screen.dart';

class MainWrapper extends StatefulWidget {
  // Biến nhận Role từ màn hình Login hoặc Splash truyền sang
  final String userRole;

  const MainWrapper({super.key, required this.userRole});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Dùng late vì chúng ta sẽ khởi tạo danh sách màn hình dựa vào Role
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    // 1. KIỂM TRA QUYỀN ADMIN
    if (widget.userRole == 'Admin') {
      _screens = [
        const AdminDashboard(), // Gọi màn hình quản lý
        AccountScreen(userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Quản lý'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      ];
    }
    // 2. KIỂM TRA QUYỀN PT
    else if (widget.userRole == 'PT') {
      _screens = [
        const Center(child: Text("Màn hình: Lịch dạy hôm nay (Dành cho PT)")),
        const Center(child: Text("Màn hình: Danh sách Học viên (Dành cho PT)")),
        AccountScreen(userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch dạy'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Học viên'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      ];
    }
    // 3. TẤT CẢ CÁC TRƯỜNG HỢP CÒN LẠI (Bao gồm 'User' và 'Pending_PT')
    // Họ sẽ dùng chung giao diện Khách hàng bình thường
    else {
      _screens = [
        const HomeScreen(),
        const ChallengeScreen(),
        const HistoryScreen(),
        AccountScreen(userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Thử thách'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
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
        items: _navItems, // Lấy danh sách icon theo Role
      ),
    );
  }
}