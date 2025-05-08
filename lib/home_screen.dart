import 'package:flutter/material.dart';
import 'add_item.dart'; // Import for ClosetPage navigation
import 'my_outfits.dart';
import 'local_brands.dart';
import 'filtered_shop_page.dart';
import 'change_preferences.dart';
import 'my_information_page.dart';
import 'change_password_page.dart';
import 'send_feedback_page.dart';
import 'package:image_picker/image_picker.dart'; // <<< Import image_picker
// import 'dart:ui'; // Needed for ImageFilter if using blur

// ----- Main Navigation Screen -----

class HomeScreen extends StatefulWidget {
  final String token; // ✅ Add this

  const HomeScreen({super.key, required this.token}); // ✅ Update constructor

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- State Variables for User Preferences ---
  String _userFitPreference = "Regular";
  String _userLifestylePreference = "Work, Workout, Everyday, Party";
  String _userSeasonPreference = "Auto";
  String _userAgeGroup = "18-24";
  List<String> _userPreferredColors = ["Blue", "Black"];
  List<String> _userExcludedCategories = ["Skirts"];
  final String _userName = "Jane Doe";
  final String _userEmail = "jane.doe@example.com";
  final String _userPhone = "+1 123 456 7890";
  final String _userInitial = "J";
  final String? _userImageUrl = null;
  // --- End State Variables ---


  static const Color selectedColor = Color(0xFFD55F5F);
  static const Color unselectedColor = Color(0xFF686363);

  // --- Callback function to update preferences ---
  void _updateUserPreferences(Map<String, dynamic> newPreferences) {
    setState(() {
      _userFitPreference = newPreferences['fit'] ?? _userFitPreference;
      _userLifestylePreference = (newPreferences['lifestyle'] as List<String>?)?.join(', ') ?? _userLifestylePreference;
      _userSeasonPreference = newPreferences['season'] ?? _userSeasonPreference;
      _userAgeGroup = newPreferences['ageGroup'] ?? _userAgeGroup;
      _userPreferredColors = List<String>.from(newPreferences['colors'] ?? _userPreferredColors);
      _userExcludedCategories = List<String>.from(newPreferences['exclusions'] ?? _userExcludedCategories);
    });
    print("Preferences updated in HomeScreen state!");
  }
  // --- End Callback function ---


  // --- Build the list of pages dynamically ---
  List<Widget> _buildPages() {
    return [
      HomePage(
        userFitPreference: _userFitPreference,
        userLifestylePreference: _userLifestylePreference,
        userSeasonPreference: _userSeasonPreference,
      ),
      const MyShopPage(),
      const AIStylistPage(), // Use the new AIStylistPage
      const ClosetPage(),
      ProfilePage(
        userInitial: _userInitial,
        userImageUrl: _userImageUrl,
        userName: _userName,
        userEmail: _userEmail,
        userPhone: _userPhone,
        userFitPreference: _userFitPreference,
        userLifestylePreference: _userLifestylePreference,
        userSeasonPreference: _userSeasonPreference,
        userAgeGroup: _userAgeGroup,
        userPreferredColors: _userPreferredColors,
        userExcludedCategories: _userExcludedCategories,
        onPreferencesUpdate: _updateUserPreferences,
      ),
    ];
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = _buildPages();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag, size: 30), label: "My Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy, size: 30), label: "AI Stylist"),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom, size: 30), label: "Closet"),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: "Profile"),
        ],
      ),
    );
  }
}


// ----- Page Definitions -----

// --- HomePage ---
class HomePage extends StatefulWidget {
  final String userFitPreference;
  final String userLifestylePreference;
  final String userSeasonPreference;

