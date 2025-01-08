import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherAccountDetailsPage extends StatefulWidget {
  final String teacherId;

  const TeacherAccountDetailsPage({
    super.key,
    required this.teacherId,
  });

  @override
  State<TeacherAccountDetailsPage> createState() =>
      _TeacherAccountDetailsPageState();
}

class _TeacherAccountDetailsPageState extends State<TeacherAccountDetailsPage> {
  late String teacherId;
  Map<String, dynamic>? teacherData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    teacherId = widget.teacherId;
    fetchTeacherDetails();
  }

  // Fetch teacher data from Supabase
  Future<void> fetchTeacherDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('User')
          .select('first_name, last_name, email, module, passkey, created_at')
          .eq('id', teacherId)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        print('<DEBUG> Teacher Data: $response'); // Debugging
        setState(() {
          teacherData = response;
          _isLoading = false;
        });
      } else {
        print('<ERROR> No teacher data found.');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('<ERROR> Failed to fetch teacher details: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching data
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if data failed to load
    if (_hasError || teacherData == null) {
      return Scaffold(
        body: const Center(
          child: Text(
            'Failed to load data. Please try again later.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    // Safely retrieve data
    final String fullName =
        '${teacherData!['first_name'] ?? 'Unknown'} ${teacherData!['last_name'] ?? ''}';
    final String email = teacherData!['email'] ?? 'No email available';
    final String module = teacherData!['module'] ?? 'N/A';
    final String passkey = teacherData!['passkey'] ?? '---';
    final String joinDate = _formatDate(teacherData!['created_at']);

    return Scaffold(
      backgroundColor: Colors.blue[50], // Light blue background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Teacher Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Teacher Name and Email
            Text(
              fullName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 25),

            // Module and Passkey Section
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(
                  'Module: $module',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Passkey: $passkey'),
              ),
            ),

            // Join Date Section
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text(
                  'Joined On',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(joinDate),
              ),
            ),
            const SizedBox(height: 20),
/*
            // Quick Actions Section
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Add change password logic
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Add contact support logic
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
*/
            // Logout Button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Format date to display properly
  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}-${parsedDate.month}-${parsedDate.year}';
    } catch (e) {
      print('<ERROR> Date parsing failed: $e');
      return 'N/A';
    }
  }
}