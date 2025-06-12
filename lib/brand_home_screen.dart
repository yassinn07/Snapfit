import 'package:flutter/material.dart';
import 'brand_statistics_screen.dart';
import 'home_screen.dart'; // For ProfilePage
import 'services/profile_service.dart';

class BrandHomeScreen extends StatefulWidget {
  final String token;
  const BrandHomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BrandHomeScreen> createState() => _BrandHomeScreenState();
}

class _BrandHomeScreenState extends State<BrandHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  // Profile fields
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userInitial = '';
  String? _userImageUrl;
  String _userFitPreference = '';
  String _userLifestylePreference = '';
  String _userSeasonPreference = '';
  String _userAgeGroup = '';
  List<String> _userPreferredColors = [];
  List<String> _userExcludedCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profileService = ProfileService(token: widget.token);
      final profile = await profileService.getUserProfile();
      final preferences = await profileService.getUserPreferences();
      setState(() {
        _userName = profile.name;
        _userEmail = profile.email;
        _userPhone = profile.phone;
        _userInitial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U';
        _userImageUrl = profile.imageUrl;
        _userFitPreference = preferences['fit_preference'] ?? '';
        final lifestylePref = preferences['lifestyle_preferences'];
        if (lifestylePref is List) {
          _userLifestylePreference = lifestylePref.join(', ');
        } else if (lifestylePref is String) {
          _userLifestylePreference = lifestylePref;
        } else {
          _userLifestylePreference = '';
        }
        _userSeasonPreference = preferences['season_preference'] ?? '';
        _userAgeGroup = preferences['age_group'] ?? '';
        final colorPref = preferences['preferred_colors'];
        if (colorPref is List) {
          _userPreferredColors = List<String>.from(colorPref);
        } else if (colorPref is String) {
          _userPreferredColors = [colorPref];
        } else {
          _userPreferredColors = [];
        }
        final exclPref = preferences['excluded_categories'];
        if (exclPref is List) {
          _userExcludedCategories = List<String>.from(exclPref);
        } else if (exclPref is String) {
          _userExcludedCategories = [exclPref];
        } else {
          _userExcludedCategories = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUserPreferences(Map<String, dynamic> newPreferences) {
    setState(() {
      _userFitPreference = newPreferences['fit'] ?? _userFitPreference;
      _userLifestylePreference = (newPreferences['lifestyle'] as List<String>?)?.join(', ') ?? _userLifestylePreference;
      _userSeasonPreference = newPreferences['season'] ?? _userSeasonPreference;
      _userAgeGroup = newPreferences['ageGroup'] ?? _userAgeGroup;
      _userPreferredColors = List<String>.from(newPreferences['colors'] ?? _userPreferredColors);
      _userExcludedCategories = List<String>.from(newPreferences['exclusions'] ?? _userExcludedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pages = [
      BrandStatisticsScreen(token: widget.token),
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
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.background,
        selectedItemColor: const Color(0xFFD55F5F),
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 