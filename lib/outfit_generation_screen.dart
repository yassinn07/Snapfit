import 'package:flutter/material.dart';
import 'filtered_shop_page.dart';
import 'item_screen.dart';
import 'services/ml_outfit_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/shop_service.dart';
import 'add_item.dart';
import 'services/closet_service.dart';
import 'dart:io';

class OutfitGenerationScreen extends StatefulWidget {
  final List<ShopItem> outfitItems;
  final int userId;
  final String? processedImageUrl;
  final String? token;
  final String? originalImagePath;
  const OutfitGenerationScreen({required this.outfitItems, required this.userId, this.processedImageUrl, this.token, this.originalImagePath, super.key});

  @override
  State<OutfitGenerationScreen> createState() => _OutfitGenerationScreenState();
}

class _OutfitGenerationScreenState extends State<OutfitGenerationScreen> {
  late List<ShopItem> _outfitItems;
  int? _newItemIndex; // Index of the new item needing details
  bool _isAddingNewItem = false;
  int? _newItemId;
  
  @override
  void initState() {
    super.initState();
    _outfitItems = List.from(widget.outfitItems);
    // Find the item without an ID (id is null or empty or negative)
    _newItemIndex = _outfitItems.indexWhere((item) => item.id.isEmpty || int.tryParse(item.id) == null || int.tryParse(item.id)! <= 0);
    _isAddingNewItem = _newItemIndex != -1;
  }

  void _onNewItemAdded(int newId, ShopItem completedItem) {
      setState(() {
      _outfitItems[_newItemIndex!] = completedItem.copyWith(id: newId.toString());
      _isAddingNewItem = false;
      _newItemId = newId;
    });
  }

  Future<void> _saveOutfit(BuildContext context) async {
    // Map items to their categories robustly
    int? topId, bottomId, shoesId;
    String? missingCategory;
    for (final item in _outfitItems) {
      final subcat = item.subcategory.toLowerCase();
      if ((subcat.contains('top') || subcat.contains('shirt') || subcat.contains('jacket') || subcat.contains('sweater') || subcat.contains('tshirt') || subcat.contains('upper body')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        topId = int.tryParse(item.id);
      } else if ((subcat.contains('bottom') || subcat.contains('jean') || subcat.contains('pant') || subcat.contains('trouser') || subcat.contains('short') || subcat.contains('skirt')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        bottomId = int.tryParse(item.id);
      } else if ((subcat.contains('shoe') || subcat.contains('sneaker') || subcat.contains('boot') || subcat.contains('sandal') || subcat.contains('loafer') || subcat.contains('flat') || subcat.contains('heel')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        shoesId = int.tryParse(item.id);
      }
    }
    if (topId == null) missingCategory = 'top';
    else if (bottomId == null) missingCategory = 'bottom';
    else if (shoesId == null) missingCategory = 'shoes';
    
    if (topId == null || bottomId == null || shoesId == null) {
      // Create placeholder ShopItem for missing category and show dialog
      final placeholder = ShopItem(
        id: "",
        name: "",
        description: "",
        category: missingCategory ?? '',
        userName: "",
        price: "",
        imageUrl: widget.processedImageUrl ?? '',
        color: "",
        size: "",
        occasion: "",
        gender: "",
        subcategory: "",
        brand: "",
        source: "closet",
      );
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 400,
            child: ItemDetailsForm(
              initialItem: placeholder,
              userId: widget.userId,
              processedImageUrl: widget.processedImageUrl,
              token: widget.token,
              originalImagePath: widget.originalImagePath,
              onItemAdded: (int newId, ShopItem completedItem) async {
      setState(() {
                  // Replace any existing item for this category
                  final idx = _outfitItems.indexWhere((item) => item.category.toLowerCase() == (missingCategory ?? ''));
                  if (idx != -1) {
                    _outfitItems[idx] = completedItem.copyWith(id: newId.toString());
                  } else {
                    _outfitItems.add(completedItem.copyWith(id: newId.toString()));
                  }
                });
                Navigator.of(ctx).pop(); // Close the dialog
                
                // Now directly save the outfit with the updated items
                await _saveOutfitDirectly();
              },
            ),
          ),
        ),
      );
      return;
    }
    
    // All items are present, save the outfit
    await _saveOutfitDirectly();
  }

