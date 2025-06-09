import 'package:flutter/material.dart';
import 'add_item.dart'; // Import for ClosetPage navigation
import 'my_outfits.dart';
import 'local_brands.dart';
import 'filtered_shop_page.dart';
import 'change_preferences.dart';
import 'my_information_page.dart';
import 'change_password_page.dart';
import 'send_feedback_page.dart';
import 'liked_items_screen.dart'; // Import the liked items screen
import 'package:image_picker/image_picker.dart'; // <<< Import image_picker
// import 'dart:ui'; // Needed for ImageFilter if using blur
import 'ai_stylist_camera_screen.dart'; // Import our new camera screen
import 'services/closet_service.dart'; // Import closet service
import 'services/profile_service.dart'; // Import profile service
import 'closet_item_widgets.dart'; // Import closet item widgets
import 'log_in.dart'; // <-- Add this import at the top with other imports
import 'all_category_items_page.dart'; // Import for AllCategoryItemsPage
import 'services/brand_service.dart'; // Import brand service

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
  String _userFitPreference = "";
  String _userLifestylePreference = "";
  String _userSeasonPreference = "";
  String _userAgeGroup = "";
  List<String> _userPreferredColors = [];
  List<String> _userExcludedCategories = [];
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userInitial = "";
  String? _userImageUrl;
  bool _isLoadingProfile = true;
  // --- End State Variables ---


  static const Color selectedColor = Color(0xFFD55F5F);
  static const Color unselectedColor = Color(0xFF686363);

  @override
  void initState() {
    super.initState();
    print('HomeScreen: calling _loadUserProfile in initState');
    _loadUserProfile();
  }

  // Load user profile data from the backend
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final profileService = ProfileService(token: widget.token);
      final profile = await profileService.getUserProfile();
      final preferences = await profileService.getUserPreferences();
      print('Fetched preferences from backend: $preferences');
      // Add debug print for what will be set
      final lifestylePref = preferences['lifestyle_preferences'];
      String debugLifestyle;
      if (lifestylePref is List) {
        debugLifestyle = lifestylePref.join(', ');
      } else if (lifestylePref is String) {
        debugLifestyle = lifestylePref;
      } else {
        debugLifestyle = '';
      }
      print('DEBUG: To be set - fit: \'${preferences['fit_preference']}\', lifestyle: \'$debugLifestyle\', season: \'${preferences['season_preference']}\'');
      setState(() {
        _userName = profile.name;
        _userEmail = profile.email;
        _userPhone = profile.phone;
        _userInitial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U';
        _userImageUrl = profile.imageUrl;
        _userFitPreference = preferences['fit_preference'] ?? '';
        // Defensive: handle both List and String for lifestyle_preferences
        if (lifestylePref is List) {
          _userLifestylePreference = lifestylePref.join(', ');
        } else if (lifestylePref is String) {
          _userLifestylePreference = lifestylePref;
        } else {
          _userLifestylePreference = '';
        }
        _userSeasonPreference = preferences['season_preference'] ?? '';
        _userAgeGroup = preferences['age_group'] ?? '';
        // Defensive: handle both List and String for preferred_colors
        final colorPref = preferences['preferred_colors'];
        if (colorPref is List) {
          _userPreferredColors = List<String>.from(colorPref);
        } else if (colorPref is String) {
          _userPreferredColors = [colorPref];
        } else {
          _userPreferredColors = [];
        }
        // Defensive: handle both List and String for excluded_categories
        final exclPref = preferences['excluded_categories'];
        if (exclPref is List) {
          _userExcludedCategories = List<String>.from(exclPref);
        } else if (exclPref is String) {
          _userExcludedCategories = [exclPref];
        } else {
          _userExcludedCategories = [];
        }
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('Error loading user profile or preferences: $e');
      setState(() {
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

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
    if (_isLoadingProfile) {
      return List.generate(5, (_) => const Center(child: CircularProgressIndicator()));
    }
    return [
      HomePage(
        key: ValueKey('prefs-${_userFitPreference}-${_userLifestylePreference}-${_userSeasonPreference}'),
        userFitPreference: _userFitPreference,
        userLifestylePreference: _userLifestylePreference,
        userSeasonPreference: _userSeasonPreference,
        userAgeGroup: _userAgeGroup,
        userPreferredColors: _userPreferredColors,
        userExcludedCategories: _userExcludedCategories,
        onChangePreferences: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePreferencesPage(
                initialFit: _userFitPreference,
                initialLifestyle: _userLifestylePreference,
                initialSeason: _userSeasonPreference,
                initialAgeGroup: _userAgeGroup,
                initialColors: _userPreferredColors,
                initialExclusions: _userExcludedCategories,
                onSave: _updateUserPreferences,
                token: widget.token,
              ),
            ),
          );
          if (result == true) {
            // Optionally reload profile/preferences from backend
            await _loadUserProfile();
          }
        },
      ),
      MyShopPage(token: widget.token),
      const AIStylistPage(),
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
        token: widget.token,
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
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F2EF),
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
  final String userAgeGroup;
  final List<String> userPreferredColors;
  final List<String> userExcludedCategories;
  final VoidCallback? onChangePreferences;

  const HomePage({
    required this.userFitPreference,
    required this.userLifestylePreference,
    required this.userSeasonPreference,
    required this.userAgeGroup,
    required this.userPreferredColors,
    required this.userExcludedCategories,
    this.onChangePreferences,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showPreferences = false; // controls preference card visibility in this page
  late List<Map<String, dynamic>> outfits;

  @override
  void initState() {
    super.initState();
    outfits = [];
    _loadOutfits();
  }

  void _toggleFavorite(String outfitId) async {
    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final profileService = ProfileService(token: homeScreenState.widget.token!);
        final success = await profileService.toggleFavorite(outfitId);
        
        if (success && mounted) {
          setState(() {
            final index = outfits.indexWhere((outfit) => outfit['id'] == outfitId);
            if (index != -1) {
              outfits[index]['isFavorite'] = !(outfits[index]['isFavorite'] ?? false);
            }
          });
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating favorite status'))
        );
      }
    }
  }

  Future<void> _loadOutfits() async {
    try {
      // Get token from parent HomeScreen
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final profileService = ProfileService(token: homeScreenState.widget.token);
        final favorites = await profileService.getFavorites();
        
        // TODO: Load actual outfits from backend
        // For now, using dummy data with favorite status
        setState(() {
          outfits = [
            {
              'id': '1',
              'imageUrl': null,
              'tags': ['Everyday', 'Casual'],
              'isFavorite': favorites.any((fav) => fav['item_id'] == '1'),
            },
            {
              'id': '2',
              'imageUrl': null,
              'tags': ['Work', 'Formal'],
              'isFavorite': favorites.any((fav) => fav['item_id'] == '2'),
            },
          ];
        });
      }
    } catch (e) {
      print('Error loading outfits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading outfits'))
        );
      }
    }
  }

  void _navigateToMyOutfits(String? filterCategory) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOutfitsPage(
            initialFilter: filterCategory,
            token: homeScreenState.widget.token
          )
        )
      );
    }
  }

  void _navigateToMyFavorites() {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyShopPage(token: homeScreenState.widget.token!),
        ),
      );
    }
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
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => PreferencesPreviewDialog(
                            fit: widget.userFitPreference,
                            lifestyle: widget.userLifestylePreference,
                            season: widget.userSeasonPreference,
                            ageGroup: widget.userAgeGroup,
                            colors: widget.userPreferredColors,
                            exclusions: widget.userExcludedCategories,
                          ),
                        );
                      },
                      child: const Text(
                        "My Preferences",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.02 * 25,
                          color: Colors.black,
                          fontFamily: defaultFontFamily,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            buildNewPreferencesPreview(
              fit: widget.userFitPreference,
              lifestyle: widget.userLifestylePreference,
              season: widget.userSeasonPreference,
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

  Widget _buildPreferenceRow(IconData icon, String title, String value, Color circleColor) { 
    const String defaultFontFamily = 'Archivo'; 
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [ 
        Container(
          width: 40, 
          height: 40, 
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: circleColor
          ), 
          child: Center(
            child: Icon(
              icon, 
              size: 24, 
              color: Colors.black87
            )
          )
        ), 
        const SizedBox(width: 12), 
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [ 
              Text(
                title, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500, 
                  letterSpacing: -0.02 * 14, 
                  color: const Color(0xFF221F1B).withOpacity(0.76), 
                  fontFamily: defaultFontFamily
                )
              ), 
              const SizedBox(height: 4), 
              Text(
                value, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w600, 
                  letterSpacing: -0.02 * 15, 
                  color: const Color(0xFF040404), 
                  fontFamily: defaultFontFamily
                )
              )
            ]
          )
        )
      ]
    ); 
  }
  
  Widget _buildOutfitCard({
    required String outfitId, 
    String? imageUrl, 
    List<String> tags = const [], 
    bool isFavorite = false, 
    VoidCallback? onFavoriteTap, 
    VoidCallback? onRefreshTap
  }) { 
    const String defaultFontFamily = 'Archivo'; 
    return Container(
      width: 228, 
      margin: const EdgeInsets.only(right: 18), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [ 
          Container(
            height: 272, 
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(5), 
              boxShadow: [ 
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), 
                  blurRadius: 4, 
                  offset: const Offset(0, 4)
                ) 
              ]
            ), 
            child: Stack(
              children: [ 
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3), 
                      borderRadius: BorderRadius.circular(10)
                    ), 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10), 
                      child: imageUrl != null 
                        ? Image.network(
                            imageUrl, 
                            fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 50, color: Colors.grey), 
                            loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator())
                          ) 
                        : const Icon(Icons.image_outlined, size: 80, color: Colors.grey)
                    )
                  )
                ), 
                Positioned(
                  top: 18, 
                  left: 18, 
                  child: _buildCardIconButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border, 
                    iconColor: isFavorite ? Colors.red : Colors.black.withOpacity(0.7), 
                    onTap: onFavoriteTap
                  )
                ), 
                Positioned(
                  bottom: 18, 
                  right: 18, 
                  child: _buildCardIconButton(
                    icon: Icons.refresh, 
                    onTap: onRefreshTap
                  )
                )
              ]
            )
          ), 
          const SizedBox(height: 8), 
          if (tags.isNotEmpty) 
            Wrap(
              spacing: 6.0, 
              runSpacing: 4.0, 
              children: tags.map((tag) => _buildTagChip(tag, defaultFontFamily)).toList()
            )
        ]
      )
    ); 
  }
  
  Widget _buildCardIconButton({
    required IconData icon, 
    Color? iconColor, 
    VoidCallback? onTap
  }) { 
    return Material(
      color: Colors.white, 
      shape: const CircleBorder(), 
      elevation: 1.0, 
      child: InkWell(
        customBorder: const CircleBorder(), 
        onTap: onTap, 
        child: Container(
          width: 33, 
          height: 33, 
          decoration: const BoxDecoration(shape: BoxShape.circle), 
          child: Center(
            child: Icon(
              icon, 
              size: 17, 
              color: iconColor ?? Colors.black.withOpacity(0.7)
            )
          )
        )
      )
    ); 
  }
  
  Widget _buildTagChip(String tag, String fontFamily) { 
    Color bgColor; 
    switch (tag.toLowerCase()) { 
      case 'everyday': 
        bgColor = const Color(0xFFD2EAB8); 
        break; 
      case 'party': 
        bgColor = const Color(0xFFFED5D9); 
        break; 
      case 'items': 
        bgColor = const Color(0xFFE6E6E6); 
        break; 
      default: 
        bgColor = Colors.grey.shade300; 
    } 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), 
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(20.0)
      ), 
      child: Text(
        tag, 
        style: TextStyle(
          fontFamily: fontFamily, 
          fontSize: 14, 
          fontWeight: FontWeight.w400, 
          letterSpacing: -0.02 * 14, 
          color: Colors.black
        )
      )
    ); 
  }
}

