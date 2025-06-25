// lib/add_item.dart

import 'package:flutter/material.dart';
// Import the image_picker package
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import 'dart:io' if you need to use File() for previews
import 'services/closet_service.dart'; // Import closet service
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/profile_service.dart'; // Import profile service

class AddItemPage extends StatefulWidget {
  final String token;
  const AddItemPage({required this.token, super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  String? _category;
  String? _subcategory;
  File? _imageFile;
  bool _isLoading = false;
  bool _showImagePreview = false;
  bool _isClassifying = false;
  String? _userGender;
  int? _uploadedItemId; // Store the uploaded item ID for classification
  String? _maskedImageUrl; // Store the masked image URL for preview

  final List<String> _categories = ['Upper Body', 'Lower Body', 'Shoes'];
  final Map<String, List<String>> _subcategories = {
    'Upper Body': ['Jackets', 'Shirts', 'Sweaters', 'Tops', 'Tshirts'],
    'Lower Body': ['Jeans', 'Shorts', 'Skirts', 'Track Pants', 'Trousers'],
    'Shoes': ['Casual - Formal Shoes', 'Sandals', 'Sports Shoes'],
  };
  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<String> _occasionOptions = ['Casual', 'Formal', 'Sports'];
  String? _occasion;

  // --- Adjusted Theme-related Fields ---
  static const Color mainRed = Color(0xFFD55F5F);
  static const Color bgColor = Color(0xFFF6F1EE);
  static const String fontFamily = 'Archivo';
  static const OutlineInputBorder themedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)), // BorderRadius.circular is const
    borderSide: BorderSide(color: mainRed, width: 1.2),   // BorderSide can be const
  );
  // --- End of Adjustments ---

  // Add a step variable to control the flow
  int _step = 0; // 0: image, 1: details (removed category selection step)
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
  }

  Future<void> _fetchUserGender() async {
    try {
      final profileService = ProfileService(token: widget.token);
      final profile = await profileService.getUserProfile();
      setState(() {
        _userGender = profile.gender;
      });
    } catch (e) {
      setState(() {
        _userGender = null;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _showImagePreview = true;
        _uploadedItemId = null; // Reset uploaded item ID when new image is picked
        _maskedImageUrl = null; // Reset masked image URL when new image is picked
      });
    }
  }

  void _cancelImagePreview() {
    setState(() {
      _imageFile = null;
      _showImagePreview = false;
      _uploadedItemId = null;
      _maskedImageUrl = null;
    });
  }

  void _continueAfterPreview() {
    setState(() {
      _showImagePreview = false;
    });
  }

  Future<bool> _uploadImageFirst() async {
    if (_imageFile == null) return false;
    
    setState(() { _isLoading = true; });
    try {
      final closetService = ClosetService(token: widget.token);
      final uploadResult = await closetService.addItemWithImage(_imageFile!.path);
      
      if (uploadResult != null && uploadResult['id'] != null) {
        setState(() {
          _uploadedItemId = uploadResult['id'];
          _maskedImageUrl = uploadResult['url']; // Store the masked image URL
        });
        
        // Handle classification results from upload
        if (uploadResult['classification'] != null) {
          final classification = uploadResult['classification'];
          setState(() {
            _category = classification['category'];
            _selectedCategory = classification['category'];
          });
          
          // Call the appropriate specific classifier based on subcategory prediction
          final subcategory = classification['subcategory'];
          if (subcategory == 'Topwear') {
            await _classifyTopwear();
          } else if (subcategory == 'Bottomwear') {
            await _classifyBottomwear();
          } else if (subcategory == 'Shoes') {
            await _classifyShoes();
          }
        }
        
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return false;
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and select an image.')));
      return;
    }
    setState(() { _isLoading = true; });
    final closetService = ClosetService(token: widget.token);
    final success = await closetService.addItemFull(
      name: _nameController.text,
      category: _category!,
      subcategory: _subcategory ?? '',
      color: _colorController.text,
      size: _sizeController.text,
      occasion: _occasion ?? '',
      brand: '..',
      gender: _userGender ?? '',
      imagePath: _imageFile!.path,
    );
    setState(() { _isLoading = false; });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add item.')));
    }
  }

  Future<void> _classifyTopwear() async {
    if (_uploadedItemId == null) {
      // First upload the image if not already uploaded
      final uploadSuccess = await _uploadImageFirst();
      if (!uploadSuccess) return;
    }
    
    setState(() { _isClassifying = true; });
    try {
      final url = Uri.parse('http://10.0.2.2:8000/ai/classify-topwear?item_id=$_uploadedItemId');
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      
      final response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var data = jsonDecode(respStr);
        setState(() {
          _subcategory = data['topwear'];
          final occasion = data['occasion'];
          if (_occasionOptions.contains(occasion)) {
            _occasion = occasion;
          } else {
            _occasion = null;
          }
          _occasionController.text = _occasion ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to classify image.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isClassifying = false; });
    }
  }

  Future<void> _classifyBottomwear() async {
    if (_uploadedItemId == null) {
      // First upload the image if not already uploaded
      final uploadSuccess = await _uploadImageFirst();
      if (!uploadSuccess) return;
    }
    
    setState(() { _isClassifying = true; });
    try {
      final url = Uri.parse('http://10.0.2.2:8000/ai/classify-bottomwear?item_id=$_uploadedItemId');
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      
      final response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var data = jsonDecode(respStr);
        setState(() {
          _subcategory = data['bottomwear'];
          final occasion = data['occasion'];
          if (_occasionOptions.contains(occasion)) {
            _occasion = occasion;
          } else {
            _occasion = null;
          }
          _occasionController.text = _occasion ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to classify image.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isClassifying = false; });
    }
  }

  Future<void> _classifyShoes() async {
    if (_uploadedItemId == null) {
      // First upload the image if not already uploaded
      final uploadSuccess = await _uploadImageFirst();
      if (!uploadSuccess) return;
    }
    
    setState(() { _isClassifying = true; });
    try {
      final url = Uri.parse('http://10.0.2.2:8000/ai/classify-shoes?item_id=$_uploadedItemId');
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      
      final response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var data = jsonDecode(respStr);
        setState(() {
          _subcategory = data['shoes'];
          final occasion = data['occasion'];
          if (_occasionOptions.contains(occasion)) {
            _occasion = occasion;
          } else {
            _occasion = null;
          }
          _occasionController.text = _occasion ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to classify image.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isClassifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new item', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: fontFamily, color: Colors.black)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 60.0, bottom: 0.0),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      // Step 1: Image selection
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 0, right: 0, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Info note for best photo ---
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Place the clothing item on a flat surface and take a clear photo',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 14,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: _imageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Take a photo of your item', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: 500),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Upload image and auto-classify, then go to details
                  final success = await _uploadImageFirst();
                  if (success) {
                    setState(() => _step = 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  minimumSize: const Size(180, 48),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue', style: TextStyle(fontFamily: fontFamily, fontSize: 18)),
              ),
            ],
          ],
        ),
      );
    } else {
      // Step 2: Details form (modern card with icons and divider)
      return Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Card(
          elevation: 6,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: fontFamily),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Masked Image Preview Container
                  if (_maskedImageUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_fix_high, color: mainRed, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Background Removed Image',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'http://10.0.2.2:8000$_maskedImageUrl',
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: mainRed,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(color: Colors.grey[600], fontFamily: fontFamily),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  const Divider(height: 32, thickness: 1.2),
                  
                  // Category Dropdown (auto-filled based on classification)
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: _categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category, style: const TextStyle(fontFamily: fontFamily)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _category = val;
                        _selectedCategory = val;
                        _subcategory = null; // Reset subcategory when category changes
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category, color: mainRed),
                      labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                      border: themedBorder,
                      focusedBorder: themedBorder,
                    ),
                    validator: (value) => value == null ? 'Please select a category' : null,
                    style: const TextStyle(fontFamily: fontFamily, color: mainRed),
                    dropdownColor: Colors.white,
                    iconEnabledColor: mainRed,
                  ),
                  const SizedBox(height: 18),
                  
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontFamily: fontFamily),
                        decoration: const InputDecoration(
                          labelText: 'Name/Description',
                      prefixIcon: Icon(Icons.label_outline, color: mainRed),
                          labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                          border: themedBorder,
                          focusedBorder: themedBorder,
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name/description' : null,
                      ),
                      const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          value: _subcategory,
                    items: (_selectedCategory != null ? (_subcategories[_selectedCategory] ?? <String>[]) : <String>[])
                        .map<DropdownMenuItem<String>>((sub) => DropdownMenuItem<String>(
                            value: sub,
                            child: Text(sub, style: const TextStyle(fontFamily: fontFamily)),
                        ))
                        .toList(),
                          onChanged: (val) => setState(() => _subcategory = val),
                          decoration: const InputDecoration(
                            labelText: 'Subcategory',
                      prefixIcon: Icon(Icons.category_outlined, color: mainRed),
                            labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                            border: themedBorder,
                            focusedBorder: themedBorder,
                          ),
                          validator: (value) => value == null ? 'Please select a subcategory' : null,
                          style: const TextStyle(fontFamily: fontFamily, color: mainRed),
                          dropdownColor: Colors.white,
                          iconEnabledColor: mainRed,
                        ),
                  const SizedBox(height: 18),
                      TextFormField(
                        controller: _colorController,
                        style: const TextStyle(fontFamily: fontFamily),
                        decoration: const InputDecoration(
                          labelText: 'Color',
                      prefixIcon: Icon(Icons.color_lens_outlined, color: mainRed),
                          labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                          border: themedBorder,
                          focusedBorder: themedBorder,
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a color' : null,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _sizeController.text.isNotEmpty ? _sizeController.text : null,
                        items: _sizes.map((size) => DropdownMenuItem(value: size, child: Text(size, style: const TextStyle(fontFamily: fontFamily)))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _sizeController.text = val ?? '';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Size',
                      prefixIcon: Icon(Icons.straighten, color: mainRed),
                          labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                          border: themedBorder,
                          focusedBorder: themedBorder,
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please select a size' : null,
                        style: const TextStyle(fontFamily: fontFamily, color: mainRed),
                        dropdownColor: Colors.white,
                        iconEnabledColor: mainRed,
                      ),
                      const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _occasionOptions.contains(_occasion) ? _occasion : null,
                    items: _occasionOptions
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option, style: const TextStyle(fontFamily: fontFamily)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _occasion = val;
                        _occasionController.text = val ?? '';
                      });
                    },
                        decoration: const InputDecoration(
                          labelText: 'Occasion',
                      prefixIcon: Icon(Icons.event_outlined, color: mainRed),
                          labelStyle: TextStyle(color: mainRed, fontFamily: fontFamily),
                          border: themedBorder,
                          focusedBorder: themedBorder,
                        ),
                    validator: (value) => value == null || value.isEmpty ? 'Please select an occasion' : null,
                    style: const TextStyle(fontFamily: fontFamily, color: mainRed),
                    dropdownColor: Colors.white,
                    iconEnabledColor: mainRed,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainRed,
                          foregroundColor: Colors.white,
                      elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
                  ),
                ],
            ),
          ),
        ),
      ),
    );
    }
  }
}