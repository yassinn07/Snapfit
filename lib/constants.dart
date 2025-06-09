// lib/constants.dart
// This file contains configuration constants for the app

class ApiConstants {
  // Base API URL
  static const String baseUrl = 'http://localhost:8000'; // Update with your server URL
  
  // API Endpoint paths
  static const String authEndpoint = '/auth/login';
  static const String registerEndpoint = '/users';
  static const String outfitsEndpoint = '/outfits';
  static const String clothesEndpoint = '/clothes';
  static const String userPreferencesEndpoint = '/users/preferences';
  
  // Other constants can be added here
}

class AppConstants {
  // App-specific constants
  static const String appName = 'SnapFit';
  static const String appVersion = '1.0.0';
  
  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  
  // Other constants can be added here
} 