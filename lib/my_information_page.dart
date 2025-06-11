// lib/my_information_page.dart

import 'package:flutter/material.dart';
import 'services/profile_service.dart';

class MyInformationPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String token;

  const MyInformationPage({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  _MyInformationPageState createState() => _MyInformationPageState();
}

class _MyInformationPageState extends State<MyInformationPage> {
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName ?? '');
    _phoneController = TextEditingController(text: widget.userPhone ?? '');
    _emailController = TextEditingController(text: widget.userEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'))
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final profileService = ProfileService(token: widget.token);
      final updatedProfile = await profileService.updateUserInfo(
        name: name,
        phone: phone,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      print('Error updating user info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating information'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "My Information",
          style: TextStyle(
            fontFamily: 'Archivo',
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: "Full Name",
                  controller: _nameController,
                  hintText: "",
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: "Email",
                  controller: _emailController,
                  hintText: "Email address",
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: "Phone Number",
                  controller: _phoneController,
                  hintText: "Enter phone number",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveUserInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD55F5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