// --- MyShopPage ---
class MyShopPage extends StatefulWidget {
  final String token;
  const MyShopPage({required this.token, super.key});

  @override
  State<MyShopPage> createState() => _MyShopPageState();
}

class _MyShopPageState extends State<MyShopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _allCategories = [
    "All",
    "Clothing",
    "Bags",
    "Shoes",
    "Accessories",
  ];

  // --- Dynamic Brands State ---
  List<Brand> _brands = [];
  bool _isLoadingBrands = true;
  String _brandError = '';

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  void _fetchBrands() async {
    setState(() {
      _isLoadingBrands = true;
      _brandError = '';
    });
    try {
      final brandService = BrandService(token: widget.token);
      final brands = await brandService.getAllBrands();
      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
      });
    } catch (e) {
      setState(() {
        _brandError = 'Failed to load brands';
        _isLoadingBrands = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFilteredShop(BuildContext context, String title, FilterType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredShopPage(
          filterTitle: title,
          filterType: type,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    // Filter categories based on search query
    final filteredCategories = _allCategories.where((cat) =>
      cat.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 96,
        leading: Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Image.asset(
            'assets/logo_remove.png',
            width: 80,
            height: 80,
            errorBuilder: (c, e, s) => const Icon(Icons.error),
          ),
        ),
        title: const Text(
          "My shop",
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSearchBar(defaultFontFamily),
            const SizedBox(height: 24),
            const Text(
              "Categories",
              style: TextStyle(
                fontFamily: defaultFontFamily,
                fontSize: 23,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.02 * 23,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Show filtered categories
            for (final cat in filteredCategories)
              _buildCategoryRow(
                context,
                cat,
                defaultFontFamily,
                () => _navigateToFilteredShop(context, cat, FilterType.category),
              ),
            const SizedBox(height: 32),
            // --- Local Brands Section (Dynamic) ---
            const Text(
              "Local Brands",
              style: TextStyle(
                fontFamily: defaultFontFamily,
                fontSize: 23,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.02 * 23,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingBrands)
              const Center(child: CircularProgressIndicator())
            else if (_brandError.isNotEmpty)
              Center(child: Text(_brandError, style: TextStyle(color: Colors.red)))
            else if (_brands.isEmpty)
              const Center(child: Text("No local brands available."))
            else
              ..._brands.map((brand) => _buildCategoryRow(
                context,
                brand.name,
                defaultFontFamily,
                () => _navigateToFilteredShop(context, brand.name, FilterType.brand),
              )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(String fontFamily) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
          });
        },
        style: TextStyle(fontSize: 15, fontFamily: fontFamily),
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: TextStyle(
            fontFamily: fontFamily,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, String title, String fontFamily, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.02 * 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );
  }
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

  // --- Updated Function to Use AI Stylist Camera Screen ---
  Future<void> _processImageFromCamera() async {
    // Get the token from HomeScreenState
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // Navigate to our new camera screen with token
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIStylistCameraScreen(token: homeScreenState.widget.token),
        ),
      );
    }
  }

  // --- Functions for Action Buttons ---
  void _getAdviceOnItem() {
    // Get the token from HomeScreenState
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // Navigate to our AI Stylist camera screen with token
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIStylistCameraScreen(token: homeScreenState.widget.token),
        ),
      );
    }
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
      backgroundColor: const Color(0xFFFFFBF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, defaultFontFamily),
            Expanded(
              child: _isLoading
                  ? _buildLoadingView(defaultFontFamily)
                  : _buildMainContentView(defaultFontFamily),
            ),
            if (!_isLoading) _buildBottomActionBar(context, defaultFontFamily),
          ],
        ),
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
            Expanded(
              child: Text(
                "AI Stylist",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: fontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black),
              ),
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
          Text("Hi, I'm your personal AI Stylist!", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          const SizedBox(height: 14),
          Text("Lets us explore your Style Formula and Preferences.", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          const SizedBox(height: 4),
          Text("I'm here to bring your style to the next level!", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black)),
          Expanded(flex: 3, child: Container(margin: const EdgeInsets.symmetric(vertical: 20), alignment: Alignment.center, child: const Text("Chat history will appear here"))),
          const SizedBox(height: 10),
          // Action buttons removed as per new design
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
            "Analyzing your photos... 1/1\nGive us a few seconds - it won't take long",
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
class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  bool _isLoading = true;
  List<ClosetItem> _closetItems = [];

  // Selected filters
  String _selectedUpperFilter = "All Upper Body";
  String _selectedLowerFilter = "All Lower Body";
  String _selectedShoesFilter = "All Shoes";

  @override
  void initState() {
    super.initState();
    _loadClosetItems();
  }

  Future<void> _loadClosetItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final closetService = ClosetService(token: homeScreenState.widget.token);
        final items = await closetService.getClosetItems();

        setState(() {
          _closetItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading closet items: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading your closet items'))
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final closetService = ClosetService(token: homeScreenState.widget.token);
        final success = await closetService.deleteClosetItem(itemId);

        if (success && mounted) {
          setState(() {
            _closetItems.removeWhere((item) => item.id == itemId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully'))
          );
        }
      }
    } catch (e) {
      print('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting item'))
        );
      }
    }
  }

  void _navigateToMyOutfits(String? filterCategory) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOutfitsPage(
            initialFilter: filterCategory,
            token: homeScreenState.widget.token
          )
        )
      );
    }
  }

  void _navigateToAddItem() async {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemPage(token: homeScreenState.widget.token)
        )
      );
      
      if (result == true) {
        // Item was added, refresh the list
        _loadClosetItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Count items by category
    int upperBodyCount = _closetItems.where((item) => item.category == 'Upper Body').length;
    int lowerBodyCount = _closetItems.where((item) => item.category == 'Lower Body').length;
    int shoesCount = _closetItems.where((item) => item.category == 'Shoes').length;

    // Fixed target counts
    const int targetUpperBodyCount = 4;
    const int targetLowerBodyCount = 3;
    
    int totalItemsUploaded = _closetItems.length;
    const int totalItemsRequired = 7;
    bool isComplete = totalItemsUploaded >= totalItemsRequired;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 48.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: isComplete
            ? _buildCompleteView(context)
            : _buildIncompleteView(
                context,
                upperBodyCount,
                lowerBodyCount,
                targetUpperBodyCount, // Fixed target count for Upper Body
                targetLowerBodyCount, // Fixed target count for Lower Body
                totalItemsUploaded,
                totalItemsRequired
            )
      )
    );
  }

  Widget _buildIncompleteView(BuildContext context, int topsCount, int bottomsCount, int totalTops, int totalBottoms, int totalItemsUploaded, int totalItemsRequired) {
    List<String?> outfitImageUrls = [null, null, null];

    return RefreshIndicator(
      onRefresh: _loadClosetItems,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              "My Closet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Archivo'
              )
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F1EE),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        "$totalItemsUploaded/$totalItemsRequired ITEMS UPLOADED",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Archivo'
                        )
                      )
                    ]
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add at least 7 items, and your AI stylist will pair them into outfits",
                    style: TextStyle(fontFamily: 'Archivo')
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24
                      ),
                      minimumSize: const Size(double.infinity, 48)
                    ),
                    onPressed: _navigateToAddItem,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "ADD ITEM",
                          style: TextStyle(fontFamily: 'Archivo')
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward)
                      ]
                    )
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProgressIndicator(
                        context,
                        "Upper Body",
                        topsCount,
                        totalTops
                      ),
                      _buildProgressIndicator(
                        context,
                        "Lower Body",
                        bottomsCount,
                        totalBottoms
                      )
                    ]
                  )
                ]
              )
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Everyday"),
                    child: _buildSmallCategoryCard(
                      "Everyday",
                      Icons.calendar_today,
                      Colors.lightGreen
                    ),
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Weekend"),
                    child: _buildSmallCategoryCard(
                      "Weekend",
                      Icons.weekend,
                      Colors.pink[200]!
                    ),
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Workout"),
                    child: _buildSmallCategoryCard(
                      "Workout",
                      Icons.fitness_center,
                      Colors.orange[200]!
                    ),
                  )
                )
              ]
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Closet Outfits",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo'
                  )
                ),
                TextButton(
                  onPressed: () => _navigateToMyOutfits(null),
                  child: const Text(
                    "View all",
                    style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Archivo'
                    )
                  )
                )
              ]
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: outfitImageUrls.isEmpty ? 1 : outfitImageUrls.length,
                itemBuilder: (context, index) {
                  if (outfitImageUrls.isEmpty) {
                    return _buildOutfitCardPlaceholder(null);
                  }
                  return _buildOutfitCardPlaceholder(outfitImageUrls[index]);
                }
              )
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddItem,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add New Item', style: TextStyle(fontFamily: 'Archivo', color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD55F5F),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ]
        )
      )
    );
  }

  Widget _buildCompleteView(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    // Count outfits (placeholder for now)
    int everydayOutfitCount = 2;
    int weekendOutfitCount = 1;
    int workoutOutfitCount = 1;

    // Define filters
    List<String> upperBodyFilters = ["All Upper Body", "Jackets", "Shirts", "Sweaters", "Tops", "Tshirts"];
    List<String> lowerBodyFilters = ["All Lower Body", "Jeans", "Shorts", "Skirts", "Track Pants", "Trousers"];
    List<String> shoesFilters = ["All Shoes", "Casual - Formal Shoes", "Sandals", "Sports Shoes"];

    // Get upper body items
    List<ClosetItem> upperBodyItems = _closetItems
        .where((item) => item.category == 'Upper Body')
        .toList();

    // Get lower body items
    List<ClosetItem> lowerBodyItems = _closetItems
        .where((item) => item.category == 'Lower Body')
        .toList();

    // Get shoes items
    List<ClosetItem> shoesItems = _closetItems
        .where((item) => item.category == 'Shoes')
        .toList();

    // Filter based on selected filters
    if (_selectedUpperFilter != "All Upper Body") {
      upperBodyItems = upperBodyItems
          .where((item) => item.subcategory.toLowerCase() == _selectedUpperFilter.toLowerCase())
          .toList();
    }

    if (_selectedLowerFilter != "All Lower Body") {
      lowerBodyItems = lowerBodyItems
          .where((item) => item.subcategory.toLowerCase() == _selectedLowerFilter.toLowerCase())
          .toList();
    }

    if (_selectedShoesFilter != "All Shoes") {
      shoesItems = shoesItems
          .where((item) => item.subcategory.toLowerCase() == _selectedShoesFilter.toLowerCase())
          .toList();
    }

    return RefreshIndicator(
      onRefresh: _loadClosetItems,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSectionHeader(
              context: context,
              title: "My Closet Outfits",
              fontFamily: defaultFontFamily,
              onNavigate: () => _navigateToMyOutfits(null)
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Everyday"),
                    child: _buildCategorySummaryCard(
                      title: "Everyday",
                      count: everydayOutfitCount,
                      icon: Icons.calendar_today_outlined,
                      bgColor: const Color(0xFFD2EAB8),
                      fontFamily: defaultFontFamily
                    )
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Weekend"),
                    child: _buildCategorySummaryCard(
                      title: "Weekend",
                      count: weekendOutfitCount,
                      icon: Icons.weekend_outlined,
                      bgColor: const Color(0xFFF9D8DA),
                      fontFamily: defaultFontFamily
                    )
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToMyOutfits("Workout"),
                    child: _buildCategorySummaryCard(
                      title: "Workout",
                      count: workoutOutfitCount,
                      icon: Icons.fitness_center,
                      bgColor: const Color(0xFFFEE4CB),
                      fontFamily: defaultFontFamily
                    )
                  )
                )
              ]
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddItem,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add New Item', style: TextStyle(fontFamily: 'Archivo', color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD55F5F),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            _buildSectionHeader(
              context: context,
              title: "Upper Body",
              fontFamily: defaultFontFamily,
              onNavigate: () => _navigateToAllCategoryItems("Upper Body", _selectedUpperFilter != "All Upper Body" ? _selectedUpperFilter : null)
            ),
            const SizedBox(height: 10),
            _buildFilterChipsRow(
              context: context,
              filters: upperBodyFilters,
              selectedFilter: _selectedUpperFilter,
              fontFamily: defaultFontFamily,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedUpperFilter = filter;
                });
              }
            ),
            const SizedBox(height: 18),
            buildClosetItemsRow(
              context: context,
              items: upperBodyItems,
              fontFamily: defaultFontFamily,
              onTap: (item) {
                // TODO: Navigate to item detail
                print("Tapped item: ${item.id}");
              },
              onEdit: (item) {
                // TODO: Edit item
                print("Edit item: ${item.id}");
              },
              onDelete: (item) {
                _deleteItem(item.id);
              },
              onAddItem: _navigateToAddItem
            ),
            const SizedBox(height: 10),
            _buildSectionHeader(
              context: context,
              title: "Lower Body",
              fontFamily: defaultFontFamily,
              onNavigate: () => _navigateToAllCategoryItems("Lower Body", _selectedLowerFilter != "All Lower Body" ? _selectedLowerFilter : null)
            ),
            const SizedBox(height: 10),
            _buildFilterChipsRow(
              context: context,
              filters: lowerBodyFilters,
              selectedFilter: _selectedLowerFilter,
              fontFamily: defaultFontFamily,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedLowerFilter = filter;
                });
              }
            ),
            const SizedBox(height: 18),
            buildClosetItemsRow(
              context: context,
              items: lowerBodyItems,
              fontFamily: defaultFontFamily,
              onTap: (item) {
                // TODO: Navigate to item detail
                print("Tapped item: ${item.id}");
              },
              onEdit: (item) {
                // TODO: Edit item
                print("Edit item: ${item.id}");
              },
              onDelete: (item) {
                _deleteItem(item.id);
              },
              onAddItem: _navigateToAddItem
            ),
            const SizedBox(height: 10),
            _buildSectionHeader(
              context: context,
              title: "Shoes",
              fontFamily: defaultFontFamily,
              onNavigate: () => _navigateToAllCategoryItems("Shoes", _selectedShoesFilter != "All Shoes" ? _selectedShoesFilter : null)
            ),
            const SizedBox(height: 10),
            _buildFilterChipsRow(
              context: context,
              filters: shoesFilters,
              selectedFilter: _selectedShoesFilter,
              fontFamily: defaultFontFamily,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedShoesFilter = filter;
                });
              }
            ),
            const SizedBox(height: 18),
            buildClosetItemsRow(
              context: context,
              items: shoesItems,
              fontFamily: defaultFontFamily,
              onTap: (item) {
                // TODO: Navigate to item detail
                print("Tapped item: ${item.id}");
              },
              onEdit: (item) {
                // TODO: Edit item
                print("Edit item: ${item.id}");
              },
              onDelete: (item) {
                _deleteItem(item.id);
              },
              onAddItem: _navigateToAddItem
            ),
            const SizedBox(height: 40)
          ]
        )
      )
    );
  }

  Widget _buildProgressIndicator(BuildContext context, String label, int current, int total) {
    double progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    double availableWidth = MediaQuery.of(context).size.width - (16 * 2);
    double containerPadding = 16 * 2;
    double spacing = 16;
    double progressBarWidth = (availableWidth - containerPadding - spacing) / 2;
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Archivo')),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(width: progressBarWidth, height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            Container(width: progress * progressBarWidth, height: 8, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)))
          ]
        ),
        Text("$current/$total", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontFamily: 'Archivo'))
      ]
    );
  }

  Widget _buildSmallCategoryCard(String title, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1) ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Archivo')),
          const Text("0 OUTFITS", style: TextStyle(fontSize: 10, fontFamily: 'Archivo'))
        ]
      )
    );
  }

  Widget _buildOutfitCardPlaceholder(String? imageUrl) {
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1) ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: !hasImage
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Add items to see outfits", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Archivo'))
                    ]
                )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Center(child: Text("Outfit Placeholder"))
                )
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            const Text("AI Outfit", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontFamily: 'Archivo'), maxLines: 2, overflow: TextOverflow.ellipsis)
          ]
        ]
      )
    );
  }

  // Helper method to build the closet items list
  Widget _buildClosetItemsRow({
    required BuildContext context,
    required List<ClosetItem> items,
    required String fontFamily,
    required Function(ClosetItem) onTap,
    required Function(ClosetItem) onEdit,
    required Function(ClosetItem) onDelete,
    required VoidCallback onAddItem,
  }) {
    return SizedBox(
      height: 201,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1, // +1 for the "Add Item" card
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildAddItemCard(
                context: context,
                fontFamily: fontFamily,
                onTap: onAddItem
              )
            );
          }
          
          final item = items[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildClosetItemCard(
              context: context,
              item: item,
              fontFamily: fontFamily,
              onTap: () => onTap(item),
              onEditTap: () => onEdit(item),
              onDeleteTap: () => onDelete(item)
            )
          );
        }
      )
    );
  }
  
  // Helper method to build a closet item card
  Widget _buildClosetItemCard({
    required BuildContext context,
    required ClosetItem item,
    required String fontFamily,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
    VoidCallback? onDeleteTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 143,
        height: 201,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Stack(
          children: [
            // Item image or placeholder
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.checkroom, size: 60, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 14,
                                  color: Colors.grey.shade600
                                ),
                              ),
                              Text(
                                item.color,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 12,
                                  color: Colors.grey
                                ),
                              ),
                            ],
                          )
                        )
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checkroom, size: 60, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              color: Colors.grey.shade600
                            ),
                          ),
                          Text(
                            item.color,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.grey
                            ),
                          ),
                        ],
                      )
                    )
              )
            ),
            
            // Edit button
            Positioned(
              top: 8,
              right: 8,
              child: _buildItemCardOverlayButton(
                onTap: onEditTap,
                icon: Icons.edit_outlined
              )
            ),
            
            // Delete button
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildItemCardOverlayButton(
                onTap: onDeleteTap,
                icon: Icons.delete_outline
              )
            ),
          ]
        )
      )
    );
  }
  
  Widget _buildSectionHeader({required BuildContext context, required String title, required String fontFamily, required VoidCallback onNavigate}) {
    bool isMainTitle = title == "My Closet Outfits";
    return Padding(
      padding: EdgeInsets.only(top: isMainTitle ? 0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: isMainTitle ? 25 : 24, fontWeight: FontWeight.w500, letterSpacing: -0.02 * (isMainTitle ? 25 : 24), color: Colors.black, fontFamily: fontFamily)),
          TextButton(
            onPressed: onNavigate,
            child: Text("View all", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 15, color: Colors.black.withOpacity(0.65), fontFamily: fontFamily))
          )
        ]
      )
    );
  }

  Widget _buildCategorySummaryCard({required String title, required int count, required IconData icon, required Color bgColor, required String fontFamily}) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor), child: Center(child: Icon(icon, size: 23, color: Colors.black.withOpacity(0.8)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 16, color: Colors.black, fontFamily: fontFamily), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text("$count OUTFIT${count == 1 ? '' : 'S'}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 12, color: Colors.black.withOpacity(0.65), fontFamily: fontFamily))
              ]
            )
          )
        ]
      )
    );
  }

  Widget _buildFilterChipsRow({required BuildContext context, required List<String> filters, required String selectedFilter, required String fontFamily, required ValueChanged<String> onFilterSelected}) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          BoxDecoration decoration = BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7D7D7)),
            color: isSelected ? const Color(0xFFF6F1EE) : Colors.transparent
          );
          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(filter, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.02 * 14, color: Colors.black))
            )
          );
        }
      )
    );
  }

  Widget _buildAddItemCard({required BuildContext context, required String fontFamily, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 128,
        height: 201,
        decoration: BoxDecoration(color: const Color(0xFFF6F1EE), borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(color: Color(0xFFD55F5F), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.add, color: Colors.white, size: 24))
            ),
            const SizedBox(height: 15),
            Text("New Item", textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 14, color: Colors.black))
          ]
        )
      )
    );
  }

  Widget _buildItemCardOverlayButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1.0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(width: 33, height: 33, decoration: const BoxDecoration(shape: BoxShape.circle), child: Center(child: Icon(icon, size: 17, color: Colors.black.withOpacity(0.7))))
      )
    );
  }

  // Add navigation for View all buttons for each section
  void _navigateToAllCategoryItems(String category, String? subcategory) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllCategoryItemsPage(
            token: homeScreenState.widget.token,
            category: category,
            subcategory: subcategory,
            closetItems: _closetItems,
          ),
        ),
      );
    }
  }
}


