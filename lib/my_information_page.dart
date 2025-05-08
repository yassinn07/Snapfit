// lib/my_information_page.dart

import 'package:flutter/material.dart';

class MyInformationPage extends StatelessWidget {
  // Receive user data from ProfilePage
  final String userName;
  final String userEmail;
  final String userPhone; // Assuming phone number is available

  const MyInformationPage({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white, // Consistent background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "My Information",
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoField(
              label: "Name",
              value: userName,
              fontFamily: defaultFontFamily,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              label: "Email Address",
              value: userEmail,
              fontFamily: defaultFontFamily,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              label: "Phone Number",
              value: userPhone, // Display phone number
              fontFamily: defaultFontFamily,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 40),
            // Edit Button (Placeholder)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to an edit information page or enable editing here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit functionality not implemented yet.')),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Edit Information"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50), // Adjust size as needed
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: defaultFontFamily,
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

  // Helper widget to display information fields consistently
  Widget _buildInfoField({
    required String label,
    required String value,
    required String fontFamily,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EE), // Match preference box color
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                    letterSpacing: -0.02 * 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    letterSpacing: -0.02 * 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
