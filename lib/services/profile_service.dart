import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class UserProfile {
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
  
  UserProfile({
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
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
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
      print('Error fetching user profile: $e');
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
      print('Error updating preferences: $e');
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
      print('Error updating user info: $e');
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
      print('Error updating password: $e');
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
      print('Error sending feedback: $e');
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
      print('Error getting profile picture: $e');
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
      print('Error uploading profile picture: $e');
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
      print('Error fetching favorites: $e');
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
      print('Error toggling favorite: $e');
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
      print('Error removing favorite: $e');
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
      print('Error fetching user preferences: $e');
      throw Exception('Failed to load user preferences: $e');
    }
  }
} 