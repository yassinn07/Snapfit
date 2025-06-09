// lib/my_outfits.dart

import 'package:flutter/material.dart';
// import 'dart:math'; // Example if needed for random data later
import 'services/outfit_service.dart'; // Import the outfit service

// Outfit model representing a complete outfit
class Outfit {
  final String id;
  final List<String> itemImageUrls; // URLs/Paths for top, bottom, shoes in order
  final List<String> tags; // e.g., ["Everyday", "Work", "Summer"]
  bool isFavorite;

  Outfit({
    required this.id,
    required this.itemImageUrls,
    required this.tags,
    this.isFavorite = false,
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
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _filteredOutfits.length,
                    itemBuilder: (context, index) {
                      final outfit = _filteredOutfits[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
                        child: _buildOutfitDisplayCard(
                          context: context,
                          outfit: outfit,
                          fontFamily: defaultFontFamily,
                          onFavoriteTap: () => _toggleFavorite(outfit.id),
                          onReloadTap: () => _deleteOutfit(outfit.id),
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

  Widget _buildOutfitDisplayCard({required BuildContext context, required Outfit outfit, required String fontFamily, VoidCallback? onFavoriteTap, VoidCallback? onReloadTap}) {
    return Container(
      decoration: BoxDecoration( color: const Color(0xFFFDFDFD), borderRadius: BorderRadius.circular(5), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)) ],),
      child: Stack(
        children: [
          Positioned.fill( // Inner Grey Background
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          // Display outfit item images
          if (outfit.itemImageUrls.isNotEmpty) ...[
            // Top item (positioned at the top)
            if (outfit.itemImageUrls.length > 0)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                height: 150,
                child: Image.network(
                  outfit.itemImageUrls[0],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading top image: $error');
                    return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                  },
                ),
              ),
            // Bottom item (positioned in the middle)
            if (outfit.itemImageUrls.length > 1)
              Positioned(
                top: 180,
                left: 0,
                right: 0,
                height: 150,
                child: Image.network(
                  outfit.itemImageUrls[1],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading bottom image: $error');
                    return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                  },
                ),
              ),
            // Shoes (positioned at the bottom)
            if (outfit.itemImageUrls.length > 2)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                height: 100,
                child: Image.network(
                  outfit.itemImageUrls[2],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading shoes image: $error');
                    return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                  },
                ),
              ),
          ] else
            Positioned.fill(
              child: Center(child: Icon(Icons.checkroom_outlined, size: 100, color: Colors.grey)),
            ),
          Positioned( top: 30, left: 30, // Like/Unlike Button
            child: _buildCardIconButton( icon: outfit.isFavorite ? Icons.favorite : Icons.favorite_border, iconColor: outfit.isFavorite ? Colors.red : Colors.black, onTap: onFavoriteTap, size: 57, iconSize: 29, ),
          ),
          Positioned( bottom: 30, right: 30, // Reload/Regenerate Button
            child: _buildCardIconButton( icon: Icons.delete, onTap: onReloadTap, size: 57, iconSize: 29, ),
          ),
          Positioned( bottom: 30, left: 30, // Tag Display
            child: _buildTagChip(outfit.tags.isNotEmpty ? outfit.tags[0] : "Outfit", fontFamily),
          ),
        ],
      ),
    );
  }

  Widget _buildCardIconButton({required IconData icon, Color? iconColor, VoidCallback? onTap, double size = 33, double iconSize = 17}) {
    return Material( color: Colors.white, shape: const CircleBorder(), elevation: 2.0, shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell( customBorder: const CircleBorder(), onTap: onTap,
        child: Container( width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center( child: Icon( icon, size: iconSize, color: iconColor ?? Colors.black.withOpacity(0.7) )),
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

} // End of _MyOutfitsPageState