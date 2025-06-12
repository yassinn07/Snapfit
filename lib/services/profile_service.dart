import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? imageUrl;
  final String fitPreference;
  final List<String> lifestylePreferences;
  final String seasonPreference;
  final String ageGroup;
  final List<String> preferredColors;
  final List<String> excludedCategories;
  final String gender;
  final bool isBrand;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.imageUrl,
    required this.fitPreference,
    required this.lifestylePreferences,
    required this.seasonPreference,
    required this.ageGroup,
    required this.preferredColors,
    required this.excludedCategories,
    required this.gender,
    required this.isBrand,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['user_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['image_url'],
      fitPreference: json['fit_preference'] ?? 'Regular',
      lifestylePreferences: List<String>.from(json['lifestyle_preferences'] ?? []),
      seasonPreference: json['season_preference'] ?? 'Auto',
      ageGroup: json['age_group'] ?? '18-24',
      preferredColors: List<String>.from(json['preferred_colors'] ?? []),
      excludedCategories: List<String>.from(json['excluded_categories'] ?? []),
      gender: json['gender'] ?? '',
      isBrand: json['brand'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'image_url': imageUrl,
      'fit_preference': fitPreference,
      'lifestyle_preferences': lifestylePreferences,
      'season_preference': seasonPreference,
      'age_group': ageGroup,
      'preferred_colors': preferredColors,
      'excluded_categories': excludedCategories,
      'gender': gender,
      'brand': isBrand,
    };
  }
}

class ProfileService {
  final String token;
  
  ProfileService({required this.token});
  
  Future<UserProfile> getUserProfile() async {
    final url = Uri.parse('${Config.apiUrl}/users/me');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }
  
  Future<UserProfile> updatePreferences({
    required String fitPreference,
    required List<String> lifestylePreferences,
    required String seasonPreference,
    required String ageGroup,
    required List<String> preferredColors,
    required List<String> excludedCategories,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/users/preferences');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fit_preference': fitPreference,
          'lifestyle_preferences': lifestylePreferences,
          'season_preference': seasonPreference,
          'age_group': ageGroup,
          'preferred_colors': preferredColors,
          'excluded_categories': excludedCategories,
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }
  
  Future<UserProfile> updateUserInfo({
    required String name,
    required String phone,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/users/info');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'phone': phone,
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to update user info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update user info: $e');
    }
  }
  
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/users/password');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
  
  Future<bool> sendFeedback(String feedback) async {
    final url = Uri.parse('${Config.apiUrl}/users/feedback');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'feedback': feedback,
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to send feedback: $e');
    }
  }
  
  Future<String?> getProfilePicture() async {
    try {
      // First try to get the profile picture from the dedicated endpoint
      final url = Uri.parse('${Config.apiUrl}/users/profile-picture');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('profile_picture') && data['profile_picture'] != null) {
          return data['profile_picture'] as String;
        }
      }
      
      // If that fails, try to get it from the user profile
      final profile = await getUserProfile();
      return profile.imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String filePath) async {
    final url = Uri.parse('${Config.apiUrl}/users/profile-picture');
    
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response to get the URL if available
        Map<String, dynamic> result = {'success': true};
        try {
          final responseData = json.decode(response.body);
          if (responseData.containsKey('url')) {
            result['url'] = responseData['url'];
          }
        } catch (e) {
          print('Could not parse response body: $e');
        }
        return result;
      }
      return {'success': false};
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final url = Uri.parse('${Config.apiUrl}/users/favorites');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  Future<bool> toggleFavorite(String itemId) async {
    final url = Uri.parse('${Config.apiUrl}/users/favorites/$itemId');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Future<bool> removeFavorite(String itemId) async {
    final url = Uri.parse('${Config.apiUrl}/users/favorites/$itemId');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    final url = Uri.parse('${Config.apiUrl}/users/preferences');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load preferences: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user preferences: $e');
    }
  }

  static Future<void> logItemEvent({
    required int itemId,
    required int userId,
    required String eventType,
    required String token,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/brands/item_event');
    print('Posting event: item_id=[1m$itemId[0m, user_id=[1m$userId[0m, event_type=[1m$eventType[0m, token=[1m$token[0m to $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'item_id': itemId,
          'user_id': userId,
          'event_type': eventType,
        }),
      );
      print('Event POST response: [1m${response.statusCode}[0m ${response.body}');
    } catch (e) {
      print('Error posting event: $e');
    }
  }
} 