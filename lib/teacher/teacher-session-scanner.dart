import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;

enum DetectionStatus { noFace, fail, success }

class CameraScreen extends StatefulWidget {
  final String teacherId;

  const CameraScreen({super.key, required this.teacherId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Map<String, dynamic>? sessionData; // Passed from the previous page
  CameraController? controller;
  List<Map<String, dynamic>> presentStudents = [];
  late WebSocketChannel channel;
  Timer? _timer;
  late String sessionId; // Session ID
  bool isFrontCamera = true; // Track front/back camera
  late CameraDescription frontCamera;
  late CameraDescription backCamera;
  bool isInitializing = true;
  late String sessionKey;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sessionData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (sessionData != null) {
      sessionKey = "${sessionData!['year']}-${sessionData!['specialty']}-${sessionData!['group']}";
      sessionId = sessionData!['session_id']; // Extract session ID
      initializeWebSocket();
    }
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    backCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);

    controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();
    setState(() => isInitializing = false); // Set to false after initialization
  }

  void startImageCapture() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !(controller?.value.isInitialized ?? false)) {
        print("<DEBUG> Camera controller is not initialized or widget is disposed.");
        return;
      }

      // Capture image
      print("<DEBUG> Capturing image...");
      try {
        final image = await controller!.takePicture();

        // Prepare image for sending
        final originalBytes = File(image.path).readAsBytesSync();
        final decodedImage = img.decodeImage(originalBytes);
        if (decodedImage == null) {
          print("<ERROR> Failed to decode image.");
          return;
        }

        final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);
        final grayscaleImage = img.grayscale(resizedImage);
        final compressedBytes = img.encodeJpg(grayscaleImage, quality: 50);

        final base64Image = base64.encode(compressedBytes);
        final jsonPayload = jsonEncode({
          'img': base64Image,
          'session_key': sessionKey,
        });

        channel.sink.add(jsonPayload);

        print("<DEBUG> Image sent to WebSocket.");
      } catch (e) {
        print("<ERROR> Failed to capture or process image: $e");
      }
    });
  }

  void initializeWebSocket() async {
    try {
      if (sessionData == null) {
        // Retrieve session details and ID from the route arguments
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('session_id')) {
          throw Exception("Session details not provided or missing session ID.");
        }
        sessionData = args; // Store session details
      }

      print("<DEBUG> Connecting to WebSocket...");
      channel = IOWebSocketChannel.connect(dotenv.env['WEBSOCKET_URL']!);

      String sessionKey = "${sessionData!['year']}-${sessionData!['specialty']}-${sessionData!['group']}";
      String sessionId = sessionData!['session_id']; // Extract session ID

      // Send session details and ID to WebSocket
      channel.sink.add(jsonEncode({
        'type': 'scan',
        'session_key': sessionKey,
        'session_id': sessionId, // Ensure session_id is passed
        'year': sessionData!['year'],
        'specialty': sessionData!['specialty'],
        'group': sessionData!['group'],
      }));

      print("<DEBUG> WebSocket connection established and data sent.");

      channel.stream.listen((data) {
        handleWebSocketResponse(data);
      }, onError: (error) {
        print("<WEBSOCKET> Error: $error");
      }, onDone: () {
        print("<WEBSOCKET> Connection Closed.");
      });

      Future.delayed(const Duration(seconds: 2), startImageCapture);
    } catch (e) {
      print("<WEBSOCKET> Initialization Error: $e");
    }
  }

  void handleWebSocketResponse(dynamic data) {
    try {
      final response = jsonDecode(data);

      if (response['status'] == true) {
        final name = response['name'];
        final userId = response['id'];

        if (name != null && userId != null) {
          if (!presentStudents.any((student) => student['user_id'] == userId)) {
            presentStudents.add({'user_id': userId, 'name': name});
            saveAttendance(userId, name);
            print("<DEBUG> User Detected: $name");

            // Show toast bar with the detected username and user image
            showToast(name, userId);
          }
        }
      } else {
        print("<DEBUG> Face not recognized.");
      }
    } catch (e) {
      print("<WEBSOCKET> Error processing response: $e");
    }
  }

  void showToast(String username, String userId) async {
    // Show the SnackBar at the top of the screen, below the AppBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green, // Background color
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Row(
            children: [
              // Confirmation Icon
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 40, // Larger icon
              ),
              const SizedBox(width: 16), // Spacing between icon and text
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Text
                    Text(
                      'Detected: $username',
                      style: const TextStyle(
                        fontSize: 18, // Larger font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4), // Small spacing
                    // Subtitle Message
                    const Text(
                      'Attendance set to present',
                      style: TextStyle(
                        fontSize: 14, // Smaller font size
                        color: Colors.white70, // Slightly transparent
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2), // Disappears after 2 seconds
        backgroundColor: Colors.transparent, // Make SnackBar background transparent
        elevation: 0, // Remove shadow
        behavior: SnackBarBehavior.floating, // Makes it float above the content
        margin: const EdgeInsets.only(
          top: kToolbarHeight + 10, // Position below the AppBar
          left: 20.0,
          right: 20.0,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // No border radius (handled by the container)
        ),
      ),
    );
  }

  void printPresentStudents() {
    print("<PRESENTSTUDENTS> ${jsonEncode(presentStudents)}");
  }

  Future<void> saveAttendance(String userId, String name) async {
    try {
      if (sessionData == null) throw Exception("Session data is missing");

      await Supabase.instance.client.from('Attendance').insert({
        'student_id': userId,
        'session_id': sessionData!['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'present',
      });

      print("<ATTENDANCE> Saved presence for $name");
    } catch (e) {
      print("<ATTENDANCE> Failed to save presence for $name: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to stop image capture
    controller?.dispose(); // Dispose the camera controller
    channel.sink.close(); // Close the WebSocket connection
    super.dispose();
  }

  Future<void> _confirmEndSession() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Session'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to end the session?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('End Session'),
              onPressed: () async {
                try {
                  // Get session ID from the route arguments
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  if (args != null && args.containsKey('session_id')) {
                    final sessionId = args['session_id'];

                    // Update end_time and set status to "inactive"
                    await Supabase.instance.client
                        .from('Sessions')
                        .update({
                      'end_time': DateTime.now().toIso8601String(),
                      'status': 'inactive', // Set status to "inactive"
                    })
                        .eq('id', sessionId);

                    print('<DEBUG> Session $sessionId ended, end_time and status updated.');
                  } else {
                    print('<ERROR> No session_id found to update end_time and status.');
                  }

                  // Close the dialog and navigate back
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Navigate back to the previous screen
                  printPresentStudents(); // Print attendance
                } catch (e) {
                  print('<ERROR> Failed to update session end_time and status: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Row(
          children: [
            Icon(Icons.live_tv, color: Colors.white), // Live icon
            SizedBox(width: 8),
            Text('Live Session', style: TextStyle(color: Colors.white)),
          ],
        ),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
          Positioned(
            top: 10, // Position the toast at the top of the camera session
            left: 10,
            right: 10,
            child: Container(), // Placeholder for toast
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: _confirmEndSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue button
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Bigger button
                ),
                child: const Text(
                  "End Session",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}