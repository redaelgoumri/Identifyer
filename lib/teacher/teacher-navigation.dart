import 'package:flutter/material.dart';
import 'package:identifyer/teacher/teacher-account-details.dart';
import 'teacher-dashboard.dart';
import 'teacher-sessions.dart';

class TeacherNavigation extends StatefulWidget {
  final String teacherId; // Pass teacherId from login

  const TeacherNavigation({super.key, required this.teacherId});

  @override
  State<TeacherNavigation> createState() => _TeacherNavigationState();
}

class _TeacherNavigationState extends State<TeacherNavigation> {
  late final String teacherId;
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    teacherId = widget.teacherId; // Assign teacherId from widget
    print('<DEBUG> Teacher ID in Navigation: $teacherId'); // Debug
    _pages = [
      TeacherDashboardPage(teacherId: teacherId), // Pass teacherId
      TeacherSessionsPage(teacherId: teacherId),  // Pass teacherId
      TeacherAccountDetailsPage(teacherId: teacherId),  // Pass teacherId
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Increase height to accommodate more white space
        child: Padding(
          padding: const EdgeInsets.only(top: 40), // Add more padding to lower the AppBar
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16), // Add horizontal margin for spacing
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2), // Bright blue background
              borderRadius: BorderRadius.circular(20), // Rounded edges
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // Shadow for depth
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16), // Add vertical padding inside the container
                child: Text(
                  _pageTitles[_currentIndex],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 80, // Increased height for the bottom navigation bar
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Sessions Button (Left)
            _buildNavItem(
              icon: Icons.event,
              label: 'Sessions',
              index: 1,
            ),
            // Dashboard Button (Center)
            _buildCenterNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
            ),
            // Account Button (Right)
            _buildNavItem(
              icon: Icons.account_box,
              label: 'Account',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Build a regular navigation item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: Colors.blue.withOpacity(0.2), // Ripple effect color
        borderRadius: BorderRadius.circular(8), // Rounded corners for ripple effect
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8), // Add padding for better touch area
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _currentIndex == index ? const Color(0xFF1976D2) : Colors.grey,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: _currentIndex == index ? const Color(0xFF1976D2) : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the center navigation item (Dashboard)
  Widget _buildCenterNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      splashColor: Colors.blue.withOpacity(0.2), // Ripple effect color
      borderRadius: BorderRadius.circular(30), // Rounded corners for ripple effect
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 8), // Add margin for better spacing
        decoration: BoxDecoration(
          color: _currentIndex == index ? const Color(0xFF1976D2) : Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  // List of page titles corresponding to the BottomNavigationBar
  final List<String> _pageTitles = [
    'Dashboard',
    'Sessions',
    'Account Details',
  ];
}