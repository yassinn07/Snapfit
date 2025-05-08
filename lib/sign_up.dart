import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'log_in.dart';
import 'config.dart';


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
      _showErrorDialog('Please fill all required fields');
      return;
    }

    if (_userType == null) {
      _showErrorDialog('Please select a user type');
      return;
    }

    try {
      final url = _userType == 'Consumer'
          ? '${Config.baseUrl}/users/consumer-create'
          : '${Config.baseUrl}/users/brand-create';

      final body = _userType == 'Consumer'
          ? {
        'email': email,
        'password': password,
        'username': username,
        'size': _size ?? '',
        'gender': _gender ?? '',
      }
          : {
        'email': email,
        'password': password,
        'username': username,
        'description': _descriptionController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        // Success - navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Handle error
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'assets/logo_small.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 35,
                  fontFamily: 'Archivo',
                  letterSpacing: -0.02,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              // User Type Dropdown
              const Text("User Type", style: TextStyle(fontSize: 14, color: Colors.black)),
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
                  });
                },
                decoration: InputDecoration(
                  hintText: "Select your user type",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Username", style: TextStyle(fontSize: 14, color: Colors.black)),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Your username",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Email", style: TextStyle(fontSize: 14, color: Colors.black)),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Your email",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Password", style: TextStyle(fontSize: 14, color: Colors.black)),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Your password",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Conditional fields based on user type
              if (_userType == 'Consumer') ...[
                const Text("Size", style: TextStyle(fontSize: 14, color: Colors.black)),
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
                    hintText: "Select your size",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Gender", style: TextStyle(fontSize: 14, color: Colors.black)),
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
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_userType == 'Brand') ...[
                const Text("Description", style: TextStyle(fontSize: 14, color: Colors.black)),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Brand description",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _signUp,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      ),
    );
  }
}