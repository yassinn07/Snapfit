// lib/my_outfits.dart

import 'package:flutter/material.dart';
// import 'dart:math'; // Example if needed for random data later

// Placeholder data structure for an outfit
// TODO: Replace with your actual Outfit model
class Outfit {
  final String id;
  final List<String> itemImageUrls; // URLs/Paths for items IN the outfit
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

  const MyOutfitsPage({this.initialFilter, super.key});

  @override
  State<MyOutfitsPage> createState() => _MyOutfitsPageState();
}

class _MyOutfitsPageState extends State<MyOutfitsPage> {
  late String selectedFilter;
  late PageController _pageController;

  // --- Placeholder Outfit Data ---
  // TODO: Replace with actual data fetching based on user's closet/AI generation
  final List<Outfit> _allOutfits = [
    Outfit(id: 'o1', itemImageUrls: ['item_placeholder1.png', 'item_placeholder2.png'], tags: ['Everyday', 'Work'], isFavorite: true),
    Outfit(id: 'o2', itemImageUrls: ['item_placeholder3.png', 'item_placeholder4.png'], tags: ['Party', 'Weekend']),
    Outfit(id: 'o3', itemImageUrls: ['item_placeholder5.png', 'item_placeholder6.png'], tags: ['Workout']),
    Outfit(id: 'o4', itemImageUrls: ['item_placeholder1.png', 'item_placeholder4.png'], tags: ['Everyday']),
    // *** FIX: Corrected syntax from "Outfit:" to "Outfit(" ***
    Outfit(id: 'o5', itemImageUrls: ['item_placeholder2.png', 'item_placeholder5.png'], tags: ['Work']),
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
    _filterOutfits();
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

  void _toggleFavorite(String outfitId) {
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
    // TODO: Persist favorite change
    print("Toggled favorite for outfit $outfitId");
  }

  void _regenerateOutfit(String outfitId) {
    // TODO: Implement logic
    print("Regenerate tapped for outfit $outfitId");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Regenerate action needed for Outfit $outfitId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

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

          // Outfit Display Area (PageView)
          Expanded(
            child: _filteredOutfits.isEmpty
                ? Center(
              child: Text(
                "No outfits found for '$selectedFilter'",
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: defaultFontFamily),
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
                    onReloadTap: () => _regenerateOutfit(outfit.id),
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
              // TODO: Display actual outfit item images overlayed here using outfit.itemImageUrls
              child: const Center(child: Icon(Icons.checkroom_outlined, size: 100, color: Colors.grey)),
            ),
          ),
          // TODO: Positioned Item Images here
          Positioned( top: 30, left: 30, // Like/Unlike Button
            child: _buildCardIconButton( icon: outfit.isFavorite ? Icons.favorite : Icons.favorite_border, iconColor: outfit.isFavorite ? Colors.red : Colors.black, onTap: onFavoriteTap, size: 57, iconSize: 29, ),
          ),
          Positioned( bottom: 30, right: 30, // Reload/Regenerate Button
            child: _buildCardIconButton( icon: Icons.refresh, onTap: onReloadTap, size: 57, iconSize: 29, ),
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