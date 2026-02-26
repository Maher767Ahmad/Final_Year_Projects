import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'departments/my_department_screen.dart';
import 'departments/all_departments_screen.dart';
import 'requests/requests_screen.dart';
import 'profile/profile_screen.dart';

class MainAppNavigation extends StatefulWidget {
  const MainAppNavigation({super.key});

  @override
  State<MainAppNavigation> createState() => _MainAppNavigationState();
}

class _MainAppNavigationState extends State<MainAppNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyDepartmentScreen(),
    const AllDepartmentsScreen(),
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.domain_outlined),
            activeIcon: Icon(Icons.domain),
            label: 'My Dept',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_outlined),
            activeIcon: Icon(Icons.request_quote),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
