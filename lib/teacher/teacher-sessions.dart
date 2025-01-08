import 'package:flutter/material.dart';
import 'package:identifyer/teacher/teacher-navigation.dart';
import 'package:identifyer/teacher/teacher-session-scanner.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherSessionsPage extends StatefulWidget {
  final String teacherId; // Pass teacherId from login

  const TeacherSessionsPage({super.key, required this.teacherId});

  @override
  State<TeacherSessionsPage> createState() => _TeacherSessionsPageState();
}

class _TeacherSessionsPageState extends State<TeacherSessionsPage> {
  late final String teacherId;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  bool _isLoading = true;

  String? selectedYear;
  String? selectedSpecialty;
  String? selectedGroup;

  final List<String> years = List.generate(5, (index) => '${index + 1}');
  final List<String> specialties = ['IIR', 'GF', 'GI', 'GC', 'IAII', 'GESI'];
  final List<String> groups = List.generate(13, (index) => 'G${index + 1}');

  final Map<String, IconData> specialtyIcons = {
    'IIR': Icons.computer,
    'GF': Icons.attach_money,
    'GI': Icons.business,
    'GC': Icons.engineering,
    'IAII': Icons.auto_mode,
    'GESI': Icons.manage_accounts,
  };

  @override
  void initState() {
    super.initState();
    teacherId = widget.teacherId; // Assign teacherId from widget
    print('<DEBUG> Teacher ID in Sessions: $teacherId'); // Debug
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessionsResponse = await Supabase.instance.client
          .from('Sessions')
          .select('*')
          .eq('teacher', teacherId)
          .order('created_at', ascending: false);

      final sessions = List<Map<String, dynamic>>.from(sessionsResponse);

      setState(() {
        _sessions = sessions;
        _filteredSessions = sessions; // Initialize with all sessions
      });

      print('<DEBUG> Fetched Sessions: $_sessions');
    } catch (e) {
      print('<DEBUG> Error fetching teacher sessions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      _filteredSessions = _sessions.where((session) {
        final yearMatch =
            selectedYear == null || session['year']?.toString() == selectedYear;
        final specialtyMatch =
            selectedSpecialty == null || session['specialty'] == selectedSpecialty;
        final groupMatch =
            selectedGroup == null || session['group'] == selectedGroup;

        return yearMatch && specialtyMatch && groupMatch;
      }).toList();
    });
  }

  String formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return "N/A"; // Return a default value for null or empty dates
    }

    try {
      final DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yy (HH:mm)').format(parsedDate);
    } catch (e) {
      print('<DEBUG> Error parsing date: $e');
      return "Invalid Date"; // Return an error message if parsing fails
    }
  }

  void clearFilters() {
    setState(() {
      selectedYear = null;
      selectedSpecialty = null;
      selectedGroup = null;
      _filteredSessions = _sessions;
    });
  }

  Future<void> _refreshData() async {
    await fetchSessions();
  }

  void _showSessionForm(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: _SessionForm(
            teacherId: teacherId,
            years: years,
            specialties: specialties,
            groups: groups,
            onSubmit: (sessionDetails) async {
              // Create session in Supabase and get session ID
              final response = await Supabase.instance.client
                  .from('Sessions')
                  .insert(sessionDetails)
                  .select('id')
                  .single();

              if (response['id'] != null) {
                final String sessionId = response['id'];
                print('<DEBUG> Session created with ID: $sessionId');

                // Use parent context to pop the modal
                if (parentContext.mounted) {
                  Navigator.pop(parentContext); // Use parent context here
                  await Future.delayed(const Duration(milliseconds: 100));

                  Navigator.pushNamed(
                    parentContext,
                    '/scanning',
                    arguments: {
                      ...sessionDetails,
                      'session_id': sessionId,
                    },
                  );
                }
              } else {
                print('<ERROR> Failed to create session.');
              }
            },
          ),
        );
      },
    );
  }

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Center(
            child: Column(
              children: [
                Icon(
                  specialtyIcons[session['specialty']] ?? Icons.info,
                  size: 50,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Session Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: Text('Year: ${session['year'] ?? "N/A"}'),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: Text('Specialty: ${session['specialty'] ?? "N/A"}'),
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: Text('Group: ${session['group'] ?? "N/A"}'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.blue),
                title: const Text('Time Span'),
                subtitle: Text(
                  '${formatDate(session['start_time'] ?? "")} \n${formatDate(session['end_time'] ?? "")}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _downloadSessionFile(session['id']),
                icon: const Icon(Icons.download),
                label: const Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadSessionFile(String sessionId) async {
    try {
      final response = Supabase.instance.client.storage
          .from('sessions')
          .getPublicUrl('$sessionId.xlsx');

      if (response.isNotEmpty) {
        // Launch the URL to download the file
        await launchUrl(Uri.parse(response));
        print('<DEBUG> Download initiated for: $response');
      } else {
        print('<ERROR> No file found for session: $sessionId');
      }
    } catch (e) {
      print('<ERROR> Failed to download file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Section
                const Text(
                  'Filter Sessions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.blue),
                      onPressed: () {
                        _showFilterDialog(
                          context: context,
                          title: 'Year',
                          options: years,
                          selectedValue: selectedYear,
                          onSelected: (value) {
                            setState(() {
                              selectedYear = value;
                              applyFilters();
                            });
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.school, color: Colors.blue),
                      onPressed: () {
                        _showFilterDialog(
                          context: context,
                          title: 'Specialty',
                          options: specialties,
                          selectedValue: selectedSpecialty,
                          onSelected: (value) {
                            setState(() {
                              selectedSpecialty = value;
                              applyFilters();
                            });
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.group, color: Colors.blue),
                      onPressed: () {
                        _showFilterDialog(
                          context: context,
                          title: 'Group',
                          options: groups,
                          selectedValue: selectedGroup,
                          onSelected: (value) {
                            setState(() {
                              selectedGroup = value;
                              applyFilters();
                            });
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: clearFilters,
                    ),
                  ],
                ),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 16),

                // Sessions List
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = _filteredSessions[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showSessionDetails(context, session),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.blue.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                specialtyIcons[session['specialty']] ?? Icons.info,
                                size: 40,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${session['year']}-${session['specialty']}-${session['group']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Started » ${formatDate(session['created_at'])}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSessionForm(context),
        tooltip: 'Start Session',
        backgroundColor: Colors.black, // Set background color to black
        foregroundColor: Colors.white, // Set icon color to white
        elevation: 8, // Increase elevation for a more noticeable shadow
        child: const Icon(Icons.add, size: 30), // Increase icon size
      ),
    );
  }

  void _showFilterDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Filter by $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: selectedValue,
                  title: Text(option),
                  onChanged: (value) {
                    onSelected(value);
                    Navigator.pop(context); // Close the dialog after selecting
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _SessionForm extends StatefulWidget {
  final String teacherId; // Add teacherId as a parameter
  final List<String> years;
  final List<String> specialties;
  final List<String> groups;
  final Function(Map<String, String>) onSubmit;

  const _SessionForm({
    Key? key,
    required this.teacherId, // Require teacherId
    required this.years,
    required this.specialties,
    required this.groups,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  String? selectedYear;
  String? selectedSpecialty;
  String? selectedGroup;

  Future<void> _createSession() async {
    if (selectedYear == null || selectedSpecialty == null || selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Insert session into the database with status "active"
      final response = await Supabase.instance.client
          .from('Sessions')
          .insert({
        'year': selectedYear!,
        'specialty': selectedSpecialty!,
        'group': selectedGroup!,
        'teacher': widget.teacherId,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active', // Set status to "active"
      })
          .select('id') // Retrieve the generated session ID
          .single();

      final sessionId = response['id']; // Extract the session ID

      final sessionDetails = {
        'session_id': sessionId, // Include the session ID
        'year': selectedYear!,
        'specialty': selectedSpecialty!,
        'group': selectedGroup!,
        'teacher': widget.teacherId,
        'start_time': DateTime.now().toIso8601String(),
      };

      print('<DEBUG> Session created with ID: $sessionId'); // Debugging log

      // Navigate to CameraScreen with session details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            teacherId: widget.teacherId,
          ),
          settings: RouteSettings(arguments: sessionDetails), // Pass session details
        ),
      );
    } catch (e) {
      print('<ERROR> Failed to create session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create session. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: selectedYear,
          decoration: const InputDecoration(labelText: 'Year'),
          items: widget.years
              .map((year) => DropdownMenuItem(value: year, child: Text(year)))
              .toList(),
          onChanged: (value) => setState(() => selectedYear = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedSpecialty,
          decoration: const InputDecoration(labelText: 'Specialty'),
          items: widget.specialties
              .map((specialty) =>
              DropdownMenuItem(value: specialty, child: Text(specialty)))
              .toList(),
          onChanged: (value) => setState(() => selectedSpecialty = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedGroup,
          decoration: const InputDecoration(labelText: 'Group'),
          items: widget.groups
              .map((group) => DropdownMenuItem(value: group, child: Text(group)))
              .toList(),
          onChanged: (value) => setState(() => selectedGroup = value),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _createSession,
          child: const Text('Start Session'),
        ),
      ],
    );
  }
}