  Future<void> _saveOutfitDirectly() async {
    // Map items to their categories robustly
    int? topId, bottomId, shoesId;
    for (final item in _outfitItems) {
      final subcat = item.subcategory.toLowerCase();
      if ((subcat.contains('top') || subcat.contains('shirt') || subcat.contains('jacket') || subcat.contains('sweater') || subcat.contains('tshirt') || subcat.contains('upper body')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        topId = int.tryParse(item.id);
      } else if ((subcat.contains('bottom') || subcat.contains('jean') || subcat.contains('pant') || subcat.contains('trouser') || subcat.contains('short') || subcat.contains('skirt')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        bottomId = int.tryParse(item.id);
      } else if ((subcat.contains('shoe') || subcat.contains('sneaker') || subcat.contains('boot') || subcat.contains('sandal') || subcat.contains('loafer') || subcat.contains('flat') || subcat.contains('heel')) && int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        shoesId = int.tryParse(item.id);
      }
    }
    
    if (topId == null || bottomId == null || shoesId == null) {
      print('DEBUG: topId=$topId, bottomId=$bottomId, shoesId=$shoesId');
      print('DEBUG: _outfitItems=${_outfitItems.map((item) => 'id: \\${item.id}, cat: \\${item.category}, name: \\${item.name}').toList()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing required items for outfit.')),
      );
      return;
    }
    
    final body = {
      'user_id': widget.userId,
      'top_id': topId,
      'bottom_id': bottomId,
      'shoes_id': shoesId,
      'name': 'AI Stylist Outfit',
      'tags': [],
      'is_favorite': false,
    };
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ai/save-outfit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving outfit: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    if (_isAddingNewItem && _newItemIndex != null && _newItemIndex! >= 0) {
      // Show the item details form for the new item
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add New Item to Closet', style: TextStyle(fontFamily: defaultFontFamily, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ItemDetailsForm(
          initialItem: _outfitItems[_newItemIndex!],
          userId: widget.userId,
          onItemAdded: (int newId, ShopItem completedItem) => _onNewItemAdded(newId, completedItem),
          processedImageUrl: widget.processedImageUrl,
          token: widget.token,
          originalImagePath: widget.originalImagePath,
        ),
      );
    }
    // Normal outfit generation screen
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "AI Outfit Generator",
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
      body: Column(
          children: [
          Expanded(
            child: _outfitItems.isEmpty
              ? Center(child: Text('No outfit recommendations found.', style: TextStyle(fontFamily: defaultFontFamily)))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
                  itemCount: _outfitItems.length,
                  itemBuilder: (context, index) {
                    final item = _outfitItems[index];
                    return _buildOutfitItemCard(item, defaultFontFamily, context);
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveOutfit(context);
                        },
              style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD55F5F), // mainRed
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Archivo',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                          elevation: 2,
                        ),
                        child: const Text("Save Outfit"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // Cancel: pop twice to return to first screen
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD55F5F),
                          side: const BorderSide(color: Color(0xFFD55F5F), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Archivo',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOutfitItemCard(ShopItem item, String fontFamily, BuildContext context) {
    final isShop = item.source == 'shop';
    final isCloset = item.source == 'closet';
    return GestureDetector(
      onTap: isShop
          ? () async {
              final shopService = ShopService(token: null); // Pass token if needed
              final fullItem = await shopService.getShopItemById(item.id);
              if (fullItem != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
                    builder: (context) => ItemScreen(item: fullItem, userId: widget.userId),
          ),
        );
              }
            }
          : null, // Disable tap for closet items
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.checkroom, size: 40, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                children: [
                  Text(
                    item.category,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isShop ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isShop ? 'From Shop' : 'From Closet',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isShop ? Colors.blue[900] : Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.userName.isNotEmpty
                      ? (item.name.isNotEmpty ? '${item.name} | ${item.userName}' : (item.subcategory.isNotEmpty ? '${item.subcategory} | ${item.userName}' : item.userName))
                      : (item.name.isNotEmpty ? item.name : (item.subcategory ?? '')),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.price != null && item.price.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${item.price} EGP',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                    ),
                  if (item.color.isNotEmpty)
                    Text('Color: ${item.color}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                  if (item.size.isNotEmpty)
                    Text('Size: ${item.size}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                  if (item.occasion.isNotEmpty)
                    Text('Occasion: ${item.occasion}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                  if (item.userName != null && item.userName.toString().isNotEmpty)
                    Text('Brand: ${item.userName}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add a local ItemDetailsForm widget for new item entry (modeled after add_item.dart)
class ItemDetailsForm extends StatefulWidget {
  final ShopItem initialItem;
  final int userId;
  final void Function(int newId, ShopItem completedItem) onItemAdded;
  final String? processedImageUrl;
  final String? token;
  final String? originalImagePath;
  const ItemDetailsForm({required this.initialItem, required this.userId, required this.onItemAdded, this.processedImageUrl, this.token, this.originalImagePath, Key? key}) : super(key: key);

  @override
  State<ItemDetailsForm> createState() => _ItemDetailsFormState();
}

class _ItemDetailsFormState extends State<ItemDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  String? _category;
  String? _subcategory;
  bool _isLoading = false;

  final List<String> _categories = ['Upper Body', 'Lower Body', 'Dress', 'Bags', 'Shoes'];
  final Map<String, List<String>> _subcategories = {
    'Upper Body': ['Jackets', 'Shirts', 'Sweaters', 'Tops', 'Tshirts'],
    'Lower Body': ['Jeans', 'Shorts', 'Skirts', 'Track Pants', 'Trousers'],
    'Dress': ['Casual Dresses', 'Formal Dresses', 'Party Dresses'],
    'Bags': ['Backpacks', 'Clutches', 'Totes'],
    'Shoes': ['Casual - Formal Shoes', 'Sandals', 'Sports Shoes'],
  };
  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<String> _occasionOptions = ['Casual', 'Formal', 'Sports'];
  String? _occasion;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialItem.name;
    _colorController.text = widget.initialItem.color;
    _sizeController.text = widget.initialItem.size;
    _occasionController.text = widget.initialItem.occasion;
    // Map placeholder category to valid dropdown value
    String cat = widget.initialItem.category.trim().toLowerCase();
    if (cat == 'top') {
      _category = 'Upper Body';
    } else if (cat == 'bottom') {
      _category = 'Lower Body';
    } else if (cat == 'shoes' || cat == 'shoe') {
      _category = 'Shoes';
    } else if (_categories.contains(widget.initialItem.category)) {
      _category = widget.initialItem.category;
    } else {
      _category = null;
    }
    _subcategory = widget.initialItem.subcategory.isNotEmpty ? widget.initialItem.subcategory : null;
    _occasion = widget.initialItem.occasion.isNotEmpty ? widget.initialItem.occasion : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
      print('ItemDetailsForm token: \'${widget.token}\'');
      // Call backend to add item and get new ID
      final closetService = ClosetService(token: widget.token ?? '');
      final newItem = await closetService.addItemFull(
        name: _nameController.text,
        category: _category ?? '',
        subcategory: _subcategory ?? '',
        color: _colorController.text,
        size: _sizeController.text,
        occasion: _occasion ?? '',
        brand: '',
        gender: '',
        imagePath: widget.originalImagePath ?? '',
        userId: widget.userId,
      );
      if (newItem != null) {
        // Use the actual database ID returned from the backend
        final newId = int.parse(newItem.id);
        final completedItem = widget.initialItem.copyWith(
          id: newItem.id,
          name: _nameController.text,
          color: _colorController.text,
          size: _sizeController.text,
          occasion: _occasion ?? '',
          category: _category ?? '',
          subcategory: _subcategory ?? '',
        );
        widget.onItemAdded(newId, completedItem);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add item.')));
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'Archivo';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter Item Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: fontFamily), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (widget.processedImageUrl != null && widget.processedImageUrl!.isNotEmpty) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.processedImageUrl!.startsWith('http')
                    ? Image.network(
                        widget.processedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      )
                    : Image.file(
                        File(widget.processedImageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category, style: const TextStyle(fontFamily: fontFamily)))).toList(),
              onChanged: (val) {
                setState(() {
                  _category = val;
                  _subcategory = null;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name/Description',
                prefixIcon: Icon(Icons.label_outline, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a name/description' : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _subcategory,
              items: (_category != null ? (_subcategories[_category] ?? <String>[]) : <String>[])
                  .map((sub) => DropdownMenuItem(value: sub, child: Text(sub, style: const TextStyle(fontFamily: fontFamily)))).toList(),
              onChanged: (val) => setState(() => _subcategory = val),
              decoration: const InputDecoration(
                labelText: 'Subcategory',
                prefixIcon: Icon(Icons.category_outlined, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null ? 'Please select a subcategory' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                prefixIcon: Icon(Icons.color_lens_outlined, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
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
                prefixIcon: Icon(Icons.straighten, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please select a size' : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _occasionOptions.contains(_occasion) ? _occasion : null,
              items: _occasionOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontFamily: fontFamily)))).toList(),
              onChanged: (val) {
                setState(() {
                  _occasion = val;
                  _occasionController.text = val ?? '';
                });
              },
              decoration: const InputDecoration(
                labelText: 'Occasion',
                prefixIcon: Icon(Icons.event_outlined, color: Color(0xFFD55F5F)),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please select an occasion' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD55F5F),
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
    );
  }
} 