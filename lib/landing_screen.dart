import 'package:flutter/material.dart';
import 'sign_up.dart'; // Import the sign-up screen

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Logo
          Positioned(
            top: 61,
            left: 13,
            child: Image.asset(
              'assets/logo_remove.png',
              width: 402,
              height: 402,
            ),
          ),

          // Logo Text
          Positioned(
            top: 338,
            left: 61,
            child: Image.asset(
              'assets/logo_text_r.png',
              width: 305,
              height: 156,
            ),
          ),

          // "Meet Your AI Stylist" Text
          Positioned(
            top: 494,
            left: MediaQuery.of(context).size.width * 0.5 - 194,
            child: const SizedBox(
              width: 388,
              child: Text(
                'Meet your AI Stylist & Local fashion destination',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  letterSpacing: -0.02,
                  color: Color(0xB8000000),
                  fontFamily: 'Archivo',
                ),
              ),
            ),
          ),

          // Continue with Google Button
          Positioned(
            top: 668,
            left: 37,
            child: SizedBox(
              width: 353,
              height: 54,
              child: ElevatedButton.icon(
                icon: Image.asset('assets/google.png', width: 24, height: 24),
                label: const Text("Continue with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // Handle Google login
                },
              ),
            ),
          ),

          // Continue with Email Button (Navigates to SignUpScreen)
          Positioned(
            top: 735,
            left: 37,
            child: SizedBox(
              width: 353,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.email, color: Colors.black), // Email icon
                label: const Text("Continue with Email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()), // Navigate
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
