import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'ai_stylist_page.dart';
import 'services/outfit_service.dart'; // Add this import

// ----- Main Navigation Screen -----

class HomeScreen extends StatefulWidget {
  final String token;
  final int userId;

  const HomeScreen({super.key, required this.token, required this.userId});

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
        token: widget.token,
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
      MyShopPage(token: widget.token, userId: widget.userId),
      // Pass token in route settings when navigating to AIStylistPage
      Builder(
        builder: (context) {
          return AIStylistPage(userId: widget.userId, token: widget.token);
        },
      ),
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
    if (_selectedIndex != index) {
      // Add haptic feedback
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
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
      bottomNavigationBar: _buildModernNavigationBar(),
    );
  }

  Widget _buildModernNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home, "Home"),
              _buildNavItem(1, Icons.shopping_bag, "My Shop"),
              _buildNavItem(2, Icons.smart_toy, "AI Stylist"),
              _buildNavItem(3, Icons.checkroom, "Closet"),
              _buildNavItem(4, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 8 : 0),
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
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
  final String token;

  const HomePage({
    required this.userFitPreference,
    required this.userLifestylePreference,
    required this.userSeasonPreference,
    required this.userAgeGroup,
    required this.userPreferredColors,
    required this.userExcludedCategories,
    required this.token,
    this.onChangePreferences,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showPreferences = false; // controls preference card visibility in this page
  late List<Outfit> outfits;

  @override
  void initState() {
    super.initState();
    outfits = [];
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final outfitService = OutfitService(token: homeScreenState.widget.token);
        final fetchedOutfits = await outfitService.getUserOutfits();
        setState(() {
          outfits = fetchedOutfits;
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

  void _toggleFavorite(String outfitId) async {
    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final profileService = ProfileService(token: homeScreenState.widget.token!);
        final success = await profileService.toggleFavorite(outfitId);

        if (success && mounted) {
          setState(() {
            final index = outfits.indexWhere((outfit) => outfit.id == outfitId);
            if (index != -1) {
              outfits[index].isFavorite = !(outfits[index].isFavorite ?? false);
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

  void _navigateToMyOutfits(String? filterCategory) async {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOutfitsPage(
            initialFilter: filterCategory,
            token: homeScreenState.widget.token,
          ),
        ),
      );
      // Refresh counters after returning
      // await _loadOutfitsAndCounters(); // Removed: Only ClosetPage should call this
    }
  }

  void _navigateToMyFavorites() {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyShopPage(token: homeScreenState.widget.token!, userId: homeScreenState.widget.userId),
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
      body: RefreshIndicator(
        onRefresh: _loadOutfits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  itemCount: outfits.length > 3 ? 3 : outfits.length,
                  itemBuilder: (context, index) {
                    final outfit = outfits[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyOutfitsPage(
                              initialFilter: null,
                              token: widget.token,
                              initialOutfitId: outfit.id,
                            ),
                          ),
                        );
                        // Optionally, you can implement logic to scroll to the tapped outfit inside MyOutfitsPage
                      },
                      child: _buildOutfitPreviewCard(outfit, defaultFontFamily),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitPreviewCard(Outfit outfit, String fontFamily) {
    // Use the first image as preview, or a placeholder
    final String? imageUrl = outfit.itemImageUrls.isNotEmpty ? outfit.itemImageUrls[0] : null;
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
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl.startsWith('http')
                        ? imageUrl
                        : 'http://10.0.2.2:8000/static/${normalizeImagePath(imageUrl)}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 50, color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                    )
                  : const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          if (outfit.tags.isNotEmpty)
            Flexible(
              child: Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: outfit.tags.map((tag) => _buildTagChip(tag, fontFamily)).toList(),
              ),
            ),
        ],
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
                                        imageUrl.startsWith('http')
                                          ? imageUrl
                                          : 'http://10.0.2.2:8000/static/${normalizeImagePath(imageUrl)}',
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
  final int userId;
  const MyShopPage({required this.token, required this.userId, super.key});

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
          userId: widget.userId,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedItemsScreen(token: widget.token),
                ),
              );
            },
          ),
        ],
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                    const Icon(Icons.arrow_forward_ios, size: 17, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- AIStylistPage ---
// Removed duplicate AIStylistPage class and state. The version from ai_stylist_page.dart will be used.
// ... existing code ...

// --- ClosetPage ---
class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  bool _isLoading = true;
  List<ClosetItem> _closetItems = [];
  List<Outfit> _outfits = [];
  int everydayOutfitCount = 0;
  int weekendOutfitCount = 0;
  int workoutOutfitCount = 0;

  // Selected filters
  String _selectedUpperFilter = "All Upper Body";
  String _selectedLowerFilter = "All Lower Body";
  String _selectedDressFilter = "All Dress";
  String _selectedBagsFilter = "All Bags";
  String _selectedShoesFilter = "All Shoes";

  @override
  void initState() {
    super.initState();
    _loadClosetItems();
    _loadOutfitsAndCounters();
  }

  Future<void> _loadOutfitsAndCounters() async {
    try {
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        final outfitService = OutfitService(token: homeScreenState.widget.token);
        final outfits = await outfitService.getUserOutfits();
        setState(() {
          _outfits = outfits;
          everydayOutfitCount = outfits.where((o) => o.tags.any((t) => t.toLowerCase() == 'everyday')).length;
          weekendOutfitCount = outfits.where((o) => o.tags.any((t) => t.toLowerCase() == 'weekend')).length;
          workoutOutfitCount = outfits.where((o) => o.tags.any((t) => t.toLowerCase() == 'workout')).length;
        });
      }
    } catch (e) {
      print('Error loading outfits for counters: $e');
    }
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
        final (success, errorMsg) = await closetService.deleteClosetItem(itemId);

        if (success && mounted) {
          setState(() {
            _closetItems.removeWhere((item) => item.id == itemId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item deleted successfully', style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFFD55F5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg ?? 'Failed to delete item', style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFFD55F5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFFD55F5F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToMyOutfits(String? filterCategory) async {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOutfitsPage(
            initialFilter: filterCategory,
            token: homeScreenState.widget.token,
          ),
        ),
      );
      // Refresh counters after returning
      await _loadOutfitsAndCounters();
    }
  }

  void _navigateToAddItem() async {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddItemPage(token: homeScreenState.widget.token, userId: homeScreenState.widget.userId)
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
    int dressCount = _closetItems.where((item) => item.category == 'Dress').length;
    int bagsCount = _closetItems.where((item) => item.category == 'Bags').length;
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
            child: _buildCompleteView(context)
        )
    );
  }

  Widget _buildCompleteView(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    // Use real counters
    // everydayOutfitCount, weekendOutfitCount, workoutOutfitCount are now set from backend

    // Define filters
    List<String> upperBodyFilters = ["All Upper Body", "Jackets", "Shirts", "Sweaters", "Tops", "Tshirts"];
    List<String> lowerBodyFilters = ["All Lower Body", "Jeans", "Shorts", "Skirts", "Track Pants", "Trousers"];
    List<String> dressFilters = ["All Dress", "Casual Dresses", "Formal Dresses", "Party Dresses"];
    List<String> bagsFilters = ["All Bags", "Backpacks", "Clutches", "Totes"];
    List<String> shoesFilters = ["All Shoes", "Casual - Formal Shoes", "Sandals", "Sports Shoes"];

    // Get upper body items
    List<ClosetItem> upperBodyItems = _closetItems
        .where((item) => item.category == 'Upper Body')
        .toList();

    // Get lower body items
    List<ClosetItem> lowerBodyItems = _closetItems
        .where((item) => item.category == 'Lower Body')
        .toList();

    // Get dress items
    List<ClosetItem> dressItems = _closetItems
        .where((item) => item.category == 'Dress')
        .toList();

    // Get bags items
    List<ClosetItem> bagsItems = _closetItems
        .where((item) => item.category == 'Bags')
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

    if (_selectedDressFilter != "All Dress") {
      dressItems = dressItems
          .where((item) => item.subcategory.toLowerCase() == _selectedDressFilter.toLowerCase())
          .toList();
    }

    if (_selectedBagsFilter != "All Bags") {
      bagsItems = bagsItems
          .where((item) => item.subcategory.toLowerCase() == _selectedBagsFilter.toLowerCase())
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
                      title: "My Closet ",
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
                      title: "Dress",
                      fontFamily: defaultFontFamily,
                      onNavigate: () => _navigateToAllCategoryItems("Dress", _selectedDressFilter != "All Dress" ? _selectedDressFilter : null)
                  ),
                  const SizedBox(height: 10),
                  _buildFilterChipsRow(
                      context: context,
                      filters: dressFilters,
                      selectedFilter: _selectedDressFilter,
                      fontFamily: defaultFontFamily,
                      onFilterSelected: (filter) {
                        setState(() {
                          _selectedDressFilter = filter;
                        });
                      }
                  ),
                  const SizedBox(height: 18),
                  buildClosetItemsRow(
                      context: context,
                      items: dressItems,
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
                      title: "Bags",
                      fontFamily: defaultFontFamily,
                      onNavigate: () => _navigateToAllCategoryItems("Bags", _selectedBagsFilter != "All Bags" ? _selectedBagsFilter : null)
                  ),
                  const SizedBox(height: 10),
                  _buildFilterChipsRow(
                      context: context,
                      filters: bagsFilters,
                      selectedFilter: _selectedBagsFilter,
                      fontFamily: defaultFontFamily,
                      onFilterSelected: (filter) {
                        setState(() {
                          _selectedBagsFilter = filter;
                        });
                      }
                  ),
                  const SizedBox(height: 18),
                  buildClosetItemsRow(
                      context: context,
                      items: bagsItems,
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


  ])));}

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

  void _navigateToAIStylist() async {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIStylistPage(userId: homeScreenState.widget.userId, token: homeScreenState.widget.token),
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
      backgroundColor: const Color(0xFFF6F2EF),
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
                            backgroundColor: Colors.white, // Make the background white if no image
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
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.black54, fontFamily: 'Archivo'),
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
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.black54, fontFamily: 'Archivo'),
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Color(0xFFD55F5F), width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 20, color: Color(0xFFD55F5F)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Archivo'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'Archivo'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      style: const TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'Archivo'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF9F7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Settings"),
                          const SizedBox(height: 8),
                          _buildSettingItem(
                            icon: Icons.tune,
                            title: "Change Preferences",
                            onTap: _navigateToChangePreferences,
                          ),
                          _buildSettingItem(
                            icon: Icons.person_outline,
                            title: "My Information",
                            onTap: _navigateToMyInformation,
                          ),
                          _buildSettingItem(
                            icon: Icons.lock_outline,
                            title: "Change Password",
                            onTap: _navigateToChangePassword,
                          ),
                          _buildSettingItem(
                            icon: Icons.feedback_outlined,
                            title: "Send Feedback",
                            onTap: _navigateToFeedback,
                          ),
                          _buildSettingItem(
                            icon: Icons.logout,
                            title: "Sign Out",
                            onTap: _confirmSignOut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD55F5F),
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
          color: const Color(0xFFF6F2EF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xFFD55F5F)),
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
          color: Colors.black54,
          fontFamily: 'Archivo',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFD55F5F)),
      onTap: onTap,
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF9F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out', style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(fontFamily: 'Archivo', fontSize: 16, color: Colors.black)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Archivo', color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign Out', style: TextStyle(fontFamily: 'Archivo', color: Color(0xFFD55F5F), fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Color(0xFFD55F5F), size: 28),
                const SizedBox(width: 10),
                const Text(
                  "My Preferences",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Archivo',
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1.2),
            _buildRow(Icons.accessibility_new, "Fit", fit),
            _buildRow(Icons.directions_run, "Lifestyle", lifestyle),
            _buildRow(Icons.wb_sunny, "Season", season),
            _buildRow(Icons.cake, "Age Group", ageGroup),
            _buildRow(Icons.palette, "Preferred Colors", colors.isNotEmpty ? colors.join(", ") : "None"),
            _buildRow(Icons.block, "Excluded Categories", exclusions.isNotEmpty ? exclusions.join(", ") : "None"),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFD55F5F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  textStyle: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFFD55F5F), size: 20),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Archivo')),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Archivo'))),
        ],
      ),
    );
  }
}

Widget _buildModernOutfitPreviewCard(Outfit outfit) {
  // Modern card: rounded, shadow, theme color, stacked/overlapping images, no tags
  return Container(
    width: 110,
    decoration: BoxDecoration(
      color: const Color(0xFFFDFDFD),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (outfit.itemImageUrls.length > 2)
          Positioned(
            left: 24,
            top: 24,
            child: _buildOutfitItemImage(outfit.itemImageUrls[2], 44, 0.5),
          ),
        if (outfit.itemImageUrls.length > 1)
          Positioned(
            left: 12,
            top: 12,
            child: _buildOutfitItemImage(outfit.itemImageUrls[1], 52, 0.7),
          ),
        if (outfit.itemImageUrls.isNotEmpty)
          _buildOutfitItemImage(outfit.itemImageUrls[0], 60, 1.0),
      ],
    ),
  );
}

Widget _buildOutfitItemImage(String url, double size, double opacity) {
  return Opacity(
    opacity: opacity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      ),
    ),
  );
}

// Helper to normalize image paths
String normalizeImagePath(String path) => path.replaceAll('\\', '/');