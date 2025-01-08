import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart'; // For loading shimmer effect

class AdminSessionsPage extends StatefulWidget {
  const AdminSessionsPage({Key? key}) : super(key: key);

  @override
  State<AdminSessionsPage> createState() => _AdminSessionsPageState();
}

class _AdminSessionsPageState extends State<AdminSessionsPage> {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  Map<String, Map<String, String>> _teacherDetails = {};
  bool _isLoading = true;

  String? selectedYear;
  String? selectedSpecialty;
  String? selectedGroup;

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
          .order('created_at', ascending: false);

      final sessions = List<Map<String, dynamic>>.from(sessionsResponse);

      final teacherIds = sessions.map((session) => session['teacher']).toSet();

      for (var teacherId in teacherIds) {
        if (teacherId != null && !_teacherDetails.containsKey(teacherId)) {
          final teacherResponse = await Supabase.instance.client
              .from('User')
              .select('first_name, last_name, module')
              .eq('id', teacherId)
              .single();

          final teacher = teacherResponse;
          _teacherDetails[teacherId] = {
            'name': "${teacher['last_name']} ${teacher['first_name']}",
            'module': teacher['module'] ?? 'Unknown Module',
          };
        }
      }

      setState(() {
        _sessions = sessions;
        _filteredSessions = _sessions;
      });
    } catch (e) {
      print('<DEBUG> Error fetching sessions: $e');
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
        final specialtyMatch = selectedSpecialty == null ||
            session['specialty'] == selectedSpecialty;
        final groupMatch =
            selectedGroup == null || session['group'] == selectedGroup;

        return yearMatch && specialtyMatch && groupMatch;
      }).toList();
    });
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

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session) {
    final teacherId = session['teacher'];
    final teacherName = _teacherDetails[teacherId]?['name'] ?? 'Unknown';
    final teacherModule = _teacherDetails[teacherId]?['module'] ?? 'Unknown Module';

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
                Text(
                  'Session Details',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text('Teacher: $teacherName'),
                subtitle: Text('Module: $teacherModule'),
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: Text('Year: ${session['year']}'),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: Text('Specialty: ${session['specialty']}'),
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: Text('Group: ${session['group']}'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.blue),
                title: Text('Time Span'),
                subtitle: Text(
                  '${session['start_time']} - ${session['end_time']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search sessions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filteredSessions = _sessions
                          .where((session) =>
                      session['teacher']
                          .toString()
                          .toLowerCase()
                          .contains(value.toLowerCase()) ||
                          session['specialty']
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filter Section
                const Text(
                  'Filter Sessions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(selectedYear ?? 'Year'),
                      onSelected: (selected) {
                        _showFilterDialog(
                          context: context,
                          title: 'Year',
                          options: List.generate(5, (index) => 'Year: ${index + 1}'),
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
                    FilterChip(
                      label: Text(selectedSpecialty ?? 'Specialty'),
                      onSelected: (selected) {
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
                    FilterChip(
                      label: Text(selectedGroup ?? 'Group'),
                      onSelected: (selected) {
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

                // Sessions Grid
                _isLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                )
                    : _filteredSessions.isEmpty
                    ? const Center(
                  child: Text(
                    'No sessions found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = _filteredSessions[index];
                    final teacherId = session['teacher'];
                    final teacherName =
                        _teacherDetails[teacherId]?['name'] ?? 'Unknown';
                    final teacherModule =
                        _teacherDetails[teacherId]?['module'] ?? 'Unknown Module';
                    return GestureDetector(
                      onTap: () => _showSessionDetails(context, session),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade100, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                specialtyIcons[session['specialty']] ??
                                    Icons.info,
                                size: 40,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                teacherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Module » $teacherModule',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Class » ${session['year']}-${session['specialty']}-${session['group']}',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
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
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}