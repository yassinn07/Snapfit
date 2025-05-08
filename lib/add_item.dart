// lib/add_item.dart

import 'package:flutter/material.dart';
// Import the image_picker package
import 'package:image_picker/image_picker.dart';
// import 'dart:io'; // Import 'dart:io' if you need to use File() for previews

class AddItemPage extends StatelessWidget {
  // *** FIX: Remove the non-constant instance field ***
  // final ImagePicker picker = ImagePicker(); // REMOVED THIS LINE

  // Ensure the constructor remains const
  const AddItemPage({super.key});

  // --- Action Handlers ---

  // Picks an image from the gallery
  Future<void> _onChoosePhotoTap(BuildContext context) async {
    // *** FIX: Create local picker instance here ***
    final ImagePicker picker = ImagePicker();
    print("Choose Photo Tapped - Opening gallery...");
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        print('Image picked from gallery: ${image.path}');
        // Use mounted check if context is used across async gap
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image Selected: ${image.name}')),
        );
        // TODO: Process picked image
      } else {
        print('No image selected from gallery.');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  // Takes a photo using the camera
  Future<void> _onTakePhotoTap(BuildContext context) async {
    // *** FIX: Create local picker instance here ***
    final ImagePicker picker = ImagePicker();
    print("Take New Photo Tapped - Opening camera...");
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        print('Photo taken: ${photo.path}');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo Taken: ${photo.name}')),
        );
        // TODO: Process taken photo
      } else {
        print('No photo taken.');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No photo taken.')),
        );
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error using camera: $e')),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo'; // Ensure font is set up

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Add new item",
          style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text( // Search via description Title
              "Search via description",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: defaultFontFamily, fontSize: 17, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02 * 17),
            ),
            const SizedBox(height: 15),
            TextField( // Search Input Field
              style: const TextStyle(fontFamily: defaultFontFamily, fontSize: 15, fontWeight: FontWeight.w300, color: Color.fromRGBO(0, 0, 0, 0.65), letterSpacing: -0.02 * 15),
              decoration: InputDecoration(
                hintText: "STPS BLACK CREWNECK", // Placeholder
                hintStyle: const TextStyle(fontFamily: defaultFontFamily, fontSize: 15, fontWeight: FontWeight.w300, color: Color.fromRGBO(0, 0, 0, 0.65), letterSpacing: -0.02 * 15),
                prefixIcon: const Padding(padding: EdgeInsets.only(left: 13.0, right: 10.0), child: Icon(Icons.search, size: 21, color: Colors.black54)),
                filled: true, fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.0)),
              ),
            ),
            const SizedBox(height: 40),
            const Text( // "Or using photo" Title
              "Or using photo",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: defaultFontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02 * 16),
            ),
            const SizedBox(height: 15),
            Row( // Photo Option Buttons Row
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPhotoOptionCard( // Choose Photo Button
                  context: context, label: "Choose photo", icon: Icons.photo_library_outlined, backgroundColor: const Color(0xFFFFEFE5),
                  onTap: () => _onChoosePhotoTap(context), // Calls gallery function
                  fontFamily: defaultFontFamily,
                ),
                const SizedBox(width: 28), // Spacing
                _buildPhotoOptionCard( // Take Photo Button
                  context: context, label: "Take New", icon: Icons.camera_alt_outlined, backgroundColor: const Color(0xFFFFDFE0),
                  onTap: () => _onTakePhotoTap(context), // Calls camera function
                  fontFamily: defaultFontFamily,
                ),
              ],
            ),
            const SizedBox(height: 30), // Bottom Padding
          ],
        ),
      ),
    );
  }

  // Helper widget for the photo option cards (remains the same)
  Widget _buildPhotoOptionCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
    required String fontFamily,
  }) {
    return InkWell(
      onTap: onTap, // This makes the card tappable
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        width: 176, height: 94,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)) ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container( // Circular Icon Background
              width: 40, height: 40,
              decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
              child: Icon(icon, size: 25, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text( // Label Text
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02 * 17),
            ),
          ],
        ),
      ),
    );
  }
}