// lib/my_outfits.dart

import 'package:flutter/material.dart';
// import 'dart:math'; // Example if needed for random data later
import 'services/outfit_service.dart'; // Import the outfit service
import 'item_screen.dart'; // For shop navigation
import 'filtered_shop_page.dart'; // For ShopItem

// Outfit model representing a complete outfit
class Outfit {
  final String id;
  final List<String> itemImageUrls; // URLs/Paths for top, bottom, shoes in order
  final List<String> tags; // e.g., ["Everyday", "Work", "Summer"]
  bool isFavorite;
  final Map<String, dynamic> top;
  final Map<String, dynamic> bottom;
  final Map<String, dynamic> shoes;

  Outfit({
    required this.id,
    required this.itemImageUrls,
    required this.tags,
    this.isFavorite = false,
    required this.top,
    required this.bottom,
    required this.shoes,
  });
}


class MyOutfitsPage extends StatefulWidget {
  final String? initialFilter; // Category passed from ClosetPage
  final String token; // Add token parameter for user authentication

  const MyOutfitsPage({
    this.initialFilter, 
    required this.token, // Make token required
    super.key
  });

  @override
  State<MyOutfitsPage> createState() => _MyOutfitsPageState();
}

class _MyOutfitsPageState extends State<MyOutfitsPage> {
  late String selectedFilter;
  late PageController _pageController;
  bool _isLoading = true;

  // --- Placeholder Outfit Data ---
  // Initialize with empty list for new users
  final List<Outfit> _allOutfits = [
    // Empty list - no outfits by default for new users
  ];
  // --- End Placeholder Data ---

  List<Outfit> _filteredOutfits = [];

  // Available filter categories
  final List<String> _filterCategories = ["All", "Work", "Workout", "Everyday", "Party", "Weekend"];

  @override
  void initState() {
    super.initState();
    selectedFilter = (widget.initialFilter != null && _filterCategories.contains(widget.initialFilter))
        ? widget.initialFilter!
        : "All";
    _pageController = PageController();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use OutfitService to fetch outfits for the logged-in user
      final outfitService = OutfitService(token: widget.token);
      final outfits = await outfitService.getUserOutfits();

      setState(() {
        _allOutfits.clear();
        _allOutfits.addAll(outfits);
        _isLoading = false;
      });

      // Apply initial filter
      _filterOutfits();
    } catch (e) {
      print('Error loading outfits: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading your outfits'))
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Standard filtering logic using .any()
  void _filterOutfits() {
    setState(() {
      if (selectedFilter == "All") {
        _filteredOutfits = List.from(_allOutfits);
      } else {
        _filteredOutfits = _allOutfits.where((outfit) =>
            outfit.tags.any((tag) => tag.toLowerCase() == selectedFilter.toLowerCase())
        ).toList();
      }
      if (_pageController.hasClients && _pageController.page != 0) {
        _pageController.jumpToPage(0);
      }
    });
  }

