// lib/item_screen.dart

import 'package:flutter/material.dart';
import 'filtered_shop_page.dart'; // Import to use ShopItem model and potentially helper widgets

// Placeholder for related item data model (can be the same as ShopItem)
// TODO: Replace with your actual data structure if different
typedef RelatedItem = ShopItem;

class ItemScreen extends StatefulWidget {
  final ShopItem item;

  const ItemScreen({required this.item, super.key});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  late bool _isFavorite; // Local state for favorite status on this screen

  // --- Placeholder Related Item Data ---
  // TODO: Fetch actual related items based on widget.item
  final List<RelatedItem> _relatedItems = [
    ShopItem(id: 'related1', name: 'Matching Pants', category: 'Pants', brand: 'Dodici', price: '600 EGP', imageUrl: null),
    ShopItem(id: 'related2', name: 'Complementary Scarf', category: 'Accessory', brand: 'Style Co', price: '300 EGP', imageUrl: null),
    ShopItem(id: 'related3', name: 'Similar Style Top', category: 'Top', brand: 'STPS Streetwear', price: '450 EGP', imageUrl: null),
    ShopItem(id: 'related4', name: 'Goes With Shoes', category: 'Shoes', brand: 'Ravello', price: '900 EGP', imageUrl: null),
  ];
  // --- End Placeholder Data ---


