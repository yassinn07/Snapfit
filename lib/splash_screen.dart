import 'dart:async';
import 'package:flutter/material.dart';
import 'landing_screen.dart';
import 'log_in.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash for 1 second, then go to login
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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