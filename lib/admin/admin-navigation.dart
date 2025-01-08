import 'package:flutter/material.dart';
import 'package:identifyer/admin/admin-sessions.dart';
import 'package:identifyer/admin/admin-account-details.dart';
import 'package:identifyer/admin/admin-students.dart';
import 'package:identifyer/admin/admin-dashboard.dart';
import 'package:identifyer/admin/admin-teachers.dart';

class AdminNavigation extends StatefulWidget {
  final String? adminId;
  final String? adminEmail; // Accept admin email

  const AdminNavigation({
    Key? key,
    this.adminId,
    this.adminEmail,
  }) : super(key: key);

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages and pass the admin email to the Account Details page
    _pages = [
      const AdminDashboardPage(),
      const AdminStudentsPage(),
      const AdminSessionsPage(),
      const AdminTeachersPage(),
      AdminAccountDetailsPage(adminEmail: widget.adminEmail ?? 'No email'), // Pass email here
    ];
  }

  final List<String> _pageTitles = [
    'Dashboard',
    'Students',
    'Sessions',
    'Teachers',
    'Account Details',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Increase height to match teacher's style
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
            // Students Button (Left)
            _buildNavItem(
              icon: Icons.people,
              label: 'Students',
              index: 1,
            ),
            // Sessions Button (Left Center)
            _buildNavItem(
              icon: Icons.event,
              label: 'Sessions',
              index: 2,
            ),
            // Dashboard Button (Center)
            _buildCenterNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
            ),
            // Teachers Button (Right Center)
            _buildNavItem(
              icon: Icons.book,
              label: 'Teachers',
              index: 3,
            ),
            // Account Button (Right)
            _buildNavItem(
              icon: Icons.account_box,
              label: 'Account',
              index: 4,
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
}