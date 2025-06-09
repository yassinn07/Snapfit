import 'dart:convert';
import 'package:http/http.dart' as http;
import '../my_outfits.dart'; // Import the Outfit model
import '../constants.dart'; // Import API constants

class OutfitService {
  final String token;
  final String baseUrl = ApiConstants.baseUrl; // Use constants instead of hardcoded URL
  
  OutfitService({required this.token});
  
  // Get all outfits for the logged-in user
  Future<List<Outfit>> getUserOutfits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/outfits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((outfitData) => _parseOutfit(outfitData)).toList();
      } else {
        // Handle error
        print('Failed to load outfits. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        
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
    // Extract the image URLs from the top, bottom, and shoes
    // Add baseUrl to the paths to create full URLs
    final List<String> itemImageUrls = [
      data['top']['path'].startsWith('http') 
          ? data['top']['path'] 
          : '$baseUrl/${data['top']['path']}',
      data['bottom']['path'].startsWith('http') 
          ? data['bottom']['path'] 
          : '$baseUrl/${data['bottom']['path']}',
      data['shoes']['path'].startsWith('http') 
          ? data['shoes']['path'] 
          : '$baseUrl/${data['shoes']['path']}',
    ];
    
    return Outfit(
      id: data['id'].toString(),
      itemImageUrls: itemImageUrls,
      tags: List<String>.from(data['tags'] ?? []),
      isFavorite: data['is_favorite'] ?? false,
    );
  }
} 