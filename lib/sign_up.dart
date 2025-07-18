import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'log_in.dart'; // Assuming this is your login screen
import 'config.dart'; // Your API config
import 'constants.dart' show showThemedSnackBar;

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

  Future<bool> _isUsernameTaken(String username) async {
    final url = '${Config.baseUrl}/users/check-username/$username';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
    } catch (e) {}
    return false; // Assume not taken if error
  }

  bool _isValidPassword(String password) {
    // At least 8 chars, at least one letter and one number
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return regex.hasMatch(password);
  }

  bool _isValidEmail(String email) {
    // General email validation regex
    final regex = RegExp(r'^\S+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showThemedSnackBar(context, 'Please fill all required fields: Username, Email, and Password.', type: 'critical');
      return;
    }

    if (!_isValidEmail(email)) {
      showThemedSnackBar(context, 'Please enter a valid email address.', type: 'critical');
      return;
    }

    if (!_isValidPassword(password)) {
      showThemedSnackBar(context, 'Password: 8+ chars, letters & numbers.', type: 'critical');
      return;
    }

    if (await _isUsernameTaken(username)) {
      showThemedSnackBar(context, 'Username is already taken. Please choose another.', type: 'critical');
      return;
    }

    if (_userType == null) {
      showThemedSnackBar(context, 'Please select a user type (Consumer or Brand).', type: 'critical');
      return;
    }

    // Specific field validation for consumer
    if (_userType == 'Consumer') {
      if (_size == null || _size!.isEmpty) {
        showThemedSnackBar(context, 'Please select your size.', type: 'critical');
        return;
      }
      if (_gender == null || _gender!.isEmpty) {
        showThemedSnackBar(context, 'Please select your gender.', type: 'critical');
        return;
      }
    }

    // Specific field validation for brand
    if (_userType == 'Brand') {
      if (_descriptionController.text.trim().isEmpty) {
        showThemedSnackBar(context, 'Please enter a brand description.', type: 'critical');
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
          showThemedSnackBar(context, 'Signup successful! Please log in.', type: 'success');
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
        showThemedSnackBar(context, errorMessage, type: 'critical');
      }
    } catch (e) {
      // setState(() { _isLoading = false; }); // Hide loading
      showThemedSnackBar(context, 'An error occurred: ${e.toString()}. Please check your connection and try again.', type: 'critical');
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
    const String fontFamily = 'Archivo';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/logo_small.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: fontFamily,
                    letterSpacing: -0.02,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("I am a...", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _userType,
                        items: _userTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                              child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) => _userTypes.map((value) => Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                            child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                          ),
                        )).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _userType = newValue;
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
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) => value == null ? 'Please select a user type' : null,
                        dropdownColor: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 20),
                      const Text("Username", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: "Choose a username",
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(fontFamily: fontFamily),
                      ),
                      const SizedBox(height: 20),
                      const Text("Email", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "your.email@example.com",
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(fontFamily: fontFamily),
                      ),
                      const SizedBox(height: 20),
                      const Text("Password", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Create a strong password",
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(fontFamily: fontFamily),
                      ),
                      const SizedBox(height: 20),
                      if (_userType == 'Consumer') ...[
                        const Text("Size", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _size,
                          items: _sizes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (context) => _sizes.map((value) => Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                              child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                            ),
                          )).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _size = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Select your clothing size",
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) => _userType == 'Consumer' && value == null ? 'Please select your size' : null,
                          dropdownColor: Colors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(height: 20),
                        const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: _genders.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (context) => _genders.map((value) => Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                              child: Text(value, style: const TextStyle(fontFamily: fontFamily)),
                            ),
                          )).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Select your gender",
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) => _userType == 'Consumer' && value == null ? 'Please select your gender' : null,
                          dropdownColor: Colors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(height: 20),
                      ] else if (_userType == 'Brand') ...[
                        const Text("Brand Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: fontFamily)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Tell us about your brand",
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontFamily: fontFamily),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(fontFamily: fontFamily),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD55F5F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _signUp,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: fontFamily),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7), fontFamily: fontFamily),
                        children: const [
                          TextSpan(
                            text: "Log In",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.black,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}