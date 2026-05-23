import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../feed/safety_feed_screen.dart';
import '../walk/walk_request_screen.dart';
import '../sos/sos_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/staff_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const studentNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'Feed',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Walk',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.sos_outlined),
      activeIcon: Icon(Icons.sos),
      label: 'SOS',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  static const staffNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'Feed',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Walk',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.admin_panel_settings_outlined),
      activeIcon: Icon(Icons.admin_panel_settings),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final role = authService.userModel?.role ?? 'student';
    final isStaff = role == 'admin';
    final screens = [
      const SafetyFeedScreen(),
      const WalkRequestScreen(),
      isStaff ? StaffDashboardScreen(role: role) : const SosScreen(),
      ProfileScreen(userRole: role),
    ];

    return Scaffold(
      drawer: CustomDrawer(userRole: role),
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: isStaff ? staffNavItems : studentNavItems,
      ),
    );
  }
}