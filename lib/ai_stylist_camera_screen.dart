import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'filtered_shop_page.dart';
import 'outfit_generation_screen.dart';

class AIStylistCameraScreen extends StatefulWidget {
  final String? token; // Add token parameter (optional to maintain compatibility)
  
  const AIStylistCameraScreen({this.token, super.key});

  @override
  State<AIStylistCameraScreen> createState() => _AIStylistCameraScreenState();
}

class _AIStylistCameraScreenState extends State<AIStylistCameraScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  // Capture an image from the camera
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      
      setState(() {
        _imageFile = File(photo.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  // Choose an image from the gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() {
        _imageFile = File(image.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Process the image and navigate to outfit generation
  void _processImage() {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    // Simulate image analysis (in a real app, you'd send the image to a server)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
      });

      // Create a ShopItem from the captured image
      final ShopItem detectedItem = ShopItem(
        id: 'camera_item',
        name: 'Your Clothing Item',
        category: 'Unknown Category', // In a real app, this would be detected
        userName: 'Your Wardrobe',
        price: 'N/A',
        imageUrl: null, // We can't use local files directly as imageUrl
        description: 'Item captured from camera',
      );

      // Navigate to the outfit generation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutfitGenerationScreen(
            baseItem: detectedItem,
            token: widget.token
          ),
        ),
      );
    });
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
          "AI Stylist",
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.02 * 25,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F1EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Outfit Generator",
                    style: TextStyle(
                      fontFamily: defaultFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Take a picture of your clothing item, and our AI will generate complete outfit recommendations.",
                    style: TextStyle(
                      fontFamily: defaultFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Image preview area
            Expanded(
              child: _imageFile == null
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Take a photo of your item",
                            style: TextStyle(
                              fontFamily: defaultFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isAnalyzing)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Analyzing item...",
                                style: TextStyle(
                                  fontFamily: defaultFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
            ),
            
            const SizedBox(height: 24),
            
            // Button row
            Row(
              children: [
                // Camera button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD55F5F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Gallery button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Generate Outfit button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _imageFile != null && !_isAnalyzing ? _processImage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4BFE2),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Generate Outfit",
                  style: TextStyle(
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
} 