  const HomePage({
    required this.userFitPreference,
    required this.userLifestylePreference,
    required this.userSeasonPreference,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> outfits;

  @override
  void initState() {
    super.initState();
    outfits = [
      {'id': '1', 'imageUrl': null, 'tags': ['Everyday', 'Items'], 'isFavorite': false},
      {'id': '2', 'imageUrl': null, 'tags': ['Party'], 'isFavorite': true},
      {'id': '3', 'imageUrl': null, 'tags': ['Workout', 'Items'], 'isFavorite': false},
    ];
  }

  void _toggleFavorite(String outfitId) {
    setState(() {
      final index = outfits.indexWhere((outfit) => outfit['id'] == outfitId);
      if (index != -1) {
        outfits[index]['isFavorite'] = !(outfits[index]['isFavorite'] ?? false);
      }
    });
    // TODO: Persist favorite change
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 6.0, top: 4, bottom: 4),
          child: Image.asset('assets/logo_small.png', errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_outlined, color: Colors.grey)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, size: 29, color: Colors.black), tooltip: 'Wishlist', onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: Text("Check your preferences", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black, fontFamily: defaultFontFamily))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () { final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>(); homeScreenState?._onItemTapped(4); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(68, 30)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [ Text("View", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 14, fontFamily: defaultFontFamily)), SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white)]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(10), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
                child: Column(
                  children: [
                    _buildPreferenceRow(Icons.accessibility_new, "Your fit", widget.userFitPreference, const Color(0xFFF6ECAA)),
                    const SizedBox(height: 15),
                    _buildPreferenceRow(Icons.work_outline, "Life Style", widget.userLifestylePreference, const Color(0xFFCEC7FA)),
                    const SizedBox(height: 15),
                    _buildPreferenceRow(Icons.cloud_outlined, "Season", widget.userSeasonPreference, const Color(0xFFD55F5F)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0, top: 20.0, bottom: 10.0),
              child: Text("My Outfits", style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 23, color: Colors.black, fontFamily: defaultFontFamily)),
            ),
            SizedBox(
              height: 310,
              child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  scrollDirection: Axis.horizontal,
                  itemCount: outfits.length,
                  itemBuilder: (context, index) {
                    final outfit = outfits[index];
                    return _buildOutfitCard(
                      outfitId: outfit['id'] ?? '$index', imageUrl: outfit['imageUrl'], tags: List<String>.from(outfit['tags'] ?? []), isFavorite: outfit['isFavorite'] ?? false,
                      onFavoriteTap: () => _toggleFavorite(outfit['id'] ?? '$index'), onRefreshTap: () { print("Refresh tapped on outfit ${outfit['id']}"); },
                    );
                  }
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String value, Color circleColor) { const String defaultFontFamily = 'Archivo'; return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [ Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor), child: Center(child: Icon(icon, size: 24, color: Colors.black87))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [ Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 14, color: const Color(0xFF221F1B).withOpacity(0.76), fontFamily: defaultFontFamily)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 15, color: const Color(0xFF040404), fontFamily: defaultFontFamily))]))]); }
  Widget _buildOutfitCard({required String outfitId, String? imageUrl, List<String> tags = const [], bool isFavorite = false, VoidCallback? onFavoriteTap, VoidCallback? onRefreshTap}) { const String defaultFontFamily = 'Archivo'; return Container(width: 228, margin: const EdgeInsets.only(right: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Container(height: 272, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)) ]), child: Stack(children: [ Positioned.fill(child: Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(10)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 50, color: Colors.grey), loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator())) : const Icon(Icons.image_outlined, size: 80, color: Colors.grey)))), Positioned(top: 18, left: 18, child: _buildCardIconButton(icon: isFavorite ? Icons.favorite : Icons.favorite_border, iconColor: isFavorite ? Colors.red : Colors.black.withOpacity(0.7), onTap: onFavoriteTap)), Positioned(bottom: 18, right: 18, child: _buildCardIconButton(icon: Icons.refresh, onTap: onRefreshTap))])), const SizedBox(height: 8), if (tags.isNotEmpty) Wrap(spacing: 6.0, runSpacing: 4.0, children: tags.map((tag) => _buildTagChip(tag, defaultFontFamily)).toList())])); }
  Widget _buildCardIconButton({required IconData icon, Color? iconColor, VoidCallback? onTap}) { return Material(color: Colors.white, shape: const CircleBorder(), elevation: 1.0, child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Container(width: 33, height: 33, decoration: const BoxDecoration(shape: BoxShape.circle), child: Center(child: Icon(icon, size: 17, color: iconColor ?? Colors.black.withOpacity(0.7)))))); }
  Widget _buildTagChip(String tag, String fontFamily) { Color bgColor; switch (tag.toLowerCase()) { case 'everyday': bgColor = const Color(0xFFD2EAB8); break; case 'party': bgColor = const Color(0xFFFED5D9); break; case 'items': bgColor = const Color(0xFFE6E6E6); break; default: bgColor = Colors.grey.shade300; } return Container(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.0)), child: Text(tag, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black))); }
}

