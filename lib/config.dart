import 'package:flutter/foundation.dart'; // For kIsWeb
// Optional, if needed elsewhere
import 'dart:io';                        // For Platform detection

class Config {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';    // Web (localhost)
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';     // Android Emulator
      //return 'http://192.168.1.13:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';    // iOS Simulator
    } else {
      // Fallback for physical devices (use your machine's LAN IP)
      return 'http://192.168.1.13:8000';  // Replace with your actual IP
    }
  }
}