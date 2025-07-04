// lib/filtered_shop_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/likes_service.dart'; // Import LikesService
import 'services/shop_service.dart'; // Import ShopService for fetching items
import 'liked_items_screen.dart'; // For navigation
import 'services/profile_service.dart';
import 'item_screen.dart'; // Import ItemScreen
import 'config.dart'; // Import Config

// Define FilterType if not in a separate file
enum FilterType { category, brand }

// Placeholder Item Data Model
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String category; // apparel_type in database
  final String userName;
  final String price;
  final String? imageUrl; // path in database
  bool isFavorite;
  final String? purchaseLink; // URL to purchase the item
  final String color;
  final String size;
  final String occasion;
  final String gender;
  final String subcategory;
  final String brand;
  final String? source; // 'closet' or 'shop' for AI stylist recommendations
  final String? path3d; // path_3d in database

  ShopItem({
    required this.id,
    required this.name,
    this.description = "",
    required this.category,
    required this.userName,
    required this.price,
    this.imageUrl,
    this.isFavorite = false,
    this.purchaseLink,
    this.color = "",
    this.size = "",
    this.occasion = "",
    this.gender = "",
    this.subcategory = "",
    this.brand = "",
    this.source, // optional
    this.path3d, // optional
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'].toString(),
      name: json['subtype'] ?? json['apparel_type'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['apparel_type'] ?? json['category'] ?? '',
      userName: json['brand'] ?? json['userName'] ?? json['user_name'] ?? '',
      price: json['price']?.toString() ?? '',
      imageUrl: json['path'] ?? json['imageUrl'],
      isFavorite: json['isFavorite'] ?? false,
      purchaseLink: json['purchase_link'] ?? json['purchaseLink'],
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      occasion: json['occasion'] ?? '',
      gender: json['gender'] ?? '',
      subcategory: json['subcategory'] ?? '',
      brand: json['brand'] ?? '',
      source: json['source'],
      path3d: json['path_3d'],
    );
  }

  ShopItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? userName,
    String? price,
    String? imageUrl,
    bool? isFavorite,
    String? purchaseLink,
    String? color,
    String? size,
    String? occasion,
    String? gender,
    String? subcategory,
    String? brand,
    String? source,
    String? path3d,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      userName: userName ?? this.userName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      purchaseLink: purchaseLink ?? this.purchaseLink,
      color: color ?? this.color,
      size: size ?? this.size,
      occasion: occasion ?? this.occasion,
      gender: gender ?? this.gender,
      subcategory: subcategory ?? this.subcategory,
      brand: brand ?? this.brand,
      source: source ?? this.source,
      path3d: path3d ?? this.path3d,
    );
  }
}


class FilteredShopPage extends StatefulWidget {
  final String filterTitle; // e.g., "Clothing", "Dodici"
  final FilterType filterType; // To know how to filter
  final String? token; // Changed to nullable String?
  final int userId; // userId is now required

  const FilteredShopPage({
    required this.filterTitle,
    required this.filterType,
    this.token, // Make token optional
    required this.userId,
    super.key,
  });

  @override
  State<FilteredShopPage> createState() => _FilteredShopPageState();
}

class _FilteredShopPageState extends State<FilteredShopPage> {
  late LikesService _likesService;
  late ShopService _shopService;

