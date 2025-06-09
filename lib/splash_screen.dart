import 'dart:async';
import 'package:flutter/material.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to landing screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LandingScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_remove.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/logo_text_r.png',
              width: 200,
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
} 