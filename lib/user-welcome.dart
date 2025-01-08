import 'dart:math';
import 'package:flutter/material.dart';
import 'package:identifyer/user-authentification.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with scattered circles
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Light gray background
            ),
            child: CustomPaint(
              size: Size.infinite, // Cover the entire screen
              painter: _CircleBackgroundPainter(),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo
                Hero(
                  tag: 'appLogo', // Unique tag for the hero animation
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png', // Replace with your app's logo asset
                      width: 160,
                      height: 160,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                const Text(
                  'Identifyer',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2), // Bright blue for the text
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Tagline
                const Text(
                  'Attendance made easier',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF757575), // Light gray for the tagline
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (_, __, ___) => const AuthentificationPage(),
                        transitionsBuilder: (_, animation, __, child) {
                          const begin = Offset(-1.0, 0.0); // Slide from the left
                          const end = Offset.zero; // Destination
                          const curve = Curves.ease;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2), // Matching blue
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scattered circles background
class _CircleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2).withOpacity(0.3) // Matching blue with higher opacity
      ..style = PaintingStyle.fill;

    final random = Random();

    // Draw 10 scattered circles with random positions and sizes
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width; // Random X position
      final y = random.nextDouble() * size.height; // Random Y position
      final radius = 20 + random.nextDouble() * 80; // Random radius between 20 and 100

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}