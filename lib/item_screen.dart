// lib/item_screen.dart

import 'package:flutter/material.dart';
import 'filtered_shop_page.dart'; // Import to use ShopItem model and potentially helper widgets
import 'services/shop_service.dart'; // Import ShopService for fetching items
import 'package:url_launcher/url_launcher.dart';
import 'services/ml_outfit_service.dart'; // Import ML outfit service
import 'services/profile_service.dart'; // Import ProfileService for favorite management
import 'package:shared_preferences/shared_preferences.dart'; // For userId
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'outfit_generation_screen.dart';
import 'config.dart';
import 'services/closet_service.dart';
import '3d_model_viewer.dart'; // Import 3D model viewer
import 'constants.dart' show showThemedSnackBar;

// Placeholder for related item data model (can be the same as ShopItem)
// TODO: Replace with your actual data structure if different
typedef RelatedItem = ShopItem;

// Local extension to access similarity if present in the backend response
extension ShopItemSimilarity on ShopItem {
  double? get similarity {
    try {
      // If the backend includes a similarity field, it will be in the original JSON map
      // This works if ShopItem.fromJson stores the original map as a property (not standard)
      // Otherwise, try to parse from price or description if overloaded, or always return null
      // For now, try to parse from description if it looks like a percentage
      if (description.isNotEmpty && description.contains('similarity:')) {
        final match = RegExp(r'similarity:([0-9.]+)').firstMatch(description);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '') ?? null;
        }
      }
      // If you want to parse from another field, add logic here
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ItemScreen extends StatefulWidget {
  final ShopItem item;
  final String? token;
  final int userId;
  final void Function(bool isFavorite)? onFavoriteChanged;

  const ItemScreen({required this.item, this.token, required this.userId, this.onFavoriteChanged, super.key});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  late bool _isFavorite;
  List<ShopItem> _relatedItems = [];
  bool _isLoadingRelated = true;
  bool _isGeneratingOutfits = false;
  List<ShopItem> _generatedOutfits = [];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
    _fetchRelatedItems();
  }