// --- ProfilePage ---
class ProfilePage extends StatefulWidget {
  final String userInitial;
  final String? userImageUrl;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userFitPreference;
  final String userLifestylePreference;
  final String userSeasonPreference;
  final String userAgeGroup;
  final List<String> userPreferredColors;
  final List<String> userExcludedCategories;
  final Function(Map<String, dynamic>) onPreferencesUpdate;
  final String token;
  
  const ProfilePage({
    required this.userInitial,
    this.userImageUrl,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userFitPreference,
    required this.userLifestylePreference,
    required this.userSeasonPreference,
    required this.userAgeGroup,
    required this.userPreferredColors,
    required this.userExcludedCategories,
    required this.onPreferencesUpdate,
    required this.token,
    super.key
  });
  
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  UserProfile? _userProfile;
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadProfilePicture();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final profileService = ProfileService(token: widget.token);
      final profile = await profileService.getUserProfile();
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile'))
        );
      }
    }
  }

  // Add a separate method to load the profile picture
  Future<void> _loadProfilePicture() async {
    try {
      final profileService = ProfileService(token: widget.token);
      final imageUrl = await profileService.getProfilePicture();
      
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      // Show bottom sheet with camera and gallery options
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) return; // User canceled the selection
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality to save space
        maxWidth: 500,    // Limit image dimensions
      );
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });
        
        final profileService = ProfileService(token: widget.token);
        final result = await profileService.uploadProfilePicture(image.path);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (result['success']) {
            // If the server returned an image URL, use it directly
            if (result.containsKey('url')) {
              setState(() {
                _profileImageUrl = result['url'];
              });
            } else {
              // Otherwise reload the profile picture
              _loadProfilePicture();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated successfully'))
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile picture'))
            );
          }
        }
      }
    } catch (e) {
      print('Error changing profile picture: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile picture'))
        );
      }
    }
  }
  
  void _navigateToChangePreferences() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePreferencesPage(
          initialFit: widget.userFitPreference,
          initialLifestyle: widget.userLifestylePreference,
          initialSeason: widget.userSeasonPreference,
          initialAgeGroup: widget.userAgeGroup,
          initialColors: widget.userPreferredColors,
          initialExclusions: widget.userExcludedCategories,
          onSave: widget.onPreferencesUpdate,
          token: widget.token,
        )
      )
    );
    
    if (result == true) {
      // Preferences were updated, reload profile
      _loadUserProfile();
    }
  }

  void _navigateToMyInformation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyInformationPage(
          userName: widget.userName,
          userEmail: widget.userEmail,
          userPhone: widget.userPhone,
          token: widget.token,
        )
      )
    );
    
    if (result != null) {
      // User info was updated with returned profile
      if (result is UserProfile) {
        // Update the state with the returned profile data
        setState(() {
          _userProfile = result;
        });
        
        // Update parent state with profile data
        widget.onPreferencesUpdate({
          'fit': result.fitPreference,
          'lifestyle': result.lifestylePreferences,
          'season': result.seasonPreference,
          'ageGroup': result.ageGroup,
          'colors': result.preferredColors,
          'exclusions': result.excludedCategories,
        });
      } else {
        // If result is just true, reload profile the old way
        _loadUserProfile();
      }
    }
  }
  
  void _navigateToChangePassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(token: widget.token)
      )
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully'))
      );
    }
  }
  
  void _navigateToFeedback() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendFeedbackPage(token: widget.token)
      )
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent successfully'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Use either the loaded profile data or fall back to the props passed from parent
    final userName = _userProfile?.name ?? widget.userName;
    final userEmail = _userProfile?.email ?? widget.userEmail;
    final userPhone = _userProfile?.phone ?? widget.userPhone;
    final userInitial = (userName.isNotEmpty) ? userName[0].toUpperCase() : widget.userInitial;
    final imageUrl = _profileImageUrl ?? _userProfile?.imageUrl ?? widget.userImageUrl;
    final fitPreference = _userProfile?.fitPreference ?? widget.userFitPreference;
    final lifestylePreferences = _userProfile?.lifestylePreferences.join(', ') ?? widget.userLifestylePreference;
    final seasonPreference = _userProfile?.seasonPreference ?? widget.userSeasonPreference;
    final ageGroup = _userProfile?.ageGroup ?? widget.userAgeGroup;
    final preferredColors = _userProfile?.preferredColors ?? widget.userPreferredColors;
    final excludedCategories = _userProfile?.excludedCategories ?? widget.userExcludedCategories;
    
    const String defaultFontFamily = 'Archivo';
    
    String getFullImageUrl(String? path) {
      if (path == null) return '';
      if (path.startsWith('http')) return path;
      return 'http://10.0.2.2:8000/static/$path'; // Adjust for your setup or use Config.apiUrl
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _changeProfilePicture,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFF3F3F3),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      getFullImageUrl(imageUrl),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          userInitial,
                                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.black54),
                                        ),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      userInitial,
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.black54),
                                    ),
                                  ),
                          ),
                        ),
                        // Edit Icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD55F5F),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFamily: defaultFontFamily),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Email
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 14, color: Colors.black54, fontFamily: defaultFontFamily),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Account Settings Section
              _buildSectionHeader('Account Settings'),
              _buildSettingItem(
                icon: Icons.person_outline, 
                title: 'My Information',
                subtitle: userPhone,
                onTap: () => _navigateToMyInformation(),
              ),
              _buildSettingItem(
                icon: Icons.lock_outline, 
                title: 'Password',
                subtitle: '********',
                onTap: () => _navigateToChangePassword(),
              ),
              
              // App Settings Section
              _buildSectionHeader('App Settings'),
              _buildSettingItem(
                icon: Icons.tune, 
                title: 'Preferences',
                subtitle: '$fitPreference · $lifestylePreferences',
                onTap: () => _navigateToChangePreferences(),
              ),
              
              // Help & Support Section
              _buildSectionHeader('Help & Support'),
              _buildSettingItem(
                icon: Icons.feedback_outlined, 
                title: 'Send Feedback',
                onTap: () => _navigateToFeedback(),
              ),
              _buildSettingItem(
                icon: Icons.help_outline, 
                title: 'Help Center',
                onTap: () => _openHelpCenter(),
              ),
              
              // Sign Out
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: _confirmSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sign Out', style: TextStyle(fontFamily: defaultFontFamily)),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ... rest of the existing methods

  // Helper methods for the ProfilePage
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontFamily: 'Archivo',
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Archivo',
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Archivo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _openHelpCenter() {
    // Open help center webpage or in-app support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help Center feature coming soon')),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    // TODO: Clear user session/token here if you use persistent login (e.g., SharedPreferences)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}

// Add this widget builder at the top-level of the file (outside the class)
Widget buildNewPreferencesPreview({
  required String fit,
  required String lifestyle,
  required String season,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F1EE),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF6ECAA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.accessibility_new, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your fit",
                  style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF221F1B)),
                ),
                Text(
                  (fit != null && fit.trim().isNotEmpty) ? fit : "Not set",
                  style: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF040404)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFCEC7FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_outline, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Life Style",
                  style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF221F1B)),
                ),
                Text(
                  (lifestyle != null && lifestyle.trim().isNotEmpty) ? lifestyle : "Not set",
                  style: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF040404)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFD55F5F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_outlined, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Season",
                  style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF221F1B)),
                ),
                Text(
                  (season != null && season.trim().isNotEmpty) ? season : "Not set",
                  style: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF040404)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class PreferencesPreviewDialog extends StatelessWidget {
  final String fit;
  final String lifestyle;
  final String season;
  final String ageGroup;
  final List<String> colors;
  final List<String> exclusions;

  const PreferencesPreviewDialog({
    required this.fit,
    required this.lifestyle,
    required this.season,
    required this.ageGroup,
    required this.colors,
    required this.exclusions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Preferences", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Archivo')),
            const SizedBox(height: 16),
            _buildRow("Fit", fit),
            _buildRow("Lifestyle", lifestyle),
            _buildRow("Season", season),
            _buildRow("Age Group", ageGroup),
            _buildRow("Preferred Colors", colors.join(", ")),
            _buildRow("Excluded Categories", exclusions.join(", ")),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Archivo')),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Archivo'))),
        ],
      ),
    );
  }
}
