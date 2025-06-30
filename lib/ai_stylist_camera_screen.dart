import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'filtered_shop_page.dart';
import 'outfit_generation_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIStylistCameraScreen extends StatefulWidget {
  final String? token; // Add token parameter (optional to maintain compatibility)
  final int userId; // <-- Add this
  
  const AIStylistCameraScreen({this.token, required this.userId, super.key});

  @override
  State<AIStylistCameraScreen> createState() => _AIStylistCameraScreenState();
}

class _AIStylistCameraScreenState extends State<AIStylistCameraScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  bool _isLoading = false;
  String? _predictedCategory;
  Map<String, dynamic>? _recommendations;
  // Store user selection for each category
  Map<String, String> _selectedSource = {'top': 'closet', 'bottom': 'closet', 'shoes': 'closet'};

  int get userId => widget.userId;

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
  Future<void> _onGenerateOutfitPressed() async {
    if (_imageFile == null) return;
    setState(() { _isAnalyzing = true; });
    final processedImageUrl = await _recommendOutfit(_imageFile!);
    setState(() { _isAnalyzing = false; });

    if (_recommendations != null) {
      final List<ShopItem> outfitItems = [];
      for (var cat in ['top', 'bottom', 'shoes']) {
        final catRecs = _recommendations?[cat];
        if (catRecs != null) {
          String? selected = _selectedSource[cat];
          // Fallback logic: if selected is null, pick the available one
          if (selected == null || catRecs[selected] == null) {
            if (catRecs['closet'] != null) {
              selected = 'closet';
              _selectedSource[cat] = 'closet';
            } else if (catRecs['shop'] != null) {
              selected = 'shop';
              _selectedSource[cat] = 'shop';
            } else {
              selected = null;
            }
          }
          final item = selected != null ? catRecs[selected] : null;
          if (item != null) {
            outfitItems.add(ShopItem(
              id: item['id'].toString(),
              name: (item['name'] != null && (item['brand'] ?? '').toString().isNotEmpty)
                ? '${item['name']} | ${item['brand']}'
                : (item['name'] ?? (item['subcategory'] ?? '')),
              description: '',
              category: item['category'] ?? '',
              userName: item['brand'] ?? '',
              price: item['price']?.toString() ?? '',
              imageUrl: item['path'],
              color: item['color'] ?? '',
              size: item['size'] ?? '',
              occasion: item['occasion'] ?? '',
              gender: item['gender'] ?? '',
              subcategory: item['subcategory'] ?? '',
              brand: item['brand'] ?? '',
              source: selected,
            ));
          }
        }
      }
      print('AIStylistCameraScreen token: \'${widget.token}\', userId: ${widget.userId}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutfitGenerationScreen(
            outfitItems: outfitItems,
            userId: userId,
            processedImageUrl: processedImageUrl ?? _imageFile!.path,
            token: widget.token,
            originalImagePath: _imageFile!.path,
          ),
        ),
      );
    }
  }

  Future<String?> _recommendOutfit(File imageFile) async {
    setState(() { _isLoading = true; });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/ai/recommend-outfit'),
      );
      request.fields['user_id'] = userId.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        setState(() {
          _recommendations = data['recommendations'];
          _predictedCategory = data['predicted_category'];
          _isLoading = false;
        });
        // Try to get processed image URL from backend response
        if (data.containsKey('processed_image_url')) {
          return data['processed_image_url'];
        }
      } else {
        setState(() { _isLoading = false; });
        // Handle error
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      // Handle error
    }
    return null;
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
                onPressed: _imageFile != null && !_isAnalyzing ? _onGenerateOutfitPressed : null,
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

  Widget _buildOutfitPreview() {
    if (_recommendations == null) return Container();
    return Column(
      children: [
        Text('Predicted Category: ${_predictedCategory ?? 'N/A'}'),
        ...['top', 'bottom', 'shoes'].map((cat) {
          final catRecs = _recommendations?[cat];
          if (catRecs == null || (catRecs['closet'] == null && catRecs['shop'] == null)) {
            return Text('No recommendation available for ${cat[0].toUpperCase()}${cat.substring(1)}');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cat[0].toUpperCase()}${cat.substring(1)}'),
              Row(
                children: [
                  for (final source in ['closet', 'shop'])
                    if (catRecs[source] != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSource[cat] = source;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedSource[cat] == source ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(source == 'closet' ? 'Closet' : 'Shop',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                if (catRecs[source]['path'] != null)
                                  Image.network(catRecs[source]['path'], height: 80),
                                Text(catRecs[source]['name'] ?? ''),
                                if ((catRecs[source]['brand'] ?? '').toString().isNotEmpty)
                                  Text(catRecs[source]['brand'], style: TextStyle(fontSize: 12)),
                                if ((catRecs[source]['price'] ?? '').toString().isNotEmpty)
                                  Text('${catRecs[source]['price']} EGP', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          );
        }).toList(),
        ElevatedButton(
          onPressed: _isLoading ? null : _onGenerateOutfitPressed,
          child: Text('Continue'),
        ),
      ],
    );
  }

  Future<void> _saveOutfit() async {
    if (_recommendations == null) return;
    setState(() { _isLoading = true; });
    try {
      final body = {
        'user_id': userId,
        'top_id': _recommendations?['top']?['id'],
        'bottom_id': _recommendations?['bottom']?['id'],
        'shoes_id': _recommendations?['shoes']?['id'],
        'name': 'AI Stylist Outfit',
        'tags': [],
        'is_favorite': false,
      };
      // Remove any None/Null IDs (for cases where only 2 items are recommended)
      body.removeWhere((k, v) => v == null);
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ai/save-outfit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      setState(() { _isLoading = false; });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Outfit saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save outfit.')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving outfit: $e')),
      );
    }
  }
} 