import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand_statistics_screen.dart';
import 'home_screen.dart'; // For ProfilePage
import 'services/profile_service.dart';
import 'brand_dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Statistics items
  List<dynamic> _items = [];
  bool _isStatsLoading = true;

  static const Color selectedColor = Color(0xFFD55F5F);
  static const Color unselectedColor = Color(0xFF686363);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchStatistics();
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

  Future<void> _fetchStatistics() async {
    setState(() {
      _isStatsLoading = true;
    });
    final url = Uri.parse('http://10.0.2.2:8000/brands/items/statistics');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _items = data;
          _isStatsLoading = false;
        });
      } else {
        setState(() {
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isStatsLoading = false;
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

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildModernBrandNavBar() {
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
              _buildBrandNavItem(0, Icons.dashboard, "Dashboard"),
              _buildBrandNavItem(1, Icons.bar_chart, "Statistics"),
              _buildBrandNavItem(2, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandNavItem(int index, IconData icon, String label) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isStatsLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Aggregate statistics for dashboard
    int totalClicks = 0;
    int totalVisits = 0;
    int totalRecommended = 0;
    for (final item in _items) {
      totalClicks += (item['users_clicked'] ?? 0) as int;
      totalVisits += (item['visit_store'] ?? 0) as int;
      totalRecommended += (item['recommended'] ?? 0) as int;
    }

    final pages = [
      BrandDashboardScreen(
        totalClicks: totalClicks,
        totalVisits: totalVisits,
        totalRecommended: totalRecommended,
      ),
      BrandStatisticsScreen(token: widget.token, items: _items),
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
      bottomNavigationBar: _buildModernBrandNavBar(),
    );
  }
} 