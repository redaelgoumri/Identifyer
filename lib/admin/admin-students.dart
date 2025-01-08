import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({Key? key}) : super(key: key);

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];

  String? selectedYear;
  String? selectedSpecialty;
  String? selectedGroup;
  String? selectedGender;

  final List<String> specialties = ['IIR', 'GF', 'GI', 'GC', 'IAII', 'GESI'];
  final List<String> groups = List.generate(13, (index) => 'G${index + 1}');
  final List<String> genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  /// Saves a student to the database
  /// If [isUpdate] is `true`, updates the existing student record
  Future<void> saveStudent(Map<String, dynamic> student, {bool isUpdate = false}) async {
    try {
      print('<DEBUG> Student Data: $student');

      if (student['first_name'] == null || student['last_name'] == null || student['year'] == null) {
        throw Exception("Required student details are missing.");
      }

      if (student['selectedImage'] == null) {
        throw Exception("No image selected for embedding.");
      }

      String studentId;

      if (isUpdate) {
        studentId = student['id'];
        print('<DEBUG> Updating existing student...');
        await Supabase.instance.client
            .from('Students')
            .update({
          'first_name': student['first_name'],
          'last_name': student['last_name'],
          'year': student['year'],
          'specialty': student['specialty'],
          'group': student['group'],
          'phone': student['phone'],
          'email': student['email'],
          'isMale': student['isMale'],
        }).eq('id', studentId);
      } else {
        final response = await Supabase.instance.client
            .from('Students')
            .insert({
          'first_name': student['first_name'],
          'last_name': student['last_name'],
          'year': student['year'],
          'specialty': student['specialty'],
          'group': student['group'],
          'phone': student['phone'],
          'email': student['email'],
          'isMale': student['isMale'],
        }).select();

        if (response.isNotEmpty) {
          studentId = response.first['id'];
          print('<DEBUG> Student inserted with ID: $studentId');
        } else {
          throw Exception("Failed to insert student.");
        }
      }

      await generateEmbeddings(student['selectedImage'], studentId);
      print('<DEBUG> Image sent for embedding.');

      final uploadSuccess = await uploadImageToStorage(student['selectedImage'], {
        ...student,
        'id': studentId
      });

      if (!uploadSuccess) {
        print('<ERROR> Image upload failed.');
      } else {
        print('<DEBUG> Image uploaded successfully.');
      }

      fetchStudents();
    } catch (e) {
      print('<ERROR> Error saving student: $e');
    }
  }







  Future<void> deleteStudent(String id) async {
    try {
      print('<DEBUG> Attempting to delete student with ID: $id');

      // Fetch the student record to get details for image path
      final response = await Supabase.instance.client
          .from('Students')
          .select('year, specialty, group, last_name, first_name')
          .eq('id', id)
          .single();

      final student = response;
      final fileName = "${student['year']}-${student['specialty']}-${student['group']}-${student['last_name']}-${student['first_name']}.jpg";

      // Attempt to delete the image from storage
      final deleteResponse = await Supabase.instance.client.storage
          .from('studentinformation')
          .remove([fileName]);

      print('<ERROR> Failed to delete image from storage: ${deleteResponse}');

      // Delete the student record from the database
      await Supabase.instance.client
          .from('Students')
          .delete()
          .eq('id', id);

      print('<DEBUG> Student record deleted from database.');
      fetchStudents();
    } catch (e) {
      print('<ERROR> Error deleting student: $e');
    }
  }




  Future<void> fetchStudents() async {
    setState(() {});

    try {
      final response = await Supabase.instance.client
          .from('Students')
          .select(
          'id, first_name, last_name, year, specialty, group, email, phone, isMale, created_at') // List all fields except embeddings
          .order('created_at', ascending: false);

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _filteredStudents = _students;
      });
    } catch (e) {
      print('<DEBUG> Error fetching students: $e');
    } finally {
      setState(() {});
    }
  }

  void applyFilters() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final yearMatch =
            selectedYear == null || student['year']?.toString() == selectedYear;
        final specialtyMatch = selectedSpecialty == null ||
            student['specialty'] == selectedSpecialty;
        final groupMatch =
            selectedGroup == null || student['group'] == selectedGroup;
        final genderMatch = selectedGender == null ||
            (student['isMale'] == true ? 'Male' : 'Female') == selectedGender;

        return yearMatch && specialtyMatch && groupMatch && genderMatch;
      }).toList();
    });
  }

  void clearFilters() {
    setState(() {
      selectedYear = null;
      selectedSpecialty = null;
      selectedGroup = null;
      selectedGender = null;
      _filteredStudents = _students;
    });
  }

  Future<void> _refreshData() async {
    await fetchStudents();
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    final gender = student['isMale'] == true ? 'Male' : 'Female';
    final imageName =
        '${student['year']}-${student['specialty']}-${student['group']}-${student['last_name']}-${student['first_name']}.jpg';
    final imageUrl =
        Supabase.instance.client.storage.from('studentinformation').getPublicUrl(imageName);

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
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: NetworkImage(imageUrl),
                  onBackgroundImageError: (_, __) => const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${student['first_name']} ${student['last_name']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
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
                  title: Text('${student['year']}'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text('Specialty: ${student['specialty']}'),
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: Text('Group: ${student['group']}'),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('Gender: $gender'),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text('Email: ${student['email'] ?? 'N/A'}'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text('Phone: ${student['phone'] ?? 'N/A'}'),
                ),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: Text('Created At: ${student['created_at']}'),
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








////////////////////////////////////////////////////////






  void _showEditStudentModal(BuildContext context, Map<String, dynamic>? student) {
    final _formKey = GlobalKey<FormState>(); // Form key for validation
    final firstNameController = TextEditingController(text: student?['first_name']);
    final lastNameController = TextEditingController(text: student?['last_name']);
    final phoneController = TextEditingController(text: student?['phone']);
    final emailController = TextEditingController(text: student?['email']);
    bool isMale = student?['isMale'] ?? true;
    String? selectedYear = student?['year']?.toString();
    String? selectedSpecialty = student?['specialty'];
    String? selectedGroup = student?['group'];
    File? selectedImage;
    String? currentImageUrl;

    if (student != null) {
      final imageName = '${student['year']}-${student['specialty']}-${student['group']}-${student['last_name']}-${student['first_name']}.jpg';
      currentImageUrl = Supabase.instance.client.storage
          .from('studentinformation')
          .getPublicUrl(imageName);
      print('<DEBUG> Current image URL for student: $currentImageUrl');
    }

    Future<void> pickOrTakePicture(StateSetter setModalState) async {
      final ImagePicker picker = ImagePicker();
      XFile? image;

      await showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Picture'),
                  onTap: () async {
                    image = await picker.pickImage(source: ImageSource.camera);
                    Navigator.of(ctx).pop();

                    if (image != null) {
                      print('<DEBUG> Picture taken from camera: ${image?.path}');
                      setModalState(() {
                        selectedImage = File(image!.path);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    image = await picker.pickImage(source: ImageSource.gallery);
                    Navigator.of(ctx).pop();

                    if (image != null) {
                      print('<DEBUG> Picture selected from gallery: ${image?.path}');
                      setModalState(() {
                        selectedImage = File(image!.path);
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                        student == null ? 'Add Student' : 'Edit Student',
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

                      // Phone Field
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^\+?[0-9]+$').hasMatch(value)) {
                              return 'Phone must contain only numbers and optionally start with +';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Email Field
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email (Optional)'),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Invalid email format';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Year Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: List.generate(5, (index) => '${index + 1}')
                            .map((year) =>
                            DropdownMenuItem(value: year, child: Text(year)))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedYear = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Year is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Specialty Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedSpecialty,
                        decoration: const InputDecoration(labelText: 'Specialty'),
                        items: ['IIR', 'GF', 'GI', 'GC', 'IAII', 'GESI']
                            .map((specialty) =>
                            DropdownMenuItem(value: specialty, child: Text(specialty)))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedSpecialty = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Specialty is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Group Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedGroup,
                        decoration: const InputDecoration(labelText: 'Group'),
                        items: List.generate(13, (index) => 'G${index + 1}')
                            .map((group) =>
                            DropdownMenuItem(value: group, child: Text(group)))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedGroup = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Group is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image Picker
                      GestureDetector(
                        onTap: () => pickOrTakePicture(setModalState),
                        child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : currentImageUrl != null
                                ? Image.network(currentImageUrl, fit: BoxFit.cover)
                                : const Center(
                              child: Text('Tap to add/select a picture'),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Save Button
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print('<DEBUG> Attempting to save student...');
                            final updatedStudent = {
                              'first_name': firstNameController.text,
                              'last_name': lastNameController.text,
                              'year': int.tryParse(selectedYear ?? '0'),
                              'specialty': selectedSpecialty,
                              'group': selectedGroup,
                              'phone': phoneController.text,
                              'email': emailController.text,
                              'isMale': isMale,
                              'selectedImage': selectedImage,
                              if (student != null) 'id': student['id'],
                            };

                            saveStudent(updatedStudent, isUpdate: student != null);
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
      },
    );
  }







////////////////////////////////////////////////////////









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

  Future<bool> uploadImageToStorage(File imageFile, Map<String, dynamic> student) async {
    try {
      final fileName =
          "${student['year']}-${student['specialty']}-${student['group']}-${student['last_name']}-${student['first_name']}.jpg";

      final bytes = await imageFile.readAsBytes();

      await Supabase.instance.client.storage
          .from('studentinformation')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

      print('<DEBUG> Image uploaded to storage: $fileName');
      return true;
    } catch (e) {
      print('<ERROR> Failed to upload image to storage: $e');
      return false;
    }
  }





  Future<void> generateEmbeddings(File imageFile, String studentId) async {
    try {
      print('<DEBUG> Connecting to WebSocket for embeddings...');

      // Generate a unique session_id for embeddings
      final String sessionId = const Uuid().v4();
      print('<DEBUG> Generated session ID for embedding: $sessionId');

      // Connect using WebSocket URL from environment variables
      final channel = IOWebSocketChannel.connect(dotenv.env['WEBSOCKET_URL']!);
      print('<DEBUG> WebSocket connection established.');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send image, student ID, and session ID to WebSocket
      channel.sink.add(jsonEncode({
        'type': 'embedding',
        'img': base64Image,
        'student_id': studentId,
        'session_id': sessionId,  // Add session_id for consistency
      }));

      print('<DEBUG> Image sent for embedding with session ID: $sessionId. Closing WebSocket.');

      // Close WebSocket after sending
      channel.sink.close();

    } catch (e) {
      print('<ERROR> WebSocket connection error: $e');
    }
  }









void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> student) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student['first_name']} ${student['last_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteStudent(student['id']);  // Pass student object
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.add, color: Colors.blue, size: 40),
                    title: const Text(
                      'Add Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    subtitle: const Text('Tap to add a new student'),
                    onTap: () {
                      _showEditStudentModal(context, null);
                    },
                  ),

                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        'Filter Students', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.blue),
                          onPressed: () {
                            _showFilterDialog(
                              context: context,
                              title: 'Year',
                              options: List.generate(5, (index) => '${index + 1}'),
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
                          icon: const Icon(Icons.person, color: Colors.blue),
                          onPressed: () {
                            _showFilterDialog(
                              context: context,
                              title: 'Gender',
                              options: genders,
                              selectedValue: selectedGender,
                              onSelected: (value) {
                                setState(() {
                                  selectedGender = value;
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
                  ],
                ),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    final imageName = '${student['year']}-${student['specialty']}-${student['group']}-${student['last_name']}-${student['first_name']}.jpg';
                    final imageUrl = Supabase.instance.client.storage.from('studentinformation').getPublicUrl(imageName);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.blue),
                          radius: 20,
                        ),
                        title: Text(
                          '${student['first_name']} ${student['last_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${student['year']}-${student['specialty']}-${student['group']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                _showEditStudentModal(context, student);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, student);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _showStudentDetails(context, student);
                        },
                      ),
                    );
                  },
                )
            ],
            ),
          ),
        ),
      ),
    );
  }



}