// --- MyShopPage ---
class MyShopPage extends StatelessWidget {
  const MyShopPage({super.key});
  final List<Map<String, String>> brands = const [ { "name": "Dodici", "logoUrl": "assets/dodici_logo_placeholder.png" }, { "name": "STPS Streetwear", "logoUrl": "assets/stps_logo_placeholder.png", "badgeUrl": "assets/images/badge_placeholder.png" }, { "name": "Ravello", "logoUrl": "assets/ravello_logo_placeholder.png" }, { "name": "Hasnaa Designs", "logoUrl": "assets/hasnaa_logo_placeholder.png" }, { "name": "Style Co", "logoUrl": "assets/styleco_logo_placeholder.png" } ];
  final Map<String, String> exclusiveOffer = const { "title": "Exclusive Offers", "imageUrl": "assets/banner_placeholder.png", "logoUrl": "assets/dodici_logo_placeholder.png" };
  @override Widget build(BuildContext context) { const String defaultFontFamily = 'Archivo'; return Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leadingWidth: 96, leading: Padding(padding: const EdgeInsets.only(left: 6.0), child: Image.asset('assets/logo_remove.png', width: 80, height: 80, errorBuilder: (c,e,s)=>const Icon(Icons.error))), title: const Text("My shop", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black)), centerTitle: true, actions: [ IconButton(icon: const Icon(Icons.favorite_border, size: 29, color: Colors.black), onPressed: () { /* TODO */ }), const SizedBox(width: 16) ]), body: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ const SizedBox(height: 20), _buildSearchBar(defaultFontFamily), const SizedBox(height: 24), _buildShopWithAIBox(context, defaultFontFamily, brands), const SizedBox(height: 24), const Text("Categories", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 23, color: Colors.black)), const SizedBox(height: 16), _buildCategoryRow(context, "All", defaultFontFamily, () => _navigateToFilteredShop(context, "All", FilterType.category)), _buildCategoryRow(context, "Clothing", defaultFontFamily, () => _navigateToFilteredShop(context, "Clothing", FilterType.category)), _buildCategoryRow(context, "Bags", defaultFontFamily, () => _navigateToFilteredShop(context, "Bag", FilterType.category)), _buildCategoryRow(context, "Shoes", defaultFontFamily, () => _navigateToFilteredShop(context, "Shoes", FilterType.category)), _buildCategoryRow(context, "Accessories", defaultFontFamily, () => _navigateToFilteredShop(context, "Accessories", FilterType.category)), const SizedBox(height: 24), _buildSectionHeader(context, "Exclusive Offers", defaultFontFamily, () {/*TODO: View All Offers*/}), const SizedBox(height: 16), _buildOfferBanner(context, defaultFontFamily, exclusiveOffer), const SizedBox(height: 32) ]))); }
  void _navigateToFilteredShop(BuildContext context, String title, FilterType type) { Navigator.push(context, MaterialPageRoute(builder: (context) => FilteredShopPage(filterTitle: title, filterType: type))); }
  Widget _buildSearchBar(String fontFamily) { return Container( height: 48, decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2), ), ], ), child: TextField( style: TextStyle(fontSize: 15, fontFamily: fontFamily), decoration: InputDecoration( hintText: "Search", hintStyle: TextStyle( fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w300, letterSpacing: -0.02 * 15, color: Colors.black.withOpacity(0.65), ), prefixIcon: Padding( padding: const EdgeInsets.only(left: 13.0, right: 10.0), child: Icon(Icons.search, size: 21, color: Colors.black.withOpacity(0.65)), ), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14), ), ), ); }
  Widget _buildSectionHeader(BuildContext context, String title, String fontFamily, VoidCallback onViewAll) { return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 23, color: Colors.black)), TextButton( onPressed: onViewAll, child: Text("View all", style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 15, color: Colors.black.withOpacity(0.65))), ), ], ); }
  Widget _buildShopWithAIBox(BuildContext context, String fontFamily, List<Map<String, String>> brandList) { return Container( padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(5)), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildSectionHeader( context, "Shop with your AI Stylist", fontFamily, () { Navigator.push( context, MaterialPageRoute(builder: (context) => const LocalBrandsPage()), ); } ), const SizedBox(height: 8), Text("Browse local brands you love and check if a piece fits your style and closet before you buy it.", style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 15, color: Colors.black.withOpacity(0.9), height: 1.3)), const SizedBox(height: 20), SizedBox( height: 125, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: brandList.length, itemBuilder: (context, index) { final brand = brandList[index]; return Padding( padding: EdgeInsets.only(right: index == brandList.length -1 ? 0 : 20.0), child: _buildBrandCircle(context, brand['name'] ?? 'Brand', brand['logoUrl'] ?? 'assets/logo_small.png', brand['badgeUrl'], fontFamily), ); }, ), ), ], ), ); }
  Widget _buildBrandCircle(BuildContext context, String name, String logoAsset, String? badgeAsset, String fontFamily) { return Column( mainAxisSize: MainAxisSize.min, children: [ Stack( clipBehavior: Clip.none, children: [ Container( width: 70, height: 70, decoration: BoxDecoration( color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(0.09), width: 1), ), child: Center( child: ClipOval( child: Image.asset( logoAsset, width: 60, height: 60, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 30, color: Colors.grey), ), ), ), ), if (badgeAsset != null && badgeAsset.isNotEmpty) Positioned( top: -3, right: -3, child: Container( width: 25, height: 25, decoration: const BoxDecoration( color: Colors.black, shape: BoxShape.circle, ), child: Center( child: Image.asset( badgeAsset, width: 20, height: 20, errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, size: 15, color: Colors.white), ), ), ), ), ], ), const SizedBox(height: 10), SizedBox( width: 75, child: Text( name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle( fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 13, color: Colors.black.withOpacity(0.9), ), ), ), ], ); }
  Widget _buildCategoryRow(BuildContext context, String title, String fontFamily, VoidCallback onTap) { return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Container( decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.09), blurRadius: 4, offset: const Offset(0, 2), ), ], ), child: Material( color: Colors.transparent, child: InkWell( onTap: onTap, borderRadius: BorderRadius.circular(10), child: SizedBox( height: 48, child: Padding( padding: const EdgeInsets.symmetric(horizontal: 15.0), child: Row( children: [ Expanded( child: Text( title, style: TextStyle( fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 18, color: Colors.black, ), ), ), const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black54), ], ), ), ), ), ), ), ); }
  Widget _buildOfferBanner(BuildContext context, String fontFamily, Map<String, String> offerData) { return Container( height: 162, decoration: BoxDecoration( borderRadius: BorderRadius.circular(10), image: DecorationImage( image: AssetImage(offerData['imageUrl'] ?? 'assets/images/placeholder_banner.png'), fit: BoxFit.cover, onError: (exception, stackTrace) { print("Error loading offer banner image: $exception"); }, ), ), child: Stack( children: [ Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(10), gradient: LinearGradient( colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.6)], begin: Alignment.bottomLeft, end: Alignment.topRight, stops: const [0.0, 0.5, 1.0], ), ), ), Positioned( left: 18, bottom: 12, child: Row( children: [ Container( width: 31, height: 31, decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.black.withOpacity(0.09), width: 1), ), child: Center( child: Padding( padding: const EdgeInsets.all(2.0), child: Image.asset( offerData['logoUrl'] ?? 'assets/logo_small.png', errorBuilder: (context, error, stackTrace) => const Icon(Icons.info, size: 15, color: Colors.grey), ), ), ), ), const SizedBox(width: 10), Text( offerData['title'] ?? 'Special Offer', style: TextStyle( fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 18, color: Colors.white, shadows: [ Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(1,1), blurRadius: 2) ] ), ), ], ), ), ], ), ); }
}

