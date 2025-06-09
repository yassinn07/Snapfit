import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'log_in.dart'; // Assuming this is your login screen
import 'config.dart'; // Your API config

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _userType;
  String? _gender;
  String? _size;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _userTypes = ['Consumer', 'Brand'];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill all required fields: Username, Email, and Password.');
      return;
    }

    if (_userType == null) {
      _showErrorDialog('Please select a user type (Consumer or Brand).');
      return;
    }

    // Specific field validation for consumer
    if (_userType == 'Consumer') {
      if (_size == null || _size!.isEmpty) {
        _showErrorDialog('Please select your size.');
        return;
      }
      if (_gender == null || _gender!.isEmpty) {
        _showErrorDialog('Please select your gender.');
        return;
      }
    }

    // Specific field validation for brand
    if (_userType == 'Brand') {
      if (_descriptionController.text.trim().isEmpty) {
        _showErrorDialog('Please enter a brand description.');
        return;
      }
    }


    final String url;
    final Map<String, String> body;

    if (_userType == 'Consumer') {
      url = '${Config.baseUrl}/users/consumer-create';
      body = {
        'email': email,
        'password': password,
        'username': username, // FastAPI endpoint expects 'username' from schema
        'size': _size ?? '',   // Backend Pydantic schema should handle '' if it's nullable or expects string
        'gender': _gender ?? '', // Same as above
      };
    } else { // Brand
      url = '${Config.baseUrl}/users/brand-create';
      body = {
        'email': email,
        'password': password,
        'username': username, // FastAPI endpoint expects 'username' from schema
        'description': _descriptionController.text.trim(),
      };
    }

    // Show loading indicator option
    // setState(() { _isLoading = true; }); // You'd need to define _isLoading

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // Added charset
        body: json.encode(body),
      );

      // setState(() { _isLoading = false; }); // Hide loading

      if (response.statusCode == 201) {
        // Success - navigate to login screen
        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful! Please log in.'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Handle error
        final responseBody = response.body;
        String errorMessage = 'Signup failed. Status code: ${response.statusCode}';
        try {
          final errorData = json.decode(responseBody);
          // FastAPI error responses usually have a "detail" field
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'] is List ? (errorData['detail'] as List).join(', ') : errorData['detail'].toString();
          } else if (errorData['message'] != null) { // Fallback for other error structures
            errorMessage = errorData['message'].toString();
          } else {
            errorMessage = 'Signup failed: $responseBody';
          }
        } catch (e) {
          // If response.body is not a valid JSON or doesn't have 'detail'/'message'
          errorMessage = 'Signup failed: $responseBody (Could not parse error details)';
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // setState(() { _isLoading = false; }); // Hide loading
      _showErrorDialog('An error occurred: ${e.toString()}. Please check your connection and try again.');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return; // Check if the widget is still in the tree
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/logo_small.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32, // Slightly adjusted for typical screen density
                    fontFamily: 'Archivo', // Ensure this font is included in pubspec.yaml
                    letterSpacing: -0.02,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                // User Type Dropdown
                const Text("I am a...", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _userType,
                  items: _userTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _userType = newValue;
                      // Reset conditional fields if user type changes
                      if (newValue == 'Consumer') {
                        _descriptionController.clear();
                      } else if (newValue == 'Brand') {
                        _size = null;
                        _gender = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Select user type",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value == null ? 'Please select a user type' : null,
                ),
                const SizedBox(height: 20),
                const Text("Username", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Choose a username",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Email", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "your.email@example.com",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Password", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Create a strong password",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),

                // Conditional fields based on user type
                if (_userType == 'Consumer') ...[
                  const Text("Size", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _size,
                    items: _sizes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _size = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select your clothing size",
                      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) => _userType == 'Consumer' && value == null ? 'Please select your size' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: _genders.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _gender = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select your gender",
                      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) => _userType == 'Consumer' && value == null ? 'Please select your gender' : null,
                  ),
                  const SizedBox(height: 20),
                ] else if (_userType == 'Brand') ...[
                  const Text("Brand Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Tell us about your brand",
                      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 30), // Increased spacing before button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Use backgroundColor for newer Flutter versions
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _signUp, // Assuming _isLoading is false or handled
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Adjusted spacing
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement( // Use pushReplacement if you don't want to come back to signup
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
                        children: const [
                          TextSpan(
                            text: "Log In",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.black, // Make it stand out a bit more
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}