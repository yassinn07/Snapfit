import 'package:flutter/material.dart';
import 'sign_up.dart'; // Import the SignUpScreen
import 'home_screen.dart'; // Import the HomeScreen

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensuring white background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo_small.png',
              width: 80,
              height: 80,
            ),

            SizedBox(height: 20),

            // Login Title
            Text(
              "Log in",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.02,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 10),

            // Email Input
            TextField(
              decoration: InputDecoration(
                labelText: "Your email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            SizedBox(height: 15),

            // Password Input
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            SizedBox(height: 10),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle forgot password action
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Log in",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // OR Login With
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Or Login with",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey)),
              ],
            ),

            SizedBox(height: 20),

            // Google Login Button (Wide)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Google login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background for Google button
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.black), // Border to make it visible
                  ),
                  elevation: 3, // Light shadow for effect
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/google.png', // Google logo
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40),

            // Sign Up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
