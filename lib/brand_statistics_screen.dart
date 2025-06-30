import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'config.dart';

class BrandStatisticsScreen extends StatefulWidget {
  final String token;
  final List<dynamic> items;
  const BrandStatisticsScreen({Key? key, required this.token, required this.items}) : super(key: key);

  @override
  State<BrandStatisticsScreen> createState() => _BrandStatisticsScreenState();
}

class _BrandStatisticsScreenState extends State<BrandStatisticsScreen> {
  late List<dynamic> _items;
  late List<dynamic> _filteredItems;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _filteredItems = widget.items;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = _items.where((item) {
        final name = (item['item_name'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBrandItemScreen(token: widget.token),
      ),
    ).then((_) {
      // Refresh the items list when returning from add item screen
      _refreshItems();
    });
  }

  Future<void> _refreshItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/brands/items/statistics'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> newItems = json.decode(response.body);
        setState(() {
          _items = newItems;
          _filteredItems = newItems;
        });
      }
    } catch (e) {
      print('Error refreshing items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildImageUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return it as is
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    
    // If it's a relative path, construct the full URL
    return '${Config.apiUrl}/static/$photoUrl';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Brand Statistics'),
        backgroundColor: const Color(0xFFD55F5F),
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add Item Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD55F5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 16),
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(child: Text('No items found.'))
                    : RefreshIndicator(
                        onRefresh: _refreshItems,
                        child: ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item['item_photo_url'] != null && item['item_photo_url'].toString().isNotEmpty
                                          ? Image.network(
                                              _buildImageUrl(item['item_photo_url']),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 80, color: Colors.grey),
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['item_name'] ?? '',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.touch_app, size: 18, color: Colors.blueGrey),
                                              const SizedBox(width: 4),
                                              Text('Users clicked: ${item['users_clicked'] ?? 0}'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.store, size: 18, color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text('Visit store: ${item['visit_store'] ?? 0}'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.recommend, size: 18, color: Colors.deepOrange),
                                              const SizedBox(width: 4),
                                              Text('Recommended: ${item['recommended'] ?? 0}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class AddBrandItemScreen extends StatefulWidget {
  final String token;
  
  const AddBrandItemScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AddBrandItemScreen> createState() => _AddBrandItemScreenState();
}

class _AddBrandItemScreenState extends State<AddBrandItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  String? _selectedImagePath;
  String _apparelType = '';
  String _subtype = '';
  String _color = '';
  String _size = '';
  String _occasion = '';
  String _gender = 'Unisex';
  String _season = '';
  double? _price;
  String _purchaseLink = '';
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Unisex'];
  final List<String> _apparelTypes = ['Top', 'Bottom', 'Shoes', 'Accessories'];
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _seasons = ['Spring', 'Summer', 'Fall', 'Winter', 'All Year Long'];

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/brands/add-item'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add form fields
      request.fields['apparel_type'] = _apparelType;
      request.fields['subtype'] = _subtype;
      request.fields['color'] = _color;
      request.fields['size'] = _size;
      request.fields['occasion'] = _occasion;
      request.fields['gender'] = _gender;
      request.fields['season'] = _season;
      if (_price != null) {
        request.fields['price'] = _price!.toString();
      }
      if (_purchaseLink.isNotEmpty) {
        request.fields['purchase_link'] = _purchaseLink;
      }

      // Add image file
      final file = await http.MultipartFile.fromPath(
        'image',
        _selectedImagePath!,
      );
      request.files.add(file);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode} - $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    // Image Selection
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Apparel Type
                    DropdownButtonFormField<String>(
                      value: _apparelType.isEmpty ? null : _apparelType,
                      decoration: const InputDecoration(
                        labelText: 'Apparel Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: _apparelTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setState(() => _apparelType = value!),
                      validator: (value) => value == null ? 'Please select apparel type' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtype
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Subtype *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _subtype = value,
                      validator: (value) => value?.isEmpty == true ? 'Please enter subtype' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Color
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Color *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _color = value,
                      validator: (value) => value?.isEmpty == true ? 'Please enter color' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Size
                    DropdownButtonFormField<String>(
                      value: _size.isEmpty ? null : _size,
                      decoration: const InputDecoration(
                        labelText: 'Size *',
                        border: OutlineInputBorder(),
                      ),
                      items: _sizes.map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
                      onChanged: (value) => setState(() => _size = value!),
                      validator: (value) => value == null ? 'Please select size' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender (Brand owner's choice)
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Item Gender *',
                        border: OutlineInputBorder(),
                      ),
                      items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Occasion
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Occasion',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _occasion = value,
                    ),
                    const SizedBox(height: 16),
                    
                    // Season
                    DropdownButtonFormField<String>(
                      value: _season.isEmpty ? null : _season,
                      decoration: const InputDecoration(
                        labelText: 'Season',
                        border: OutlineInputBorder(),
                      ),
                      items: _seasons.map((season) => DropdownMenuItem(value: season, child: Text(season))).toList(),
                      onChanged: (value) => setState(() => _season = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _price = double.tryParse(value),
                    ),
                    const SizedBox(height: 16),
                    
                    // Purchase Link
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Link',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _purchaseLink = value,
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
                      child: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 