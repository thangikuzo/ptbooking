import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/category_screen.dart';
import '../screens/history_screen.dart';
import '../screens/account_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; // Mặc định hiển thị tab đầu tiên (Trang chủ)

  // Danh sách các màn hình
  // Lưu ý: Các màn hình này phải được define ở folder screens/
  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const HistoryScreen(),
    const AccountScreen(), // Logic đăng xuất sẽ nằm trong AccountScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị màn hình tương ứng với tab đang chọn
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // Giữ trạng thái màn hình khi chuyển tab
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Cố định vị trí icon
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E3B55), // Màu xanh chủ đạo
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Danh mục',
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
        ],
      ),
    );
  }
}