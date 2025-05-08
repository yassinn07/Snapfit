import 'package:flutter/material.dart';
import 'log_in.dart'; // Import the login screen

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Align(
              alignment: Alignment.topRight,
              child: Image.asset(
                'assets/logo_small.png',
                width: 80,
                height: 80,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 35,
                fontFamily: 'Archivo',
                letterSpacing: -0.02,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Text("Username", style: TextStyle(fontSize: 14, color: Colors.black)),
            TextField(
              decoration: InputDecoration(
                hintText: "Your username",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            SizedBox(height: 20),
            Text("Email", style: TextStyle(fontSize: 14, color: Colors.black)),
            TextField(
              decoration: InputDecoration(
                hintText: "Your email",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            SizedBox(height: 20),
            Text("Password", style: TextStyle(fontSize: 14, color: Colors.black)),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Your password",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: 60),
            Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to Login Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
                    children: [
                      TextSpan(
                        text: "Log in",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
