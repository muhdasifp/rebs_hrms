import 'package:flutter/material.dart';
import 'package:hrms_test/features/attendance/view/attendance_screen.dart';
import 'package:hrms_test/features/dashboard/view/dashboard_screen.dart';
import 'package:hrms_test/features/leave/view/leave_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  final List<Widget> _screens = [
    DashboardScreen(),
    AttendanceScreen(),
    LeaveScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedFontSize: 15,
        unselectedFontSize: 14,
        onTap: (value) {
          setState(() {
            _index = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Leave',
          ),
        ],
      ),
    );
  }
}