// --- AIStylistPage ---
// Updated implementation based on CSS
class AIStylistPage extends StatefulWidget {
  const AIStylistPage({super.key});

  @override
  State<AIStylistPage> createState() => _AIStylistPageState();
}

class _AIStylistPageState extends State<AIStylistPage> {
  bool _isLoading = false; // State to control loading screen visibility
  final ImagePicker _picker = ImagePicker(); // Initialize image picker

  // --- Updated Function to Use Image Picker ---
  Future<void> _processImageFromCamera() async {
    try {
      // Attempt to pick image from camera
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      // Check if an image was actually picked AND if the widget is still mounted
      if (image != null && mounted) {
        print('Image path: ${image.path}');
        // Set loading state *after* getting the image
        setState(() { _isLoading = true; });

        // --- Simulate API call / Processing ---
        print('Simulating image processing...');
        await Future.delayed(const Duration(seconds: 3)); // Simulate network/processing time
        print('Simulated processing finished.');
        // --- End Simulation ---

        // Check if still mounted after the async delay
        if (!mounted) return;

        // Clear loading state
        setState(() { _isLoading = false; });

        // Show completion message (or navigate to results)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis Complete (Placeholder)')),
        );
        // TODO: Navigate to item analysis result page or show results here

      } else {
        print('No image selected or widget unmounted.');
        // Optionally show a message if no image was selected
        if (mounted && image == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
        }
      }
    } catch (e) {
      print('Error picking/processing image: $e');
      if(mounted) {
        setState(() { _isLoading = false; }); // Ensure loading is turned off on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

  // --- Placeholder Functions for Action Buttons ---
  void _getAdviceOnItem() {
    // TODO: Implement navigation or action for getting advice
    print("Get Advice on Item tapped");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advice on Item - Not Implemented')),
    );
  }

  void _suggestClothing() {
    // TODO: Implement navigation or action for suggesting clothing
    print("Suggest Clothing tapped");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggest Clothing - Not Implemented')),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      // Use Stack to layer background gradients/blurs behind content
      body: Stack(
        children: [
          // --- Background Effects (Approximation) ---
          // Bottom gradient (Rectangle 71)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.84, -0.82), // Approx 7.94% 9.13%
                  radius: 1.5, // Adjust radius to approximate spread
                  colors: [
                    const Color(0xFFFFF9F5).withOpacity(0.1), // rgba(255, 239, 229, 0.1)
                    const Color(0xFFFFFAF7).withOpacity(0.37), // rgba(255, 244, 239, 0.37)
                    const Color(0xFFFFFBF9).withOpacity(0.5), // rgba(255, 247, 244, 0.5)
                  ],
                  stops: const [0.0, 0.6, 0.87], // Match CSS stops
                ),
              ),
            ),
          ),
          // Top blur ellipse (Ellipse 94) - Simplified as another gradient
          Positioned(
            top: 73, // CSS top
            left: 58, // CSS left
            right: MediaQuery.of(context).size.width - 58 - 311, // Calculate right based on width
            height: 241, // CSS height
            child: Container(
              decoration: BoxDecoration(
                // *** FIXED: Use BoxShape.circle or BoxShape.rectangle, not oval directly ***
                shape: BoxShape.rectangle, // Use rectangle and maybe clip later if oval needed
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.65), // Approx 30.55% 17.43%
                  radius: 0.83, // Approx 82.57%
                  colors: [
                    const Color(0xFFEC9797).withOpacity(0.16), // rgba(236, 151, 151, 0.16)
                    const Color(0xFFB77575).withOpacity(0.16), // rgba(183, 117, 117, 0.16)
                    const Color(0xFF865656).withOpacity(0.0), // rgba(134, 86, 86, 0)
                  ],
                  stops: const [0.0, 0.685, 1.0],
                ),
              ),
            ),
          ),

          // --- Main Content Area ---
          SafeArea( // Ensure content is not under status bar etc.
            child: Column(
              children: [
                // --- Custom AppBar ---
                _buildAppBar(context, defaultFontFamily),

                // --- Body Content ---
                Expanded(
                  child: _isLoading
                      ? _buildLoadingView(defaultFontFamily) // Show loading UI
                      : _buildMainContentView(defaultFontFamily), // Show main UI
                ),

                // --- Bottom Input Simulation / Action Bar ---
                // Hide bottom bar when loading? Optional.
                if (!_isLoading) _buildBottomActionBar(context, defaultFontFamily),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Builds the custom AppBar part
  Widget _buildAppBar(BuildContext context, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48), // Spacer
            Expanded(
              child: Text(
                "AI Stylist",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: fontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              tooltip: 'Settings',
              onPressed: () { /* TODO: Implement settings action */ },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the main view when not loading
  Widget _buildMainContentView(String fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Icon(Icons.smart_toy_outlined, size: 60, color: Colors.deepPurple.shade300),
          const SizedBox(height: 30),
          Text("Hi, I’m your personal AI Stylist!", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          const SizedBox(height: 14),
          Text("Lets us explore your Style Formula and Preferences.", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          const SizedBox(height: 4),
          Text("I’m here to bring your style to the next level!", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          Expanded(flex: 3, child: Container(margin: const EdgeInsets.symmetric(vertical: 20), alignment: Alignment.center)), // Chatbot placeholder
          Row(
            children: [
              Expanded(child: _buildActionButton(fontFamily, "Advice on item", _getAdviceOnItem)),
              const SizedBox(width: 18),
              Expanded(child: _buildActionButton(fontFamily, "Suggest clothing for an occasion", _suggestClothing)),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // Builds the loading view
  Widget _buildLoadingView(String fontFamily) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Color(0xFFC4BFE2), shape: BoxShape.circle),
            child: const Center(child: SizedBox(width: 35, height: 35, child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))),
          ),
          const SizedBox(height: 25),
          Text(
            "Analyzing your photos... 1/1\nGive us a few seconds - it won’t take long",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 17, color: Colors.black, height: 1.3),
          ),
        ],
      ),
    );
  }

  // Helper for the bottom action buttons
  Widget _buildActionButton(String fontFamily, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF6F2EF), foregroundColor: Colors.black, elevation: 1, shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(172, 56), padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }

  // Builds the bottom action bar simulating text input and camera
  Widget _buildBottomActionBar(BuildContext context, String fontFamily) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2)) ],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
      ),
      child: Row(
        children: [
          // Camera Button
          InkWell(
            // *** UPDATED: Call _processImageFromCamera ***
            onTap: _processImageFromCamera,
            customBorder: const CircleBorder(),
            child: Container(
              width: 45, height: 45,
              decoration: const BoxDecoration(color: Color(0xFFD55F5F), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // Text Input Simulation
          Expanded(
            child: InkWell(
              onTap: () { print("Chat input tapped"); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat Input - Not Implemented'))); },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.06))),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Take a photo from an item, and let the styling begin!",
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w300, letterSpacing: -0.02 * 13, color: Colors.black.withOpacity(0.65)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// --- ClosetPage ---
class ClosetPage extends StatelessWidget {
  const ClosetPage({super.key});
  void _navigateToMyOutfits(BuildContext context, String? filterCategory) { Navigator.push(context, MaterialPageRoute(builder: (context) => MyOutfitsPage(initialFilter: filterCategory))); }
  @override Widget build(BuildContext context) { int topsCount = 4; int bottomsCount = 3; int totalTops = 4; int totalBottoms = 3; int totalItemsUploaded = topsCount + bottomsCount; int totalItemsRequired = 7; bool isComplete = totalItemsUploaded >= totalItemsRequired; return Scaffold(backgroundColor: Colors.white, body: Padding(padding: const EdgeInsets.only(top: 48.0, left: 16.0, right: 16.0, bottom: 16.0), child: isComplete ? _buildCompleteView(context) : _buildIncompleteView(context, topsCount, bottomsCount, totalTops, totalBottoms, totalItemsUploaded, totalItemsRequired))); }
  Widget _buildIncompleteView(BuildContext context, int topsCount, int bottomsCount, int totalTops, int totalBottoms, int totalItemsUploaded, int totalItemsRequired) { List<String?> outfitImageUrls = [null, null, null]; return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ const SizedBox(height: 24), const Text("My Closet", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Archivo')), const SizedBox(height: 24), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Row(children: [ const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 8), Text("$totalItemsUploaded/$totalItemsRequired ITEMS UPLOADED", style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Archivo'))]), const SizedBox(height: 8), const Text("Add at least 7 items, and your AI stylist will pair them into outfits", style: TextStyle(fontFamily: 'Archivo')), const SizedBox(height: 16), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), minimumSize: const Size(double.infinity, 48)), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemPage())); }, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [ Text("ADD ITEM", style: TextStyle(fontFamily: 'Archivo')), SizedBox(width: 8), Icon(Icons.arrow_forward) ])), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ _buildProgressIndicator(context, "Tops", topsCount, totalTops), _buildProgressIndicator(context, "Bottoms", bottomsCount, totalBottoms) ])])), const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: _buildSmallCategoryCard("Everyday", Icons.calendar_today, Colors.lightGreen)), const SizedBox(width: 10), Expanded(child: _buildSmallCategoryCard("Weekend", Icons.weekend, Colors.pink[200]!)), const SizedBox(width: 10), Expanded(child: _buildSmallCategoryCard("Workout", Icons.fitness_center, Colors.orange[200]!))]), const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text("My Closet Outfits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Archivo')), TextButton(onPressed: () { /* TODO */ }, child: const Text("View all", style: TextStyle(color: Colors.black54, fontFamily: 'Archivo'))) ]), const SizedBox(height: 16), SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: outfitImageUrls.isEmpty ? 1 : outfitImageUrls.length, itemBuilder: (context, index) { if (outfitImageUrls.isEmpty) { return _buildOutfitCardPlaceholder(null); } return _buildOutfitCardPlaceholder(outfitImageUrls[index]); }))])); }
  Widget _buildCompleteView(BuildContext context) { const String defaultFontFamily = 'Archivo'; int everydayOutfitCount = 2; int weekendOutfitCount = 1; int workoutOutfitCount = 1; List<String> upperBodyFilters = ["All Upper Body", "Jackets", "Tops", "Dresses"]; List<String> lowerBodyFilters = ["All Lower Body", "Pants", "Skirts"]; List<String> shoesFilters = ["All Shoes", "Sneakers", "Heels"]; String selectedUpperFilter = "All Upper Body"; String selectedLowerFilter = "All Lower Body"; String selectedShoesFilter = "All Shoes"; List<Map<String, String?>> upperBodyItems = List.generate(3, (i) => {'id': 'up${i+1}', 'name': 'Upper Item ${i+1}', 'imageUrl': null}); List<Map<String, String?>> lowerBodyItems = List.generate(2, (i) => {'id': 'low${i+1}', 'name': 'Lower Item ${i+1}', 'imageUrl': null}); List<Map<String, String?>> shoesItems = List.generate(4, (i) => {'id': 'sh${i+1}', 'name': 'Shoe ${i+1}', 'imageUrl': null}); return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ const SizedBox(height: 24), _buildSectionHeader(context: context, title: "My Closet Outfits", fontFamily: defaultFontFamily, onNavigate: () => _navigateToMyOutfits(context, null)), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: InkWell(onTap: () => _navigateToMyOutfits(context, "Everyday"), child: _buildCategorySummaryCard(title: "Everyday", count: everydayOutfitCount, icon: Icons.calendar_today_outlined, bgColor: const Color(0xFFD2EAB8), fontFamily: defaultFontFamily))), const SizedBox(width: 10), Expanded(child: InkWell(onTap: () => _navigateToMyOutfits(context, "Weekend"), child: _buildCategorySummaryCard(title: "Weekend", count: weekendOutfitCount, icon: Icons.weekend_outlined, bgColor: const Color(0xFFF9D8DA), fontFamily: defaultFontFamily))), const SizedBox(width: 10), Expanded(child: InkWell(onTap: () => _navigateToMyOutfits(context, "Workout"), child: _buildCategorySummaryCard(title: "Workout", count: workoutOutfitCount, icon: Icons.fitness_center, bgColor: const Color(0xFFFEE4CB), fontFamily: defaultFontFamily)))]), const SizedBox(height: 10), _buildSectionHeader(context: context, title: "Upper Body", fontFamily: defaultFontFamily, onNavigate: () { /* TODO */ }), const SizedBox(height: 10), _buildFilterChipsRow(context: context, filters: upperBodyFilters, selectedFilter: selectedUpperFilter, fontFamily: defaultFontFamily, onFilterSelected: (filter){ print("Selected Upper: $filter");}), const SizedBox(height: 18), _buildItemsRow(context: context, items: upperBodyItems, fontFamily: defaultFontFamily, onAddItem: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemPage())); }), const SizedBox(height: 10), _buildSectionHeader(context: context, title: "Lower Body", fontFamily: defaultFontFamily, onNavigate: () { /* TODO */ }), const SizedBox(height: 10), _buildFilterChipsRow(context: context, filters: lowerBodyFilters, selectedFilter: selectedLowerFilter, fontFamily: defaultFontFamily, onFilterSelected: (filter){ print("Selected Lower: $filter");}), const SizedBox(height: 18), _buildItemsRow(context: context, items: lowerBodyItems, fontFamily: defaultFontFamily, onAddItem: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemPage())); }), const SizedBox(height: 10), _buildSectionHeader(context: context, title: "Shoes", fontFamily: defaultFontFamily, onNavigate: () { /* TODO */ }), const SizedBox(height: 10), _buildFilterChipsRow(context: context, filters: shoesFilters, selectedFilter: selectedShoesFilter, fontFamily: defaultFontFamily, onFilterSelected: (filter){ print("Selected Shoes: $filter");}), const SizedBox(height: 18), _buildItemsRow(context: context, items: shoesItems, fontFamily: defaultFontFamily, onAddItem: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemPage())); }), const SizedBox(height: 40) ])); }
  Widget _buildProgressIndicator(BuildContext context, String label, int current, int total) { double progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0; double availableWidth = MediaQuery.of(context).size.width - (16 * 2); double containerPadding = 16 * 2; double spacing = 16; double progressBarWidth = (availableWidth - containerPadding - spacing) / 2; return Column( children: [ Text(label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Archivo')), const SizedBox(height: 4), Stack( alignment: Alignment.centerLeft, children: [ Container(width: progressBarWidth, height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))), Container(width: progress * progressBarWidth, height: 8, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4))) ]), Text("$current/$total", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontFamily: 'Archivo')) ]); }
  Widget _buildSmallCategoryCard(String title, IconData icon, Color iconColor) { return Container( padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), decoration: BoxDecoration( color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(12), boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1) ]), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(icon, color: iconColor, size: 24), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Archivo')), const Text("0 OUTFITS", style: TextStyle(fontSize: 10, fontFamily: 'Archivo')) ])); }
  Widget _buildOutfitCardPlaceholder(String? imageUrl) { bool hasImage = imageUrl != null && imageUrl.isNotEmpty; return Container( width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1) ]), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Expanded( child: !hasImage ? const Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey), SizedBox(height: 8), Text("Add items to see outfits", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Archivo'))]) : ClipRRect( borderRadius: BorderRadius.circular(8), child: Center(child: Text("Outfit Placeholder")))), if (hasImage) ...[ const SizedBox(height: 8), const Text("AI Outfit", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontFamily: 'Archivo'), maxLines: 2, overflow: TextOverflow.ellipsis)]])); }
  Widget _buildSectionHeader({required BuildContext context, required String title, required String fontFamily, required VoidCallback onNavigate}) { bool isMainTitle = title == "My Closet Outfits"; return Padding( padding: EdgeInsets.only(top: isMainTitle ? 0 : 16.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text(title, style: TextStyle(fontSize: isMainTitle ? 25 : 24, fontWeight: FontWeight.w500, letterSpacing: -0.02 * (isMainTitle ? 25 : 24), color: Colors.black, fontFamily: fontFamily)), TextButton( onPressed: onNavigate, child: Text("View all", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 15, color: Colors.black.withOpacity(0.65), fontFamily: fontFamily)))])); }
  Widget _buildCategorySummaryCard({required String title, required int count, required IconData icon, required Color bgColor, required String fontFamily}) { return Container( height: 72, padding: const EdgeInsets.symmetric(horizontal: 10.0), decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(5)), child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [ Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor), child: Center(child: Icon(icon, size: 23, color: Colors.black.withOpacity(0.8)))), const SizedBox(width: 10), Expanded( child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black, fontFamily: fontFamily), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 1), Text("$count OUTFIT${count == 1 ? '' : 'S'}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 12, color: Colors.black.withOpacity(0.65), fontFamily: fontFamily))]))])); }
  Widget _buildFilterChipsRow({required BuildContext context, required List<String> filters, required String selectedFilter, required String fontFamily, required ValueChanged<String> onFilterSelected}) { return SizedBox( height: 48, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: filters.length, padding: EdgeInsets.zero, itemBuilder: (context, index) { final filter = filters[index]; final isSelected = filter == selectedFilter; BoxDecoration decoration = BoxDecoration( borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD7D7D7)), color: isSelected ? const Color(0xFFF6F1EE) : Colors.transparent); return GestureDetector( onTap: () => onFilterSelected(filter), child: Container( margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: decoration, alignment: Alignment.center, child: Text(filter, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black)))); })); }
  Widget _buildItemsRow({required BuildContext context, required List<Map<String, String?>> items, required String fontFamily, required VoidCallback onAddItem}) { return SizedBox( height: 201, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: items.length + 1, padding: EdgeInsets.zero, itemBuilder: (context, index) { if (index == 0) { return Padding( padding: const EdgeInsets.only(right: 12.0), child: _buildAddItemCard(context: context, fontFamily: fontFamily, onTap: onAddItem)); } final itemIndex = index - 1; final item = items[itemIndex]; return Padding( padding: const EdgeInsets.only(right: 12.0), child: _buildItemCard( context: context, imageUrl: item['imageUrl'], itemId: item['id'] ?? 'unknown$itemIndex', fontFamily: fontFamily, onTap: () { print("Tapped item: ${item['id']}"); }, onEditTap: () { print("Edit item: ${item['id']}"); }, onDeleteTap: () { print("Delete item: ${item['id']}"); })); })); }
  Widget _buildAddItemCard({required BuildContext context, required String fontFamily, required VoidCallback onTap}) { return InkWell( onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container( width: 128, height: 201, decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(10)), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Container( width: 43, height: 43, decoration: const BoxDecoration(color: Color(0xFFD55F5F), shape: BoxShape.circle), child: const Center(child: Icon(Icons.add, color: Colors.white, size: 24))), const SizedBox(height: 15), Text("New Item", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 14, color: Colors.black))]))); }
  Widget _buildItemCard({required BuildContext context, String? imageUrl, required String itemId, required String fontFamily, VoidCallback? onTap, VoidCallback? onEditTap, VoidCallback? onDeleteTap}) { return InkWell( onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container( width: 143, height: 201, decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(10)), child: Stack( children: [ Positioned.fill( child: ClipRRect( borderRadius: BorderRadius.circular(10), child: imageUrl != null ? Center(child: Text("Img $itemId", style: const TextStyle(color: Colors.grey))) : const Center(child: Icon(Icons.checkroom, size: 60, color: Colors.grey)))), Positioned(top: 8, right: 8, child: _buildItemCardOverlayButton(onTap: onEditTap, icon: Icons.edit_outlined)), Positioned(bottom: 8, right: 8, child: _buildItemCardOverlayButton(onTap: onDeleteTap, icon: Icons.delete_outline))]))); }
  Widget _buildItemCardOverlayButton({required IconData icon, VoidCallback? onTap}) { return Material( color: Colors.white, shape: const CircleBorder(), elevation: 1.0, child: InkWell( customBorder: const CircleBorder(), onTap: onTap, child: Container(width: 33, height: 33, decoration: const BoxDecoration(shape: BoxShape.circle), child: Center(child: Icon(icon, size: 17, color: Colors.black.withOpacity(0.7)))))); }
}


