// lib/constants.dart
// This file contains configuration constants for the app

import 'package:flutter/material.dart';

class ApiConstants {
  // Base API URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // Use 10.0.2.2 for Android emulator
  
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

void showThemedSnackBar(BuildContext context, String message, {String type = 'normal'}) {
  Color backgroundColor;
  Icon? icon;
  TextStyle textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontFamily: 'Archivo');
  switch (type) {
    case 'critical':
      backgroundColor = Colors.red;
      icon = const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24);
      textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      break;
    case 'success':
      backgroundColor = Colors.green;
      icon = const Icon(Icons.check_circle, color: Colors.white, size: 24);
      break;
    default:
      backgroundColor = const Color(0xFFD55F5F); // app theme red
      icon = null;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              message,
              style: textStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 6,
      duration: const Duration(seconds: 2),
    ),
  );
} 