  List<ShopItem> _allItems = []; // Remove hardcoded items, start with empty list
  List<ShopItem> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _likesService = LikesService(token: widget.token ?? ''); // Handle nullable token
    _shopService = ShopService(token: widget.token ?? ''); // Initialize shop service
    _fetchItems();
  }

  // Fetch all items from backend
  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get items from the backend
      final items = await _shopService.getShopItems();

      if (mounted) {
        setState(() {
          _allItems = items;
          _filterItems(); // Apply filters after getting items
          _isLoading = false;
        });

        // Load liked status after getting items
        _loadLikedStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading items: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Apply filters based on the selected filter type and title
  void _filterItems() {
    if (widget.filterType == FilterType.category && widget.filterTitle.toLowerCase() == 'all') {
      _filteredItems = List.from(_allItems); // Show all if category is "All"
    } else if (widget.filterType == FilterType.category && widget.filterTitle.toLowerCase() == 'clothing') {
      // Example: Combine multiple categories for "Clothing"
      _filteredItems = _allItems.where((item) =>
      item.category.toLowerCase() == 'jacket' ||
          item.category.toLowerCase() == 'top' ||
          item.category.toLowerCase() == 'dress' // Add other clothing types
      ).toList();
    }
    else if (widget.filterType == FilterType.category) {
      _filteredItems = _allItems.where((item) =>
      item.category.toLowerCase() == widget.filterTitle.toLowerCase()
      ).toList();
    } else { // FilterType.brand
      _filteredItems = _allItems.where((item) =>
      item.userName.toLowerCase() == widget.filterTitle.toLowerCase()
      ).toList();
    }

    // After category/brand filtering, apply search filter if needed
    if (_searchQuery.isNotEmpty) {
      _filteredItems = _filteredItems.where((item) =>
          item.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  Future<void> _loadLikedStatus() async {
    try {
      final profileService = ProfileService(token: widget.token ?? '');
      final favorites = await profileService.getFavorites();
      final favoriteIds = favorites.map<String>((fav) {
        // Support both {id, item_id, item: {id}} structures
        if (fav['item_id'] != null) return fav['item_id'].toString();
        if (fav['id'] != null) return fav['id'].toString();
        if (fav['item'] != null && fav['item']['id'] != null) return fav['item']['id'].toString();
        return '';
      }).toSet();
      if (mounted) {
        setState(() {
          for (var item in _allItems) {
            item.isFavorite = favoriteIds.contains(item.id);
          }
          for (var item in _filteredItems) {
            item.isFavorite = favoriteIds.contains(item.id);
          }
        });
      }
    } catch (e) {
    }
  }

  void _toggleFavorite(String itemId) async {
    final profileService = ProfileService(token: widget.token!);
    final item = _allItems.firstWhere((item) => item.id == itemId);
    final newFavoriteState = !item.isFavorite;
    setState(() {
      item.isFavorite = newFavoriteState;
      final filteredIndex = _filteredItems.indexWhere((item) => item.id == itemId);
      if (filteredIndex != -1) {
        _filteredItems[filteredIndex].isFavorite = newFavoriteState;
      }
    });
    bool success = false;
    try {
      success = await profileService.toggleFavorite(itemId);
      if (!success && mounted) {
        setState(() {
          item.isFavorite = !newFavoriteState;
          final filteredIndex = _filteredItems.indexWhere((item) => item.id == itemId);
          if (filteredIndex != -1) {
            _filteredItems[filteredIndex].isFavorite = !newFavoriteState;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite status')),
        );
      }
    } catch (e) {
      setState(() {
        item.isFavorite = !newFavoriteState;
        final filteredIndex = _filteredItems.indexWhere((item) => item.id == itemId);
        if (filteredIndex != -1) {
          _filteredItems[filteredIndex].isFavorite = !newFavoriteState;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorite status')),
      );
    }
  }

  void _checkAiMatch(String itemId) async {
    try {
      final result = await _shopService.checkAiMatch(itemId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? 'AI Match check completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking AI match: $e')),
      );
    }
  }

  void _visitStore(ShopItem item) async {
    // Open the purchase link URL if available
    if (item.purchaseLink != null && item.purchaseLink!.isNotEmpty) {
      final Uri url = Uri.parse(item.purchaseLink!);
      try {
        final canLaunch = await canLaunchUrl(url);
        if (canLaunch) {
          final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
          if (!launched) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open store URL: ${item.purchaseLink}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open store URL: ${item.purchaseLink}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening store URL: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store link available for this item')),
      );
    }
  }

  void _navigateToLikedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikedItemsScreen(token: widget.token!),
      ),
    ).then((_) => _loadLikedStatus()); // Refresh liked status when returning
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo'; // Ensure font is set up

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton( // Back arrow
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text( // Dynamic Title
          widget.filterTitle, // Display category or brand name
          style: const TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add favorites button
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 29, color: Colors.black),
            onPressed: _navigateToLikedItems,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column( // Use Column to stack Info Card and Grid
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 8.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterItems();
                  });
                },
                style: TextStyle(fontSize: 15, fontFamily: defaultFontFamily),
                decoration: InputDecoration(
                  hintText: "Search items by name",
                  hintStyle: TextStyle(
                    fontFamily: defaultFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.02 * 15,
                    color: Colors.black.withOpacity(0.65),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 13.0, right: 10.0),
                    child: Icon(Icons.search, size: 21, color: Colors.black.withOpacity(0.65)),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Item Grid Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red[600], fontFamily: defaultFontFamily),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchItems,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
                : _filteredItems.isEmpty
                ? Center( // Message when no items match filter
              child: Text(
                "No items found for '${widget.filterTitle}'",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: defaultFontFamily),
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchItems,
              child: GridView.builder( // Display items in a grid
                padding: const EdgeInsets.all(16.0), // Padding around the grid
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  crossAxisSpacing: 16.0, // Horizontal spacing
                  mainAxisSpacing: 16.0, // Vertical spacing
                  childAspectRatio: 0.55, // Adjust aspect ratio (width / height) for item card + text below
                ),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildShopItemCard(
                    context: context,
                    item: item,
                    fontFamily: defaultFontFamily,
                    onFavoriteTap: () => _toggleFavorite(item.id),
                    onAiTap: () => _checkAiMatch(item.id),
                    onBagTap: () => _visitStore(item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Builds a card for a single shop item in the grid
  Widget _buildShopItemCard({
    required BuildContext context,
    required ShopItem item,
    required String fontFamily,
    VoidCallback? onFavoriteTap,
    VoidCallback? onAiTap,
    VoidCallback? onBagTap})
  {
    return GestureDetector(
      onTap: () async {
        // Log item click event
        if (widget.token != null) {
          await ProfileService.logItemEvent(
            itemId: int.parse(item.id),
            userId: widget.userId,
            eventType: 'item_click',
            token: widget.token!,
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(item: item, token: widget.token, userId: widget.userId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Card with Image and Overlays
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.imageUrl != null
                          ? Image.network(
                        _buildImageUrl(item.imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey)),
                      )
                          : const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey)),
                    ),
                  ),
                  Positioned(top: 8, left: 8,
                      child: _buildItemOverlayButton(
                          icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          iconColor: item.isFavorite ? Colors.red : Colors.black.withOpacity(0.7),
                          onTap: onFavoriteTap
                      )
                  ),
                  Positioned(bottom: 8, right: 8,
                      child: _buildItemOverlayButton(
                        icon: Icons.shopping_bag_outlined,
                        onTap: () async {
                          // Log visit store event
                          if (widget.token != null) {
                            await ProfileService.logItemEvent(
                              itemId: int.parse(item.id),
                              userId: widget.userId,
                              eventType: 'visit_store',
                              token: widget.token!,
                            );
                          }
                          _visitStore(item);
                        },
                      )
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${item.name} | ${item.userName}",
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02*13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper for the small circular overlay buttons on item cards
  Widget _buildItemOverlayButton({required IconData icon, Color? iconColor, VoidCallback? onTap}) {
    return Material(
      color: Colors.white, // CSS background: #FFFFFF;
      shape: const CircleBorder(),
      elevation: 1.0, // Add shadow
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 33, height: 33, // CSS size: 33px
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
            child: Icon(
              icon,
              size: 20, // Slightly larger than CSS 17px for visibility
              color: iconColor ?? Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  String _buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
    return '${Config.apiUrl}/static/$imageUrl';
  }

} // End _FilteredShopPageState