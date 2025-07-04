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
import 'constants.dart' show showThemedSnackBar;

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
    // Only show add-item dialog if there is a missing item (id is empty or invalid AND source is not 'shop')
    _newItemIndex = _outfitItems.indexWhere((item) => (item.id.isEmpty || int.tryParse(item.id) == null || int.tryParse(item.id)! <= 0) && (item.source != 'shop'));
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

    // Check if any required category is missing from _outfitItems
    bool hasTop = _outfitItems.any((item) {
      final subcat = item.subcategory.toLowerCase();
      final cat = item.category.toLowerCase();
      return (subcat.contains('top') || cat.contains('top') ||
              subcat.contains('shirt') || cat.contains('shirt') ||
              subcat.contains('jacket') || cat.contains('jacket') ||
              subcat.contains('sweater') || cat.contains('sweater') ||
              subcat.contains('tshirt') || cat.contains('tshirt') ||
              subcat.contains('upper body') || cat.contains('upper body'));
    });
    bool hasBottom = _outfitItems.any((item) {
      final subcat = item.subcategory.toLowerCase();
      final cat = item.category.toLowerCase();
      return (subcat.contains('bottom') || cat.contains('bottom') ||
              subcat.contains('jean') || cat.contains('jean') ||
              subcat.contains('pant') || cat.contains('pant') ||
              subcat.contains('trouser') || cat.contains('trouser') ||
              subcat.contains('short') || cat.contains('short') ||
              subcat.contains('skirt') || cat.contains('skirt') ||
              subcat.contains('lower body') || cat.contains('lower body'));
    });
    bool hasShoes = _outfitItems.any((item) {
      final subcat = item.subcategory.toLowerCase();
      final cat = item.category.toLowerCase();
      return (subcat.contains('shoe') || cat.contains('shoe') ||
              subcat.contains('sneaker') || cat.contains('sneaker') ||
              subcat.contains('boot') || cat.contains('boot') ||
              subcat.contains('sandal') || cat.contains('sandal') ||
              subcat.contains('loafer') || cat.contains('loafer') ||
              subcat.contains('flat') || cat.contains('flat') ||
              subcat.contains('heel') || cat.contains('heel'));
    });

    if (!hasTop) missingCategory = 'top';
    else if (!hasBottom) missingCategory = 'bottom';
    else if (!hasShoes) missingCategory = 'shoes';

    if (missingCategory != null) {
      // Add a placeholder for the missing category and show the dialog
      final placeholder = ShopItem(
        id: "",
        name: "",
        description: "",
        category: missingCategory,
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
      setState(() {
        _outfitItems.add(placeholder);
      });
      // Show the dialog for the new placeholder
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
                  final idx = _outfitItems.indexWhere((item) => item.category.toLowerCase() == (missingCategory ?? ''));
                  if (idx != -1) {
                    _outfitItems[idx] = completedItem.copyWith(id: newId.toString());
                  } else {
                    _outfitItems.add(completedItem.copyWith(id: newId.toString()));
                  }
                });
                Navigator.of(ctx).pop();
                await _saveOutfitDirectly();
              },
            ),
          ),
        ),
      );
      return;
    }

    // Continue with the original logic for missing/invalid id
    for (final item in _outfitItems) {
      final subcat = item.subcategory.toLowerCase();
      final cat = item.category.toLowerCase();
      if ((subcat.contains('top') || cat.contains('top') ||
           subcat.contains('shirt') || cat.contains('shirt') ||
           subcat.contains('jacket') || cat.contains('jacket') ||
           subcat.contains('sweater') || cat.contains('sweater') ||
           subcat.contains('tshirt') || cat.contains('tshirt') ||
           subcat.contains('upper body') || cat.contains('upper body')) &&
          int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        topId = int.tryParse(item.id);
      } else if ((subcat.contains('bottom') || cat.contains('bottom') ||
                  subcat.contains('jean') || cat.contains('jean') ||
                  subcat.contains('pant') || cat.contains('pant') ||
                  subcat.contains('trouser') || cat.contains('trouser') ||
                  subcat.contains('short') || cat.contains('short') ||
                  subcat.contains('skirt') || cat.contains('skirt') ||
                  subcat.contains('lower body') || cat.contains('lower body')) &&
                 int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        bottomId = int.tryParse(item.id);
      } else if ((subcat.contains('shoe') || cat.contains('shoe') ||
                  subcat.contains('sneaker') || cat.contains('sneaker') ||
                  subcat.contains('boot') || cat.contains('boot') ||
                  subcat.contains('sandal') || cat.contains('sandal') ||
                  subcat.contains('loafer') || cat.contains('loafer') ||
                  subcat.contains('flat') || cat.contains('flat') ||
                  subcat.contains('heel') || cat.contains('heel')) &&
                 int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        shoesId = int.tryParse(item.id);
      }
    }
    if (topId == null) missingCategory = 'top';
    else if (bottomId == null) missingCategory = 'bottom';
    else if (shoesId == null) missingCategory = 'shoes';
    // Only show dialog if missing item is not from the shop
    final missingIndex = _outfitItems.indexWhere((item) => (item.id.isEmpty || int.tryParse(item.id) == null || int.tryParse(item.id)! <= 0) && (item.source != 'shop'));
    if ((topId == null || bottomId == null || shoesId == null) && missingIndex != -1) {
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
      final cat = item.category.toLowerCase();
      if ((subcat.contains('top') || cat.contains('top') ||
           subcat.contains('shirt') || cat.contains('shirt') ||
           subcat.contains('jacket') || cat.contains('jacket') ||
           subcat.contains('sweater') || cat.contains('sweater') ||
           subcat.contains('tshirt') || cat.contains('tshirt') ||
           subcat.contains('upper body') || cat.contains('upper body')) &&
          int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        topId = int.tryParse(item.id);
      } else if ((subcat.contains('bottom') || cat.contains('bottom') ||
                  subcat.contains('jean') || cat.contains('jean') ||
                  subcat.contains('pant') || cat.contains('pant') ||
                  subcat.contains('trouser') || cat.contains('trouser') ||
                  subcat.contains('short') || cat.contains('short') ||
                  subcat.contains('skirt') || cat.contains('skirt') ||
                  subcat.contains('lower body') || cat.contains('lower body')) &&
                 int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        bottomId = int.tryParse(item.id);
      } else if ((subcat.contains('shoe') || cat.contains('shoe') ||
                  subcat.contains('sneaker') || cat.contains('sneaker') ||
                  subcat.contains('boot') || cat.contains('boot') ||
                  subcat.contains('sandal') || cat.contains('sandal') ||
                  subcat.contains('loafer') || cat.contains('loafer') ||
                  subcat.contains('flat') || cat.contains('flat') ||
                  subcat.contains('heel') || cat.contains('heel')) &&
                 int.tryParse(item.id) != null && int.tryParse(item.id)! > 0) {
        shoesId = int.tryParse(item.id);
      }
    }
    
    if (topId == null || bottomId == null || shoesId == null) {
      print('DEBUG: topId=$topId, bottomId=$bottomId, shoesId=$shoesId');
      print('DEBUG: _outfitItems=${_outfitItems.map((item) => 'id: \\${item.id}, cat: \\${item.category}, name: \\${item.name}').toList()}');
      showThemedSnackBar(context, 'Missing required items for outfit.', type: 'critical');
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
        showThemedSnackBar(context, 'Outfit saved successfully!', type: 'success');
        // Navigate back to the previous screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      } else {
        showThemedSnackBar(context, 'Failed to save outfit.', type: 'critical');
      }
    } catch (e) {
      showThemedSnackBar(context, 'Error saving outfit: $e', type: 'critical');
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
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOutfitItemCard(ShopItem item, String fontFamily, BuildContext context) {
    final isShop = item.source == 'shop';
    final isCloset = item.source == 'closet';
    final isValidShopId = isShop && item.id.isNotEmpty && int.tryParse(item.id) != null && int.parse(item.id) > 0;
    String buildImageUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      return 'http://10.0.2.2:8000/static/$url';
    }
    return GestureDetector(
      onTap: isValidShopId
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
          : null, // Disable tap for closet items or invalid shop items
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
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      buildImageUrl(item.imageUrl),
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
  bool _isClassifying = false;

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
      showThemedSnackBar(context, 'Please fill all required fields.', type: 'critical');
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
        showThemedSnackBar(context, 'Failed to add item.', type: 'critical');
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _classifyItem() async {
    final imagePath = widget.originalImagePath ?? widget.processedImageUrl;
    if (imagePath == null || imagePath.isEmpty) return;
    setState(() { _isClassifying = true; });
    try {
      final url = Uri.parse('http://10.0.2.2:8000/ai/classify-image');
      final request = http.MultipartRequest('POST', url);
      if (widget.token != null) {
        request.headers.addAll({'Authorization': 'Bearer ${widget.token}'});
      }
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var data = jsonDecode(responseString);
        setState(() {
          _category = data['category'];
          // Validate subcategory exists in predefined list
          final returnedSubcategory = data['subcategory'];
          final availableSubcategories = _subcategories[_category] ?? [];
          if (availableSubcategories.contains(returnedSubcategory)) {
            _subcategory = returnedSubcategory;
          } else {
            _subcategory = null;
          }
          final occasion = data['occasion'];
          if (_occasionOptions.contains(occasion)) {
            _occasion = occasion;
          } else {
            _occasion = null;
          }
          _occasionController.text = _occasion ?? '';
        });
      } else {
        showThemedSnackBar(context, 'Failed to classify image.', type: 'critical');
      }
    } catch (e) {
      showThemedSnackBar(context, 'Error: $e', type: 'critical');
    } finally {
      setState(() { _isClassifying = false; });
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
            if ((widget.processedImageUrl != null && widget.processedImageUrl!.isNotEmpty) || (widget.originalImagePath != null && widget.originalImagePath!.isNotEmpty)) ...[
              // Show the image container first
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (widget.processedImageUrl != null && widget.processedImageUrl!.isNotEmpty && widget.processedImageUrl!.startsWith('http'))
                    ? Image.network(
                        widget.processedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      )
                    : (widget.processedImageUrl != null && widget.processedImageUrl!.isNotEmpty)
                      ? Image.file(
                        File(widget.processedImageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                        )
                      : (widget.originalImagePath != null && widget.originalImagePath!.isNotEmpty)
                        ? Image.file(
                            File(widget.originalImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                          )
                        : const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 10),
              // Autofill button below the image
              ElevatedButton.icon(
                onPressed: _isClassifying ? null : _classifyItem,
                icon: _isClassifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_fix_high, color: Colors.white),
                label: Text(_isClassifying ? 'Autofilling...' : 'Autofill with AI', style: const TextStyle(fontFamily: fontFamily)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD55F5F),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8), // More compact
                ),
              ),
              const SizedBox(height: 10),
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