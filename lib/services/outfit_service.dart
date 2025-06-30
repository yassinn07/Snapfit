import 'dart:convert';
import 'package:http/http.dart' as http;
import '../my_outfits.dart'; // Import the Outfit model
import '../constants.dart'; // Import API constants

class OutfitService {
  final String token;
  final String baseUrl = ApiConstants.baseUrl; // Use constants instead of hardcoded URL
  
  OutfitService({required this.token});
  
  // Helper function to normalize image paths (replace backslashes with forward slashes)
  String _normalizeImagePath(String path) {
    return path.replaceAll('\\', '/');
  }
  
  // Get all outfits for the logged-in user
  Future<List<Outfit>> getUserOutfits() async {
    try {
      print('DEBUG: getUserOutfits called with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/outfits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('DEBUG: getUserOutfits response status: \\${response.statusCode}');
      print('DEBUG: getUserOutfits response body: \\${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        print('DEBUG: getUserOutfits parsed responseData length: \\${responseData.length}');
        return responseData.map((outfitData) => _parseOutfit(outfitData)).toList();
      } else {
        // Handle error
        print('Failed to load outfits. Status code: \\${response.statusCode}');
        print('Response body: \\${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception when getting outfits: $e');
      return [];
    }
  }
  
  // Toggle the favorite status of an outfit
  Future<bool> toggleOutfitFavorite(String outfitId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/outfits/$outfitId/toggle-favorite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception when toggling favorite: $e');
      return false;
    }
  }
  
  // Create a new outfit
  Future<Outfit?> createOutfit({
    required int topId,
    required int bottomId,
    required int shoesId,
    String? name,
    List<String> tags = const [],
  }) async {
    try {
      final Map<String, dynamic> outfitData = {
        'top_id': topId,
        'bottom_id': bottomId,
        'shoes_id': shoesId,
        'name': name,
        'tags': tags,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/outfits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(outfitData),
      );
      
      if (response.statusCode == 201) {
        final dynamic responseData = json.decode(response.body);
        return _parseOutfit(responseData);
      } else {
        print('Failed to create outfit. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception when creating outfit: $e');
      return null;
    }
  }
  
  // Delete an outfit
  Future<bool> deleteOutfit(String outfitId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/outfits/$outfitId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 204;
    } catch (e) {
      print('Exception when deleting outfit: $e');
      return false;
    }
  }
  
  // Helper method to parse outfit data from API response
  Outfit _parseOutfit(Map<String, dynamic> data) {
    final List<String> itemImageUrls = [
      _normalizeImagePath(data['top']['path']),
      _normalizeImagePath(data['bottom']['path']),
      _normalizeImagePath(data['shoes']['path']),
    ];
    return Outfit(
      id: data['id'].toString(),
      itemImageUrls: itemImageUrls,
      tags: List<String>.from(data['tags'] ?? []),
      isFavorite: data['is_favorite'] ?? false,
      top: data['top'] ?? {},
      bottom: data['bottom'] ?? {},
      shoes: data['shoes'] ?? {},
    );
  }

  // Helper to normalize image paths
  String normalizeImagePath(String path) => path.replaceAll('\\', '/');
} 