  Future<void> _fetchRelatedItems() async {
    setState(() { _isLoadingRelated = true; });
    try {
      // Fetch top 5 similar items using CLIP similarity from backend
      final response = await http.get(Uri.parse('${Config.baseUrl}/clothes/similar-items/${widget.item.id}?top_k=5'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _relatedItems = data.map((item) => ShopItem.fromJson(item)).toList();
          _isLoadingRelated = false;
        });
      } else {
        setState(() { _isLoadingRelated = false; });
      }
    } catch (e) {
      setState(() { _isLoadingRelated = false; });
    }
  }

  void _toggleFavorite() async {
    if (widget.token == null || widget.token!.isEmpty) {
      showThemedSnackBar(context, 'You must be logged in to favorite items.', type: 'critical');
      return;
    }
    final profileService = ProfileService(token: widget.token!);
    final newFavoriteState = !_isFavorite;
    setState(() {
      _isFavorite = newFavoriteState;
      widget.item.isFavorite = newFavoriteState;
    });
    bool success = false;
    try {
      success = await profileService.toggleFavorite(widget.item.id);
      if (!success && mounted) {
        setState(() {
          _isFavorite = !newFavoriteState;
          widget.item.isFavorite = !newFavoriteState;
        });
        showThemedSnackBar(context, 'Failed to update favorite status', type: 'critical');
      } else {
        // Notify parent/shop screen if callback is provided
        if (widget.onFavoriteChanged != null) {
          widget.onFavoriteChanged!(_isFavorite);
        }
      }
    } catch (e) {
      setState(() {
        _isFavorite = !newFavoriteState;
        widget.item.isFavorite = !newFavoriteState;
      });
      showThemedSnackBar(context, 'Error updating favorite status', type: 'critical');
    }
  }

  void _generateOutfits() async {
    setState(() {
      _isGeneratingOutfits = true;
    });
    try {
      // Call backend for similarity-based outfit generation
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/ai/recommend-outfit-by-item-id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'item_id': int.parse(widget.item.id),
          'user_id': widget.userId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recs = data['recommendations'] as Map<String, dynamic>;
        List<ShopItem> outfitItems = [widget.item.copyWith(source: 'shop', imageUrl: widget.item.imageUrl)];
        print('DEBUG: AI outfit details:');
        for (var cat in ['top', 'bottom', 'shoes']) {
          final closetRec = recs[cat]?['closet'];
          if (closetRec != null) {
            outfitItems.add(ShopItem.fromJson(closetRec));
            print('  Category: $cat');
            print('    Name: ${closetRec['name']}');
            print('    Score: ${(closetRec['score'] as num?)?.toStringAsFixed(4) ?? 'N/A'}');
            print('    Visual Similarity: ${(closetRec['visual_similarity'] as num?)?.toStringAsFixed(4) ?? 'N/A'}');
            print('    Metadata Score: ${(closetRec['metadata_score'] as num?)?.toStringAsFixed(4) ?? 'N/A'}');
          } else {
            print('  Category: $cat - No closet recommendation');
          }
        }
        print('DEBUG: AI outfit items: ${outfitItems.map((i) => i.name).toList()}');
        setState(() {
          _isGeneratingOutfits = false;
        });
        if (outfitItems.length < 2) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Outfit Generation'),
              content: const Text('Not enough items in your closet to generate an outfit. Please add more items to your closet.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutfitGenerationScreen(
              outfitItems: outfitItems,
              userId: widget.userId,
              processedImageUrl: widget.item.imageUrl,
              token: widget.token,
              originalImagePath: widget.item.imageUrl,
            ),
          ),
        );
        return;
      } else {
        setState(() { _isGeneratingOutfits = false; });
        showThemedSnackBar(context, 'AI outfit generation failed: ${response.body}', type: 'critical');
        return;
      }
    } catch (e) {
      setState(() {
        _isGeneratingOutfits = false;
      });
      showThemedSnackBar(context, 'Error generating outfits: $e', type: 'critical');
    }
  }

  void _visitStore() async {
    // Log visit store event using userId from widget
    if (widget.token != null) {
      await ProfileService.logItemEvent(
        itemId: int.parse(widget.item.id),
        userId: widget.userId,
        eventType: 'visit_store',
        token: widget.token!,
      );
    }
    // Open the purchase link URL if available
    if (widget.item.purchaseLink != null && widget.item.purchaseLink!.isNotEmpty) {
      final Uri url = Uri.parse(widget.item.purchaseLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showThemedSnackBar(context, 'Could not open store URL: ${widget.item.purchaseLink}', type: 'critical');
      }
    } else {
      showThemedSnackBar(context, 'No store link available for this item', type: 'normal');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    final String itemTitle = "${widget.item.name} | ${widget.item.userName}";

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

              // --- AI Match Info Card removed ---

              // --- Related Items Section ---
              const SizedBox(height: 30),
              Text(
                "You may also like",
                style: TextStyle(fontFamily: defaultFontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 12),
              _isLoadingRelated
                  ? const Center(child: CircularProgressIndicator())
                  : _relatedItems.isEmpty
                  ? const Text("No related items found.")
                  : SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _relatedItems.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final related = _relatedItems[index];
                    return _buildRelatedItemCard(context, related, defaultFontFamily);
                  },
                ),
              ),

              const SizedBox(height: 20), // Spacing (approx top: 448px for Add to Bag)

              // --- Visit Store Button (formerly Add to Bag) ---
              _buildVisitStoreButton(context),

              const SizedBox(height: 40), // Spacing (approx top: 527px for How to Style)

              // --- You may also like Section ---
              // (Removed redundant section)
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
    // Debug: Print the path3d value and button visibility
    print('DEBUG: Item path3d value: "${item.path3d}"');
    print('DEBUG: Item path3d is null: ${item.path3d == null}');
    print('DEBUG: Item path3d is empty: ${item.path3d?.isEmpty}');
    print('DEBUG: Should show 3D button: ${item.path3d != null && item.path3d!.isNotEmpty && item.path3d!.toLowerCase().endsWith('.glb')}');
    print('DEBUG: Item ID: ${item.id}, Name: ${item.name}');

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
              child: item.imageUrl != null
                  ? Image.network(_buildImageUrl(item.imageUrl), fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey)))
                  : const Center(child: Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey)),
            ),
          ),
          // Favorite Button (Top-Left)
          Positioned(
            top: 8,
            left: 8,
            child: _buildItemOverlayButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: _isFavorite ? Colors.red : Colors.black.withOpacity(0.7),
              onTap: _toggleFavorite,
            ),
          ),
          // 3D Model Button (Top-Right) - Only show if path3d is a valid .glb file
          if (item.path3d != null && item.path3d!.isNotEmpty && item.path3d!.toLowerCase().endsWith('.glb'))
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1.0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Model3DViewer(
                        modelPath: item.path3d!,
                        itemName: item.name,
                        fontFamily: fontFamily,
                      ),
                    );
                  },
                  child: Container(
                    width: 33,
                    height: 33,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Center(
                      child: Icon(
                        Icons.view_in_ar,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

        // Generate Outfits Button (theme style)
        InkWell(
          onTap: _isGeneratingOutfits ? null : _generateOutfits,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD55F5F),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isGeneratingOutfits
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.auto_awesome_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isGeneratingOutfits ? "Generating..." : "Generate Outfits",
                  style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 15, color: Colors.white),
                ),
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
            onTap: _generateOutfits,
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

  // Builds the Visit Store button (formerly Add to Bag)
  Widget _buildVisitStoreButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Make button expand horizontally (CSS width: 353px approx full width)
      height: 56, // CSS height: 56px
      child: ElevatedButton(
        onPressed: _visitStore,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD55F5F),
          foregroundColor: Colors.white, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // CSS border-radius: 10px
          ),
          textStyle: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        child: const Text("Visit Store"),
      ),
    );
  }

  // Builds the "You may also like" section including title and related items list
  Widget _buildStylingSection(BuildContext context, String fontFamily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title (CSS: You may also like)
        Text(
          "You may also like",
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              item: item,
              token: widget.token,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 180,
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
                            ? Image.network(_buildImageUrl(item.imageUrl), fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey)))
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
                    "${item.name} | ${item.userName}",
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

  String _buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
    return '${Config.baseUrl}/static/$imageUrl';
  }

  // Function to show 3D model viewer
  void _show3DModel() {
    final String? modelPath = widget.item.path3d;
    if (modelPath == null || modelPath.isEmpty || !modelPath.toLowerCase().endsWith('.glb')) {
      // No 3D model available for this item
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('3D Model'),
          content: const Text('3D model not available for this item.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    // Show the 3D model viewer
    show3DModelViewer(
      context,
      modelPath,
      widget.item.name,
      'Archivo',
    );
  }

} // End _ItemScreenState