  @override
  void initState() {
    super.initState();
    // Initialize local favorite state from the passed item
    _isFavorite = widget.item.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      // TODO: IMPORTANT - Update the original item's state in the previous screen's list
      // This often requires passing a callback function back or using a state management solution (Provider, Riverpod, Bloc)
      // For now, we just update the local state and print
      widget.item.isFavorite = _isFavorite; // Update the passed item directly (might not reflect back)
      print("Toggled favorite for item ${widget.item.id} to $_isFavorite");
      // TODO: Persist favorite change to database/backend
    });
  }

  void _checkAiMatch() {
    // TODO: Implement AI Match check logic for the current item
    print("Check AI Match tapped for item ${widget.item.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI Match Check needed for Item ${widget.item.name}')),
    );
  }

  void _generateOutfits() {
    // TODO: Implement Generate Outfits logic
    print("Generate Outfits tapped for item ${widget.item.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generate Outfits needed for Item ${widget.item.name}')),
    );
  }

  void _addToBag() {
    // TODO: Implement Add to Bag logic for the current item
    print("Add to Bag tapped for item ${widget.item.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add to Bag needed for Item ${widget.item.name}')),
    );
  }

  void _viewAiMatches() {
    // TODO: Implement View AI Matches navigation/logic
    print("View AI Matches tapped for item ${widget.item.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to AI Matches for ${widget.item.name}')),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    final String itemTitle = "${widget.item.name} | ${widget.item.brand}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton( // Back arrow (CSS: image 110 position)
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text( // Centered Title (CSS: Result)
          itemTitle, // Display combined name and brand or just name
          style: const TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center, // Ensure centering
        ),
        centerTitle: true, // Center the title widget
        backgroundColor: Colors.white,
        elevation: 0,
        // No specific actions needed in AppBar based on CSS for this screen
      ),
      body: SingleChildScrollView( // Allow content to scroll if it overflows
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.0), // Consistent horizontal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text etc. to the start
            children: [
              const SizedBox(height: 20), // Space from AppBar (approximates top: 132px for rect)

              // --- Main Item Image Area (CSS: Rectangle 113) ---
              _buildImageArea(context, widget.item, defaultFontFamily),

              const SizedBox(height: 20), // Spacing below image area

              // --- Item Details & Generate Button Row ---
              _buildDetailsAndGenerateRow(context, widget.item, defaultFontFamily),

              const SizedBox(height: 25), // Spacing (approx top: 361px for AI card)

              // --- AI Match Info Card (CSS: Rectangle 99) ---
              _buildAiMatchCard(context, defaultFontFamily),

              const SizedBox(height: 20), // Spacing (approx top: 448px for Add to Bag)

              // --- Add to Bag Button (CSS: Button / primary) ---
              _buildAddToBagButton(context),

              const SizedBox(height: 40), // Spacing (approx top: 527px for How to Style)

              // --- How to Style It Section ---
              _buildStylingSection(context, defaultFontFamily),

              const SizedBox(height: 20), // Bottom padding

            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Builds the main image container with overlay buttons
  Widget _buildImageArea(BuildContext context, ShopItem item, String fontFamily) {
    return Container(
      height: 250, // Adjusted height, CSS height 215px seems small for image+buttons
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
              // TODO: Replace placeholder with actual Image widget (CSS: image-removebg-preview (26) 2)
              child: item.imageUrl != null
                  ? Center(child: Text("Img for ${item.id}", style: const TextStyle(color: Colors.grey)))
              //? Image.network(item.imageUrl!, fit: BoxFit.contain, errorBuilder: ...) // Use contain to see full item
                  : const Center(child: Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey)),
            ),
          ),
          // --- Overlay Buttons (Based on CSS positions relative to Rectangle 113) ---
          // Favorite Button (Top-Left - CSS: Ellipse 122, heart--...)
          Positioned(
            top: 8, // Approx from CSS top: 139px vs Rect top: 132px
            left: 8, // Approx from CSS left: 52px vs Rect left: 35px
            child: _buildItemOverlayButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: _isFavorite ? Colors.red : Colors.black.withOpacity(0.7),
              onTap: _toggleFavorite,
            ),
          ),
          // AI Match/Check Button (Top-Right - CSS: Ellipse 121, image 129 - hanger/AI icon?)
          Positioned(
            top: 8, // Approx from CSS top: 139px vs Rect top: 132px
            right: 8, // Approx from CSS left: 345px vs Rect left: 35px + width 354px
            child: _buildItemOverlayButton(
              // Using smart_toy as a placeholder for AI check (CSS showed 'image 129')
              icon: Icons.smart_toy_outlined, // Placeholder icon
              onTap: _checkAiMatch,
            ),
          ),
          // Add To Bag Button (Bottom-Right - Not directly on image in CSS, but common pattern)
          // Let's keep it consistent with the grid view card for now, ignore CSS `hanger (1) 14` position here
          // Positioned(
          //   bottom: 8,
          //   right: 8,
          //   child: _buildItemOverlayButton(
          //     icon: Icons.shopping_bag_outlined,
          //     onTap: _addToBag, // Note: Main button below does this now
          //   ),
          // ),
        ],
      ),
    );
  }

  // Builds the Row containing Item Text details and the Generate Outfits button
  Widget _buildDetailsAndGenerateRow(BuildContext context, ShopItem item, String fontFamily) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
      children: [
        // Item Text Details (Implicit from context, not explicit CSS blocks here)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02 * 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Name and Brand were in AppBar title, maybe just name here or description if available
              Text(
                item.name, // Using name here, full title is in AppBar
                style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 16),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.8), letterSpacing: -0.02*14, height: 1.3),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                item.price,
                style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 16),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10), // Space before button

        // Generate Outfits Button (CSS: Rectangle 84, text, image 130)
        InkWell(
          onTap: _generateOutfits,
          borderRadius: BorderRadius.circular(20), // For splash effect
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFC4BFE2), // CSS background
              borderRadius: BorderRadius.circular(20), // CSS border-radius
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Fit content
              children: [
                // CSS: Text "Generate Outfits"
                Text(
                  "Generate Outfits",
                  style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black),
                ),
                const SizedBox(width: 6),
                // CSS: image 130 (placeholder icon)
                // TODO: Replace with actual asset if available
                const Icon(Icons.auto_awesome_outlined, size: 18, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // Builds the card showing AI match information
  Widget _buildAiMatchCard(BuildContext context, String fontFamily) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2EF), // CSS background: #F6F2EF
        borderRadius: BorderRadius.circular(20), // CSS border-radius: 20px
      ),
      child: Row(
        children: [
          // Left Icon Area (CSS: Ellipse 132, image 173)
          Container(
            width: 54, // CSS width
            height: 50, // CSS height
            decoration: const BoxDecoration(
              color: Color(0xFFD2EAB8), // CSS background: #D2EAB8
              shape: BoxShape.circle, // CSS implies circle/ellipse
            ),
            // TODO: Replace placeholder icon (CSS: image 173)
            child: const Center(child: Icon(Icons.check_circle_outline, size: 29, color: Colors.black54)),
          ),
          const SizedBox(width: 15),

          // Middle Text (CSS: Matches 2 items...)
          Expanded(
            child: Text(
              "Matches 2 items from your closet", // Placeholder text
              style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),

          // Right Button (CSS: Rectangle 100, View text, right-arrow)
          InkWell(
            onTap: _viewAiMatches,
            borderRadius: BorderRadius.circular(15), // Match container border radius
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjust padding
              // width: 78, // CSS width (optional, let it size)
              // height: 41, // CSS height (optional, let it size)
              decoration: BoxDecoration(
                color: Colors.black, // CSS background: #000000
                borderRadius: BorderRadius.circular(15), // CSS border-radius: 15px
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View Text
                  Text(
                    "View",
                    style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 15, color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  // Arrow Icon (CSS: right-arrow (1) 2)
                  // TODO: Replace with actual asset if available
                  const Icon(Icons.arrow_forward_ios, size: 17, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the main Add to Bag button
  Widget _buildAddToBagButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Make button expand horizontally (CSS width: 353px approx full width)
      height: 56, // CSS height: 56px
      child: ElevatedButton(
        onPressed: _addToBag,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // CSS background: #000000
          foregroundColor: Colors.white, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // CSS border-radius: 10px
          ),
          textStyle: const TextStyle( // CSS: Button text style
            fontFamily: 'Inter', // Different font specified in CSS
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // lineHeight: 1.25, // Flutter uses height multiplier
          ),
        ),
        child: const Text("Add to Bag"),
      ),
    );
  }

  // Builds the "How to Style It" section including title and related items list
  Widget _buildStylingSection(BuildContext context, String fontFamily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title (CSS: How to style it)
        Text(
          "How to style it",
          style: TextStyle(fontFamily: fontFamily, fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 23, color: Colors.black),
        ),
        const SizedBox(height: 20), // Spacing before related items

        // Related Items Horizontal List (CSS: Rectangles 104, 105, 106, 107, etc.)
        SizedBox(
          height: 300, // Fixed height for the horizontal list container
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedItems.length,
            itemBuilder: (context, index) {
              final relatedItem = _relatedItems[index];
              // Use a smaller card structure for related items
              return Padding(
                padding: EdgeInsets.only(right: index == _relatedItems.length - 1 ? 0 : 16.0), // Spacing between items
                child: _buildRelatedItemCard(context, relatedItem, fontFamily),
              );
            },
          ),
        ),
        const SizedBox(height: 25), // Spacing before style chips

        // Style Chips/Buttons (CSS: Rectangles 108-111, text, icons)
        _buildStyleChips(context, fontFamily),

      ],
    );
  }

  // Builds a single card for the related items list
  Widget _buildRelatedItemCard(BuildContext context, RelatedItem item, String fontFamily) {
    // Reusing structure similar to _buildShopItemCard but maybe smaller/simpler
    // CSS suggests card width around 200-230px (Rect 104/105)
    return SizedBox(
      width: 180, // Slightly smaller than grid view items
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Card with Image and Overlays (CSS: Rect 106/107)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3), // CSS background: #F3F3F3;
                borderRadius: BorderRadius.circular(10), // CSS border-radius: 10px;
                // CSS: Rect 104/105 imply a shadow, add if needed
                // boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.25), offset: Offset(0, 4))],
              ),
              child: Stack(
                children: [
                  // Image Placeholder (CSS: image-removebg-preview (4) 2, (6) 2 etc)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.imageUrl != null
                          ? Center(child: Text("Img ${item.id}", style: const TextStyle(color: Colors.grey)))
                          : const Center(child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey)),
                    ),
                  ),
                  // Overlay Buttons (CSS: Ellipse 197-200, disable-heart etc.)
                  Positioned(top: 6, left: 6, // Approx CSS pos
                      child: _buildItemOverlayButton(
                          size: 28, // Slightly smaller?
                          iconSize: 17,
                          icon: item.isFavorite ? Icons.favorite : Icons.favorite_border, // Assuming related items can also be favorited
                          iconColor: item.isFavorite ? Colors.red : Colors.black.withOpacity(0.7),
                          onTap: () { /* TODO: Handle favorite toggle for related item */ setState(() {item.isFavorite = !item.isFavorite;});}
                      )
                  ),
                  Positioned(bottom: 6, right: 6, // Approx CSS pos (Ellipse 201, reload icon)
                      child: _buildItemOverlayButton(
                          size: 28,
                          iconSize: 16,
                          icon: Icons.shopping_bag_outlined, // Placeholder - CSS shows reload icon? Maybe "Add this instead"?
                          onTap: () { /* TODO: Handle add related item to bag */ }
                      )
                  ),
                ],
              ),
            ),
          ),
          // Text Details Below Card
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( // Category
                  item.category,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text( // Name | Brand
                  "${item.name} | ${item.brand}",
                  style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: -0.02*12),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text( // Price
                  item.price,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.65), letterSpacing: -0.02*12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Builds the row/wrap of style chips/buttons below related items
  Widget _buildStyleChips(BuildContext context, String fontFamily) {
    // Using Wrap to handle potential overflow on smaller screens
    return Wrap(
      spacing: 12.0, // Horizontal spacing between chips
      runSpacing: 8.0, // Vertical spacing if chips wrap
      children: [
        // CSS: Rectangle 108 (Everyday)
        _buildStyleChip(fontFamily: fontFamily, text: "Everyday", icon: Icons.wb_sunny_outlined, color: const Color(0xFFD2EAB8), onTap: () {/*TODO: Filter/Action*/}),
        // CSS: Rectangle 109 (Items - maybe 'Work' or 'Casual'?)
        _buildStyleChip(fontFamily: fontFamily, text: "Casual", icon: Icons.coffee_outlined, color: const Color(0xFFE6E6E6), onTap: () {/*TODO: Filter/Action*/}),
        // CSS: Rectangle 110 (Party)
        _buildStyleChip(fontFamily: fontFamily, text: "Party", icon: Icons.celebration_outlined, color: const Color(0xFFFED5D9), onTap: () {/*TODO: Filter/Action*/}),
        // CSS: Rectangle 111 (Items - maybe 'Formal'?)
        _buildStyleChip(fontFamily: fontFamily, text: "Formal", icon: Icons.business_center_outlined, color: const Color(0xFFE6E6E6), onTap: () {/*TODO: Filter/Action*/}),
      ],
    );
  }

  // Helper for a single style chip
  Widget _buildStyleChip({
    required String fontFamily,
    required String text,
    required IconData icon,
    required Color color,
    VoidCallback? onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // CSS height 25px implies ~6px vertical padding
        decoration: BoxDecoration(
          color: color, // CSS background
          borderRadius: BorderRadius.circular(20), // CSS border-radius
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Fit content
          children: [
            // CSS: image 107, 108, 109 etc.
            Icon(icon, size: 16, color: Colors.black.withOpacity(0.8)),
            const SizedBox(width: 6),
            // CSS: Text (Everyday, Items, Party)
            Text(
              text,
              style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02*14, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }


  // Helper for the small circular overlay buttons (copied/adapted from filtered_shop_page.dart)
  Widget _buildItemOverlayButton({
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
    double size = 33, // Allow size override (CSS: 33px)
    double iconSize = 20 // Allow icon size override (CSS: 17-25px)
  }) {
    return Material(
      color: Colors.white, // CSS background: #FFFFFF;
      shape: const CircleBorder(),
      elevation: 1.0, // Add shadow
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size, height: size, // Use parameter size
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
            child: Icon(
              icon,
              size: iconSize, // Use parameter icon size
              color: iconColor ?? Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

} // End _ItemScreenState