  void _toggleFavorite(String outfitId) async {
    setState(() {
      final index = _allOutfits.indexWhere((o) => o.id == outfitId);
      if(index != -1) {
        _allOutfits[index].isFavorite = !_allOutfits[index].isFavorite;
        final filteredIndex = _filteredOutfits.indexWhere((o) => o.id == outfitId);
        if(filteredIndex != -1) {
          _filteredOutfits[filteredIndex].isFavorite = _allOutfits[index].isFavorite;
        }
      }
    });
    
    try {
      // Persist favorite change to backend using OutfitService
      final outfitService = OutfitService(token: widget.token);
      final success = await outfitService.toggleOutfitFavorite(outfitId);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite status'))
        );
      }
    } catch (e) {
      print("Error toggling favorite for outfit $outfitId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating favorite status'))
        );
      }
    }
  }

  void _deleteOutfit(String outfitId) async {
    try {
      // Use OutfitService to delete the outfit
      final outfitService = OutfitService(token: widget.token);
      final success = await outfitService.deleteOutfit(outfitId);
      
      if (success) {
        setState(() {
          final index = _allOutfits.indexWhere((o) => o.id == outfitId);
          if (index != -1) {
            _allOutfits.removeAt(index);
          }
          
          final filteredIndex = _filteredOutfits.indexWhere((o) => o.id == outfitId);
          if (filteredIndex != -1) {
            _filteredOutfits.removeAt(filteredIndex);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outfit removed successfully'))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove outfit'))
          );
        }
      }
    } catch (e) {
      print("Error deleting outfit $outfitId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error removing outfit'))
        );
      }
    }
  }

  // Create a new outfit with specified clothing items
  Future<void> _createOutfit({
    required int topId,
    required int bottomId,
    required int shoesId,
    String? name,
    List<String> tags = const [],
  }) async {
    try {
      final outfitService = OutfitService(token: widget.token);
      final newOutfit = await outfitService.createOutfit(
        topId: topId,
        bottomId: bottomId,
        shoesId: shoesId,
        name: name,
        tags: tags,
      );
      
      if (newOutfit != null) {
        setState(() {
          _allOutfits.add(newOutfit);
          
          // Update filtered outfits if needed
          if (selectedFilter == "All" || 
              newOutfit.tags.any((tag) => tag.toLowerCase() == selectedFilter.toLowerCase())) {
            _filteredOutfits.add(newOutfit);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New outfit created successfully'))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create outfit'))
          );
        }
      }
    } catch (e) {
      print("Error creating outfit: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating outfit'))
        );
      }
    }
  }

  // Helper to normalize image paths
  String normalizeImagePath(String path) => path.replaceAll('\\', '/');

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "My outfits",
            style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "My outfits",
          style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar Section
          _buildFilterBar(defaultFontFamily),

          // Title reflecting current filter
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 10.0),
            child: Text(
              selectedFilter == "All" ? "All Outfits" : "$selectedFilter Outfits",
              style: TextStyle(fontFamily: defaultFontFamily, fontSize: 21, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 21),
            ),
          ),

          // Outfit Display Area
          Expanded(
            child: _filteredOutfits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.checkroom_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No outfits yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            fontFamily: defaultFontFamily
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add items to your closet to see AI-generated outfits",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: defaultFontFamily
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: _filteredOutfits.length,
                    itemBuilder: (context, index) {
                      final outfit = _filteredOutfits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: GestureDetector(
                          onTap: () => _showOutfitDetailModal(context, outfit, defaultFontFamily),
                          child: _buildModernOutfitCard(outfit, defaultFontFamily, onFavoriteTap: () => _toggleFavorite(outfit.id)),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildFilterBar(String fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Text( "${_filteredOutfits.length} Outfit${_filteredOutfits.length == 1 ? '' : 's'}", style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02 * 17)),
          const SizedBox(width: 10),
          Container(height: 20, width: 1, color: Colors.black.withOpacity(0.58)), // Divider
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterCategories.map((category) {
                  bool isSelected = category == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() { selectedFilter = category; });
                          _filterOutfits();
                        }
                      },
                      labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w400, color: isSelected ? Colors.white : Colors.black, letterSpacing: -0.02 * 17),
                      selectedColor: Colors.black, backgroundColor: Colors.grey[200],
                      shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), showCheckmark: false, elevation: isSelected ? 2 : 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOutfitCard(Outfit outfit, String fontFamily, {VoidCallback? onFavoriteTap}) {
    // Modern card: rounded, shadow, theme color, stacked/overlapping images
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Stacked/overlapping images
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (outfit.itemImageUrls.length > 2)
                  Positioned(
                    left: 24,
                    top: 24,
                    child: _buildOutfitItemImage(outfit.itemImageUrls[2], 52, 0.5),
                  ),
                if (outfit.itemImageUrls.length > 1)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _buildOutfitItemImage(outfit.itemImageUrls[1], 60, 0.7),
                  ),
                if (outfit.itemImageUrls.isNotEmpty)
                  _buildOutfitItemImage(outfit.itemImageUrls[0], 68, 1.0),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (outfit.tags.isNotEmpty)
                      _buildTagChip(outfit.tags[0], fontFamily),
                    const Spacer(),
                    IconButton(
                      icon: Icon(outfit.isFavorite ? Icons.favorite : Icons.favorite_border, color: outfit.isFavorite ? Colors.red : Colors.black.withOpacity(0.7)),
                      onPressed: onFavoriteTap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Outfit #${outfit.id}",
                  style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
                ),
                if (outfit.tags.length > 1)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: outfit.tags.skip(1).map((tag) => _buildTagChip(tag, fontFamily)).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitItemImage(String url, double size, double opacity) {
    final String imageUrl = url.startsWith('http')
      ? url
      : 'http://10.0.2.2:8000/static/${normalizeImagePath(url)}';
    print('Loading image: $imageUrl');
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, String fontFamily) {
    Color bgColor;
    switch (tag.toLowerCase()) {
      case 'everyday': bgColor = const Color(0xFFD6E4BA); break;
      case 'work': bgColor = Colors.blueGrey.shade100; break;
      case 'workout': bgColor = Colors.orange.shade100; break;
      case 'party': bgColor = Colors.pink.shade100; break;
      case 'weekend': bgColor = Colors.purple.shade100; break;
      default: bgColor = Colors.grey.shade300;
    }
    // TODO: Add icon logic if needed (CSS shows image 51 for Everyday tag)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration( color: bgColor, borderRadius: BorderRadius.circular(20.0)),
      child: Text( tag, style: TextStyle( fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 17, color: Colors.black)),
    );
  }

  Widget _buildDetailRow(String label, String value, String fontFamily) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailDialog(BuildContext context, Map<String, dynamic> item, String fontFamily) {
    String cleanCategory = (item['apparel_type'] ?? item['category'] ?? '')
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll('0m', '')
        .trim();
    String subcategory = (item['subtype'] ?? '').toString();
    String color = (item['color'] ?? '').toString();
    String size = (item['size'] ?? '').toString();
    String occasion = (item['occasion'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF6F1EE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item['name'] ?? item['subtype'] ?? 'Item Details',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (item['path'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'http://10.0.2.2:8000/static/${normalizeImagePath(item['path'])}',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 18),
                _buildDetailRow('Category', cleanCategory, fontFamily),
                _buildDetailRow('Subcategory', subcategory, fontFamily),
                _buildDetailRow('Color', color, fontFamily),
                _buildDetailRow('Size', size, fontFamily),
                _buildDetailRow('Occasion', occasion, fontFamily),
                const SizedBox(height: 18),
                if (item['source'] == 'shop' || item['purchase_link'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD55F5F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ItemScreen(
                            item: ShopItem(
                              id: (item['id'] ?? '').toString(),
                              name: item['name'] ?? item['subtype'] ?? '',
                              description: item['description'] ?? '',
                              category: cleanCategory,
                              userName: item['user_name'] ?? '',
                              price: item['price'] != null ? item['price'].toString() : '',
                              imageUrl: item['path'],
                              isFavorite: item['is_favorite'] ?? false,
                              purchaseLink: item['purchase_link'],
                              color: color,
                              size: size,
                              occasion: occasion,
                              gender: item['gender'] ?? '',
                              subcategory: subcategory,
                              brand: item['brand'] ?? '',
                              source: 'shop',
                            ),
                            userId: item['owner_id'] ?? 0,
                            token: null,
                          ),
                        ));
                      },
                      child: const Text('Go to Shop'),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOutfitDetailModal(BuildContext context, Outfit outfit, String fontFamily) {
    final items = [outfit.top, outfit.bottom, outfit.shoes];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Outfit Details", style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 22)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < outfit.itemImageUrls.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () => _showItemDetailDialog(context, items[i], fontFamily),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: (() {
                            final String imageUrl = outfit.itemImageUrls[i].startsWith('http')
                              ? outfit.itemImageUrls[i]
                              : 'http://10.0.2.2:8000/static/${normalizeImagePath(outfit.itemImageUrls[i])}';
                            print('Loading image: $imageUrl');
                            return Image.network(
                              imageUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                              ),
                            );
                          })(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (outfit.tags.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: outfit.tags.map((tag) => _buildTagChip(tag, fontFamily)).toList(),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(outfit.isFavorite ? Icons.favorite : Icons.favorite_border, color: outfit.isFavorite ? Colors.red : Colors.black.withOpacity(0.7)),
                    onPressed: () {
                      _toggleFavorite(outfit.id);
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black54),
                    onPressed: () {
                      _deleteOutfit(outfit.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

} // End of _MyOutfitsPageState