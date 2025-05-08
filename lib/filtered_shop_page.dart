// lib/filtered_shop_page.dart

import 'package:flutter/material.dart';
import 'item_screen.dart'; // Import the new item screen

// Define FilterType if not in a separate file
enum FilterType { category, brand }

// Placeholder Item Data Model
// TODO: Replace with your actual Item model
class ShopItem {
  final String id;
  final String name;
  final String description; // Added description field
  final String category; // e.g., "Bag", "Top", "Jacket"
  final String brand;    // e.g., "Dodici", "STPS Streetwear"
  final String price;    // e.g., "750 EGP"
  final String? imageUrl;
  bool isFavorite; // Make it non-final to allow toggling

  ShopItem({
    required this.id,
    required this.name,
    this.description = "", // Default empty description
    required this.category,
    required this.brand,
    required this.price,
    this.imageUrl,
    this.isFavorite = false,
  });
}


class FilteredShopPage extends StatefulWidget {
  final String filterTitle; // e.g., "Clothing", "Dodici"
  final FilterType filterType; // To know how to filter

  const FilteredShopPage({
    required this.filterTitle,
    required this.filterType,
    super.key,
  });

  @override
  State<FilteredShopPage> createState() => _FilteredShopPageState();
}

class _FilteredShopPageState extends State<FilteredShopPage> {

  // --- Placeholder Item Data ---
  // TODO: Replace with actual data fetching logic based on widget.filterType and widget.filterTitle
  // Made _allItems non-final to allow modification of isFavorite
  final List<ShopItem> _allItems = [
    ShopItem(id: 'item1', name: 'Elegant white bag', description: "A stylish white bag perfect for evening events.", category: 'Bag', brand: 'Dodici', price: '750 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item2', name: 'Cool Jacket', description: "Streetwear style jacket with a modern fit.", category: 'Jacket', brand: 'STPS Streetwear', price: '1200 EGP', isFavorite: true, imageUrl: null),
    ShopItem(id: 'item3', name: 'Comfy Tee', description: "Soft cotton t-shirt for everyday wear.", category: 'Top', brand: 'Dodici', price: '400 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item4', name: 'Stylish Sneakers', description: "Comfortable and fashionable sneakers.", category: 'Shoes', brand: 'Ravello', price: '950 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item5', name: 'Black Trousers', description: "Classic black trousers, versatile for many occasions.", category: 'Pants', brand: 'STPS Streetwear', price: '800 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item6', name: 'Evening Dress', description: "Elegant dress for formal gatherings.", category: 'Dress', brand: 'Hasnaa Designs', price: '2500 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item7', name: 'Elegant Green bag', description: "A unique green bag to make a statement.", category: 'Bag', brand: 'Dodici', price: '750 EGP', isFavorite: false, imageUrl: null),
    ShopItem(id: 'item8', name: 'Elegant dark bag', description: "A sophisticated dark-colored bag.", category: 'Bag', brand: 'Dodici', price: '750 EGP', isFavorite: false, imageUrl: null),
  ];
  // --- End Placeholder Data ---

  List<ShopItem> _filteredItems = [];
  bool _isLoading = false; // For future async loading

  @override
  void initState() {
    super.initState();
    _fetchAndFilterItems();
  }

