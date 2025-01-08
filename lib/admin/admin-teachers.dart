import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart'; // For loading shimmer effect

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  bool _isLoading = true;
  String? selectedModule;

  final List<String> modules = [
    "Networking Fundamentals",
    "Data Communication",
    "Operating Systems",
    "Database Management",
    "Cybersecurity",
    "Cloud Computing",
    "Mobile Development",
    "AI Fundamentals",
    "Software Engineering",
    "Web Development",
    "Big Data",
    "Internet of Things (IoT)",
    "Embedded Systems",
    "Virtualization",
    "Project Management",
  ];

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> _confirmDeletion(BuildContext context, Map<String, dynamic> teacher) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${teacher['first_name']} ${teacher['last_name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _deleteTeacher(teacher['id']);
    }
  }

  /// Fetch teachers from the database
  Future<void> fetchTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('User')
          .select('id, first_name, last_name, module, email, passkey, created_at')
          .order('created_at', ascending: false);

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
        _filteredTeachers = _teachers; // Initialize with all teachers
      });
    } catch (e) {
      print('<DEBUG> Error fetching teachers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Filter teachers by module
  void applyFilters() {
    setState(() {
      _filteredTeachers = _teachers.where((teacher) {
        final moduleMatch = selectedModule == null || teacher['module'] == selectedModule;
        return moduleMatch;
      }).toList();
    });
  }

  /// Clear filters
  void clearFilters() {
    setState(() {
      selectedModule = null;
      _filteredTeachers = _teachers;
    });
  }

  /// Save teacher (Insert or Update)
  Future<void> saveTeacher(Map<String, dynamic> teacher, {bool isUpdate = false}) async {
    try {
      if (isUpdate) {
        await Supabase.instance.client
            .from('User')
            .update({
          'first_name': teacher['first_name'],
          'last_name': teacher['last_name'],
          'module': teacher['module'],
          'email': teacher['email'],
          'passkey': teacher['passkey'],
        })
            .eq('id', teacher['id']);
      } else {
        await Supabase.instance.client.from('User').insert({
          'first_name': teacher['first_name'],
          'last_name': teacher['last_name'],
          'module': teacher['module'],
          'email': teacher['email'],
          'passkey': teacher['passkey'],
        });
      }

      fetchTeachers(); // Refresh the teacher list
    } catch (e) {
      print('<DEBUG> Error saving teacher: $e');
    }
  }

  /// Delete teacher
  Future<void> _deleteTeacher(String id) async {
    try {
      await Supabase.instance.client.from('User').delete().eq('id', id);
      await fetchTeachers(); // Refresh the teacher list
    } catch (e) {
      _showErrorDialog(context, 'Deletion Failed', 'This teacher cannot be deleted due to existing references in other records.');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String generateRandomPasskey({int length = 5}) {
    const String upperCaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String allCharacters = '$upperCaseLetters';
    final Random random = Random.secure();

    return List<String>.generate(length, (index) {
      return allCharacters[random.nextInt(allCharacters.length)];
    }).join('');
  }

  /// Show edit/add teacher modal
  void _showEditTeacherModal(BuildContext context, Map<String, dynamic>? teacher) {
    final _formKey = GlobalKey<FormState>(); // Form key for validation
    final firstNameController = TextEditingController(text: teacher?['first_name']);
    final lastNameController = TextEditingController(text: teacher?['last_name']);
    final emailController = TextEditingController(text: teacher?['email']);
    final passkeyController = TextEditingController(
      text: teacher?['passkey'] ?? generateRandomPasskey(),
    );
    String? moduleController = teacher?['module'];

    showModalBottomSheet(
      context: context,
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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey, // Assign the form key
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    teacher == null ? 'Add Teacher' : 'Edit Teacher',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // First Name Field
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First Name is required';
                      }
                      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                        return 'First Name must contain only alphabetic characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Last Name Field
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last Name is required';
                      }
                      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                        return 'Last Name must contain only alphabetic characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Module Dropdown
                  DropdownButtonFormField<String>(
                    value: moduleController,
                    decoration: const InputDecoration(labelText: 'Module'),
                    items: modules.map((module) {
                      return DropdownMenuItem(
                        value: module,
                        child: Text(module),
                      );
                    }).toList(),
                    onChanged: (value) {
                      moduleController = value;
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Module is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Passkey Field
                  TextFormField(
                    controller: passkeyController,
                    decoration: const InputDecoration(labelText: 'Passkey'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final Map<String, dynamic> updatedTeacher = {
                          'first_name': firstNameController.text,
                          'last_name': lastNameController.text,
                          'module': moduleController,
                          'email': emailController.text,
                          'passkey': passkeyController.text,
                          if (teacher != null) 'id': teacher['id'],
                        };
                        saveTeacher(updatedTeacher, isUpdate: teacher != null);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: fetchTeachers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Teacher Button
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.add, color: Colors.blue, size: 40),
                    title: const Text(
                      'Add Teacher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    subtitle: const Text('Tap to add a new teacher'),
                    onTap: () {
                      _showEditTeacherModal(context, null);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Section
                const Text(
                  'Filter Teachers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(selectedModule ?? 'Module'),
                      onSelected: (selected) {
                        _showFilterDialog(
                          context: context,
                          title: 'Module',
                          options: modules,
                          selectedValue: selectedModule,
                          onSelected: (value) {
                            setState(() {
                              selectedModule = value;
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

                // Teachers List
                _isLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Container(
                            height: 20,
                            width: 100,
                            color: Colors.white,
                          ),
                          subtitle: Container(
                            height: 16,
                            width: 150,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                )
                    : _filteredTeachers.isEmpty
                    ? const Center(
                  child: Text(
                    'No teachers found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _filteredTeachers[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text('${teacher['first_name']} ${teacher['last_name']}'),
                        subtitle: Text('Module » ${teacher['module']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                _showEditTeacherModal(context, teacher);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeletion(context, teacher),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                _showTeacherDetails(context, teacher);
                              },
                            ),
                          ],
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
}

/// View teacher details
void _showTeacherDetails(BuildContext context, Map<String, dynamic> teacher) {
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
              const Icon(Icons.person, size: 40, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                '${teacher['first_name']} ${teacher['last_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.school),
                title: Text('Module: ${teacher['module']}'),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text('Email: ${teacher['email']}'),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text('Passkey: ${teacher['passkey']}'),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text('Created At: ${teacher['created_at']}'),
              ),
            ],
          ),
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