// --- ProfilePage ---
class ProfilePage extends StatelessWidget {
  final String userInitial; final String? userImageUrl; final String userName; final String userEmail; final String userPhone; final String userFitPreference; final String userLifestylePreference; final String userSeasonPreference; final String userAgeGroup; final List<String> userPreferredColors; final List<String> userExcludedCategories; final Function(Map<String, dynamic>) onPreferencesUpdate;
  ProfilePage({ required this.userInitial, this.userImageUrl, required this.userName, required this.userEmail, required this.userPhone, required this.userFitPreference, required this.userLifestylePreference, required this.userSeasonPreference, required this.userAgeGroup, required this.userPreferredColors, required this.userExcludedCategories, required this.onPreferencesUpdate, super.key });
  Future<void> _changeProfilePicture(BuildContext context) async { print("Change profile picture tapped!"); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile picture - Implement image picker!'))); }
  void _navigateToChangePreferences(BuildContext context) { Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePreferencesPage(initialFit: userFitPreference, initialLifestyle: userLifestylePreference, initialSeason: userSeasonPreference, initialAgeGroup: userAgeGroup, initialColors: userPreferredColors, initialExclusions: userExcludedCategories, onSave: onPreferencesUpdate))); }
  void _navigateToMyInformation(BuildContext context) { Navigator.push(context, MaterialPageRoute(builder: (context) => MyInformationPage(userName: userName, userEmail: userEmail, userPhone: userPhone))); }
  void _navigateToChangePassword(BuildContext context) { Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())); }
  void _navigateToFeedback(BuildContext context) { Navigator.push(context, MaterialPageRoute(builder: (context) => const SendFeedbackPage())); }
  @override Widget build(BuildContext context) { const String defaultFontFamily = 'Archivo'; return Scaffold(backgroundColor: Colors.white, body: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 17.0), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [ const SizedBox(height: 58), const Text("Profile", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black)), const SizedBox(height: 38), Stack(alignment: Alignment.bottomRight, children: [ Container(width: 100, height: 100, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFECE2FF)), child: userImageUrl != null ? ClipOval(child: Image.network(userImageUrl!, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(child: Text(userInitial, style: const TextStyle(fontFamily: defaultFontFamily, fontSize: 64, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 64, color: Color(0xFF8960C4)))), loadingBuilder: (c, ch, lp) => lp == null ? ch : const Center(child: CircularProgressIndicator()))) : Center(child: Text(userInitial, style: const TextStyle(fontFamily: defaultFontFamily, fontSize: 64, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 64, color: Color(0xFF8960C4))))), InkWell(onTap: () => _changeProfilePicture(context), customBorder: const CircleBorder(), child: Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [ BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1,1)) ]), child: const Center(child: Icon(Icons.edit_outlined, size: 16, color: Colors.black87))))]), const SizedBox(height: 56), const Text("Check your preferences", textAlign: TextAlign.center, style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black)), const SizedBox(height: 21), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20), decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(10)), child: Column(children: [ _buildPreferenceRow(iconPlaceholder: Icons.accessibility_new, circleColor: const Color(0xFFF6ECAA), title: "Your fit", value: userFitPreference, fontFamily: defaultFontFamily), const SizedBox(height: 27), _buildPreferenceRow(iconPlaceholder: Icons.work_outline, circleColor: const Color(0xFFCEC7FA), title: "Life Style", value: userLifestylePreference, fontFamily: defaultFontFamily), const SizedBox(height: 27), _buildPreferenceRow(iconPlaceholder: Icons.cloud_outlined, circleColor: const Color(0xFFD55F5F), title: "Season", value: userSeasonPreference, fontFamily: defaultFontFamily), const SizedBox(height: 34), ElevatedButton(onPressed: () => _navigateToChangePreferences(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(291, 47), padding: const EdgeInsets.symmetric(horizontal: 16)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [ Text("Change Preferences", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 14, color: Colors.white)), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white)]))])), const SizedBox(height: 30), _buildInfoButton(text: "My Information", leadingIcon: Icons.person_outline, fontFamily: defaultFontFamily, onTap: () => _navigateToMyInformation(context)), _buildInfoButton(text: "Change Password", leadingIcon: Icons.lock_outline, fontFamily: defaultFontFamily, onTap: () => _navigateToChangePassword(context)), _buildInfoButton(text: "Terms of Service", leadingIcon: Icons.description_outlined, fontFamily: defaultFontFamily, onTap: () { /* TODO */ print("Terms tapped"); }), _buildInfoButton(text: "Send us Feedback", leadingIcon: Icons.feedback_outlined, fontFamily: defaultFontFamily, onTap: () => _navigateToFeedback(context)), const SizedBox(height: 30) ]))); }
  Widget _buildPreferenceRow({ required IconData iconPlaceholder, required Color circleColor, required String title, required String value, required String fontFamily}) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor), child: Center(child: Icon(iconPlaceholder, size: 24, color: Colors.black.withOpacity(0.8)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 14, color: const Color(0xFF221F1B).withOpacity(0.76))), const SizedBox(height: 5), Text(value, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 15, color: const Color(0xFF040404)), overflow: TextOverflow.ellipsis, maxLines: 2)]))]); }
  Widget _buildInfoButton({ required String text, required IconData leadingIcon, required String fontFamily, required VoidCallback onTap}) { return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 15.0), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 1)), child: Row(children: [ Icon(leadingIcon, size: 25, color: Colors.black), const SizedBox(width: 12), Expanded(child: Text(text, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 18, color: Colors.black))), const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black54)])))); }
}
