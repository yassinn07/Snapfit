// lib/local_brands.dart

import 'package:flutter/material.dart';
import 'filtered_shop_page.dart'; // <<<--- ADD IMPORT for navigation

class LocalBrandsPage extends StatelessWidget {
  const LocalBrandsPage({super.key});

  // Placeholder list of brand names
  // TODO: Replace with actual data source
  final List<String> brandNames = const [
    'Dodici', 'STPS Streetwear', 'Hasnaa Designs', 'EIUS eg',
    'Ravello', 'afterhours', 'VAYA Store', 'Roots Collection', 'Simplicity Gallery',
  ];

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton( icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        title: const Text( "Local Brands", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: -0.02 * 25)),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 20.0),
        children: [
          _buildAiStylistInfoCard(context, "Local Brands", defaultFontFamily), // Pass general title
          const SizedBox(height: 30),

          // Brand List Section - Updated Navigation
          ...brandNames.map((name) => _buildBrandRow(
              context: context,
              brandName: name,
              fontFamily: defaultFontFamily,
              // *** UPDATE Navigation Here ***
              onTap: () {
                // Navigate to FilteredShopPage, filtering by this brand name
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FilteredShopPage(
                      filterTitle: name, // Pass brand name as filter title
                      filterType: FilterType.brand // Specify filter type
                  )),
                );
              }
          )
          ).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAiStylistInfoCard(BuildContext context, String filterName, String fontFamily) { Widget embeddedIcon = Container( width: 26, height: 26, padding: const EdgeInsets.all(2), margin: const EdgeInsets.symmetric(horizontal: 2.0), decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16), ); return InkWell( onTap: () { print("AI Stylist Info Card tapped"); }, borderRadius: BorderRadius.circular(5.0), child: Container( padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration( color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(5), ), child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [ const Icon(Icons.smart_toy_outlined, size: 30, color: Colors.black), const SizedBox(width: 15), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( "Shop $filterName with your AI Stylist", style: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 20, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis, ), const SizedBox(height: 5), RichText( text: TextSpan( style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black.withOpacity(0.9), height: 1.2), children: [ const TextSpan(text: "Tap the "), WidgetSpan(child: embeddedIcon, alignment: PlaceholderAlignment.middle), const TextSpan(text: " to see if the item matches your closet!"), ] ), ) ], ), ), const SizedBox(width: 10), const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54), ], ), ), ); }
  Widget _buildBrandRow({required BuildContext context, required String brandName, required String fontFamily, required VoidCallback onTap}) { return ListTile( contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), title: Text( brandName, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 18, color: Colors.black), ), trailing: const Icon( Icons.arrow_forward_ios, size: 15, color: Colors.black54 ), onTap: onTap, ); }

} // End LocalBrandsPage