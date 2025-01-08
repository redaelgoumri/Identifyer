import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:identifyer/admin/admin-dashboard.dart';
import 'package:identifyer/teacher/teacher-dashboard.dart';
import 'package:identifyer/user-authentification.dart';
import 'package:identifyer/teacher/teacher-session-scanner.dart';
import 'package:identifyer/user-welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';




Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  String URL = dotenv.env['SUPABASE_URL']!;
  String KEY = dotenv.env['SUPABASE_KEY']!;

  await Supabase.initialize(
    url: URL,
    anonKey: KEY,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Identifyer',
      initialRoute: '/', // Set the Welcome Page as the initial route
      theme: ThemeData(
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const WelcomePage(), // Welcome Page
        '/login': (context) => const AuthentificationPage(), // Login Page
        '/teacherDashboard': (context) => const TeacherDashboardPage(teacherId: '',), // Session Details
        '/adminDashboard': (context) => const AdminDashboardPage(), // Admin Dashboard
        '/scanning': (context) => const CameraScreen(teacherId: '',), // Ensure this matches
      },
    );
  }
}
