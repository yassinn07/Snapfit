// lib/change_password_page.dart

import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitChangePassword() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement password change logic (API call, validation)
      print('Current Password: ${_currentPasswordController.text}');
      print('New Password: ${_newPasswordController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password change submitted (Placeholder)')),
      );
      // Optionally navigate back or clear fields
      // Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make button full width
            children: [
              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                labelText: "Current Password",
                fontFamily: defaultFontFamily,
                obscureText: _obscureCurrentPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  // TODO: Add more specific validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                labelText: "New Password",
                fontFamily: defaultFontFamily,
                obscureText: _obscureNewPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) { // Example length validation
                    return 'Password must be at least 8 characters';
                  }
                  // TODO: Add more password strength validation
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm New Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                labelText: "Confirm New Password",
                fontFamily: defaultFontFamily,
                obscureText: _obscureConfirmPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Save Password",
                  style: TextStyle(
                    fontFamily: defaultFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for password text fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required String fontFamily,
    required bool obscureText,
    required VoidCallback toggleObscure,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.black54,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: toggleObscure,
        ),
        // Consistent styling with other inputs if needed
        filled: true,
        fillColor: const Color(0xFFF6F1EE).withOpacity(0.5), // Light background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black), // Highlight focus
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
      ),
      style: TextStyle(fontFamily: fontFamily, fontSize: 16, color: Colors.black),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