  void _fetchAndFilterItems() {
    // Simulate loading and filtering
    setState(() { _isLoading = true; });
    // TODO: Replace with actual async data fetching
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        if (widget.filterType == FilterType.category && widget.filterTitle.toLowerCase() == 'all') {
          _filteredItems = List.from(_allItems); // Show all if category is "All"
        } else if (widget.filterType == FilterType.category && widget.filterTitle.toLowerCase() == 'clothing') {
          // Example: Combine multiple categories for "Clothing"
          _filteredItems = _allItems.where((item) =>
          item.category.toLowerCase() == 'jacket' ||
              item.category.toLowerCase() == 'top' ||
              item.category.toLowerCase() == 'pants' || // Added pants
              item.category.toLowerCase() == 'dress' // Add other clothing types
          ).toList();
        }
        else if (widget.filterType == FilterType.category) {
          _filteredItems = _allItems.where((item) =>
          item.category.toLowerCase() == widget.filterTitle.toLowerCase()
          ).toList();
        } else { // FilterType.brand
          _filteredItems = _allItems.where((item) =>
          item.brand.toLowerCase() == widget.filterTitle.toLowerCase()
          ).toList();
        }
        _isLoading = false;
      });
    });
  }

  // Updated _toggleFavorite to ensure both lists are potentially updated
  void _toggleFavorite(String itemId) {
    setState(() {
      final globalIndex = _allItems.indexWhere((item) => item.id == itemId);
      if (globalIndex != -1) {
        final bool currentStatus = _allItems[globalIndex].isFavorite;
        _allItems[globalIndex].isFavorite = !currentStatus;

        // Update the item in the filtered list as well, if it exists there
        final filteredIndex = _filteredItems.indexWhere((item) => item.id == itemId);
        if (filteredIndex != -1) {
          _filteredItems[filteredIndex].isFavorite = !currentStatus;
        }
      }
    });
    // TODO: Persist favorite change to database/backend
    print("Toggled favorite for item $itemId");
  }


  void _checkAiMatch(String itemId) {
    // TODO: Implement AI Match check logic
    print("Check AI Match tapped for item $itemId");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI Match Check needed for Item $itemId')),
    );
  }

  void _addToBag(String itemId) {
    // TODO: Implement Add to Bag logic
    print("Add to Bag tapped for item $itemId");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add to Bag needed for Item $itemId')),
    );
  }

  // *** ADDED: Navigation Function ***
  void _navigateToItemDetail(ShopItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemScreen(item: item),
      ),
    ).then((_) {
      // This .then() block executes when returning from ItemScreen
      // We call setState to refresh the filtered list in case the
      // favorite status was changed on the detail screen.
      // NOTE: This relies on the ItemScreen modifying the `isFavorite`
      //       property of the ShopItem object it received.
      //       A more robust solution uses state management (Provider, Riverpod).
      setState(() {
        // Re-filter or just rebuild to reflect potential changes
        // For simplicity, just triggering a rebuild here.
        // If using proper state management, this might not be needed.
      });
    });
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
        // Removed heart action icon from this AppBar based on CSS
      ),
      body: Column( // Use Column to stack Info Card and Grid
        children: [
          // AI Stylist Info Card (CSS: Rectangle 107)
          _buildAiStylistInfoCard(context, widget.filterTitle, defaultFontFamily),

          // Item Grid Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? Center( // Message when no items match filter
              child: Text(
                "No items found for '${widget.filterTitle}'",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: defaultFontFamily),
              ),
            )
                : GridView.builder( // Display items in a grid
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
                // *** UPDATED: Wrap card in InkWell for navigation ***
                return InkWell(
                  onTap: () => _navigateToItemDetail(item),
                  child: _buildShopItemCard( // The card itself
                    context: context,
                    item: item,
                    fontFamily: defaultFontFamily,
                    // Pass button callbacks directly
                    onFavoriteTap: () => _toggleFavorite(item.id),
                    onAiTap: () => _checkAiMatch(item.id),
                    onBagTap: () => _addToBag(item.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Builds the informational card about shopping with AI Stylist
  Widget _buildAiStylistInfoCard(BuildContext context, String filterName, String fontFamily) {
    // Use filterName to customize text
    String aiTitle = "Shop $filterName with your AI Stylist";
    // Placeholder for the icon mentioned in the description text
    Widget embeddedIcon = Container(
      width: 26, height: 26, // CSS size
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.symmetric(horizontal: 2.0), // Space around icon
      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), // CSS style
      // TODO: Replace with actual logo asset Image.asset('assets/images/logo_small_placeholder.png'...)
      child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 10.0), // Match CSS left/right, add vertical margin
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Internal padding
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EE), // CSS background
        borderRadius: BorderRadius.circular(5), // CSS border-radius
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AI Logo Placeholder
          // TODO: Use actual AI logo if available
          const Icon(Icons.smart_toy_outlined, size: 30, color: Colors.black), // Simplified representation
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( // Title Text
                  aiTitle,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 20, color: Colors.black),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description with embedded icon - using RichText
                RichText(
                  text: TextSpan(
                      style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black.withOpacity(0.9), height: 1.2),
                      children: [
                        const TextSpan(text: "Tap the "),
                        // WidgetSpan embeds the icon within the text flow
                        WidgetSpan(child: embeddedIcon, alignment: PlaceholderAlignment.middle),
                        const TextSpan(text: " to see if the item matches your closet!"),
                      ]
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Trailing Icon (CSS: image 110)
          // TODO: Replace with specific Image.asset if needed
          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
        ],
      ),
    );
  }

  // Builds a card for a single shop item in the grid
  // Now accepts callbacks for the overlay buttons
  Widget _buildShopItemCard({
    required BuildContext context,
    required ShopItem item,
    required String fontFamily,
    VoidCallback? onFavoriteTap,
    VoidCallback? onAiTap,
    VoidCallback? onBagTap})
  {
    // No InkWell needed here anymore, it's handled in the GridView.builder
    return Column( // Column for Card + Text below
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Card with Image and Overlays
        Expanded( // Allow card to expand vertically
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3), // CSS background: #F3F3F3;
              borderRadius: BorderRadius.circular(10), // CSS border-radius: 10px;
            ),
            child: Stack(
              children: [
                // --- Item Image ---
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    // TODO: Replace placeholder with actual Image widget
                    child: item.imageUrl != null
                        ? Center(child: Text("Img for ${item.id}", style: const TextStyle(color: Colors.grey)))
                    //? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: ...)
                        : const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey)),
                  ),
                ),
                // --- Overlay Buttons ---
                // Favorite Button (Top-Left)
                Positioned(top: 8, left: 8,
                    child: _buildItemOverlayButton(
                        icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: item.isFavorite ? Colors.red : Colors.black.withOpacity(0.7),
                        onTap: onFavoriteTap // Use passed callback
                    )
                ),
                // AI Match Button (Top-Right)
                Positioned(top: 8, right: 8,
                    child: _buildItemOverlayButton(
                        icon: Icons.smart_toy_outlined, // Placeholder for AI check/hanger icon
                        onTap: onAiTap // Use passed callback
                    )
                ),
                // Add To Bag Button (Bottom-Right)
                Positioned(bottom: 8, right: 8,
                    child: _buildItemOverlayButton(
                        icon: Icons.shopping_bag_outlined, // Placeholder for hanger/bag icon
                        onTap: onBagTap // Use passed callback
                    )
                ),
              ],
            ),
          ),
        ),
        // Text Details Below Card
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0), // Add some padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( // Category Text (CSS: Bag)
                item.category,
                style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*13),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text( // Name | Brand Text
                "${item.name} | ${item.brand}", // Combine name and brand
                style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02*13),
                maxLines: 2, // Allow wrapping
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text( // Price Text
                item.price,
                style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*13),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  // Helper for the small circular overlay buttons on item cards
  // (Keep this helper function as it's used by _buildShopItemCard)
  Widget _buildItemOverlayButton({required IconData icon, Color? iconColor, VoidCallback? onTap}) {
    return Material(
      color: Colors.white, // CSS background: #FFFFFF;
      shape: const CircleBorder(),
      elevation: 1.0, // Add shadow
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap, // Use the provided onTap callback
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

} // End _FilteredShopPageState