import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'constants.dart' show showThemedSnackBar;

class BrandAddItemScreen extends StatefulWidget {
  final String token;

  const BrandAddItemScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BrandAddItemScreen> createState() => _BrandAddItemScreenState();
}

class _BrandAddItemScreenState extends State<BrandAddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;

  // Form controllers
  final _apparelTypeController = TextEditingController();
  final _subtypeController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  final _occasionController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchaseLinkController = TextEditingController();

  String _selectedGender = 'Unisex';
  String _selectedSeason = 'All Year Long';

  final List<String> _genderOptions = ['Male', 'Female', 'Unisex'];
  final List<String> _seasonOptions = ['Spring', 'Summer', 'Fall', 'Winter', 'All Year Long'];
  final List<String> _apparelTypeOptions = ['Top', 'Bottom', 'Shoes', 'Bags'];
  final List<String> _sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void dispose() {
    _apparelTypeController.dispose();
    _subtypeController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _occasionController.dispose();
    _priceController.dispose();
    _purchaseLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      showThemedSnackBar(context, 'Please fill all required fields and select an image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/brands/add-item'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add image
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      // Add form fields
      request.fields['apparel_type'] = _apparelTypeController.text;
      request.fields['subtype'] = _subtypeController.text;
      request.fields['color'] = _colorController.text;
      request.fields['size'] = _sizeController.text;
      request.fields['occasion'] = _occasionController.text;
      request.fields['gender'] = _selectedGender;
      request.fields['season'] = _selectedSeason;

      if (_priceController.text.isNotEmpty) {
        request.fields['price'] = _priceController.text;
      }
      if (_purchaseLinkController.text.isNotEmpty) {
        request.fields['purchase_link'] = _purchaseLinkController.text;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (mounted) {
          showThemedSnackBar(context, 'Item added successfully!');
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          showThemedSnackBar(context, 'Error: ${json.decode(responseData)['detail'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      if (mounted) {
        showThemedSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      appBar: AppBar(
        title: const Text('Add New Item'),
        backgroundColor: const Color(0xFFD55F5F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Apparel Type
              DropdownButtonFormField<String>(
                value: _apparelTypeController.text.isEmpty ? null : _apparelTypeController.text,
                decoration: const InputDecoration(
                  labelText: 'Apparel Type *',
                  border: OutlineInputBorder(),
                ),
                items: _apparelTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _apparelTypeController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select apparel type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subtype
              TextFormField(
                controller: _subtypeController,
                decoration: const InputDecoration(
                  labelText: 'Subtype (e.g., T-shirt, Jeans) *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subtype';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Size
              DropdownButtonFormField<String>(
                value: _sizeController.text.isEmpty ? null : _sizeController.text,
                decoration: const InputDecoration(
                  labelText: 'Size *',
                  border: OutlineInputBorder(),
                ),
                items: _sizeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sizeController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select size';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Target Gender *',
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Season
              DropdownButtonFormField<String>(
                value: _selectedSeason,
                decoration: const InputDecoration(
                  labelText: 'Season',
                  border: OutlineInputBorder(),
                ),
                items: _seasonOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSeason = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Occasion
              TextFormField(
                controller: _occasionController,
                decoration: const InputDecoration(
                  labelText: 'Occasion (e.g., Casual, Formal)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Purchase Link
              TextFormField(
                controller: _purchaseLinkController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Link',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD55F5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}