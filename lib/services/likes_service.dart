import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../filtered_shop_page.dart'; // For ShopItem model

class LikesService {
  final String? token;
  
  LikesService({required this.token});

  // Get the token with a default empty string if null
  String get _authToken => token ?? '';

  // Fetch all liked items for the current user
  Future<List<ShopItem>> getLikedItems() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/likes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> likesData = json.decode(response.body);
        List<ShopItem> items = [];

        // Format backend data into ShopItem objects
        for (var itemData in likesData) {
          items.add(
            ShopItem(
              id: itemData['id'].toString(),
              name: itemData['name'] ?? itemData['subtype'] ?? 'Item',
              description: itemData['description'] ?? '',
              category: itemData['apparel_type'] ?? 'Unknown',
              brand: itemData['brand'] ?? 'Unknown',
              price: itemData['price'] != null ? '${itemData['price']} EGP' : 'Price unavailable',
              imageUrl: itemData['path'],
              purchaseLink: itemData['purchase_link'],
              isFavorite: true, // These are liked items, so they are favorites
              color: itemData['color'] ?? '',
              size: itemData['size'] ?? '',
              occasion: itemData['occasion'] ?? '',
              gender: itemData['gender'] ?? '',
            ),
          );
        }
        return items;
      } else if (response.statusCode == 401) {
        // If unauthorized (no token or invalid token)
        return [];
      } else {
        throw Exception('Failed to load liked items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting liked items: $e');
      // Return an empty list instead of mock data
      return [];
    }
  }

  // Add an item to the likes
  Future<bool> addLike(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/likes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'item_id': itemId}),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        print('Unauthorized: User must be logged in to like items');
        return false;
      } else {
        print('Failed to add like: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding like: $e');
      return false;
    }
  }

  // Remove an item from likes
  Future<bool> removeLike(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/likes/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        print('Unauthorized: User must be logged in to unlike items');
        return false; 
      } else {
        print('Failed to remove like: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error removing like: $e');
      return false;
    }
  }

  // Check if an item is liked by the current user
  Future<bool> isItemLiked(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/likes/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['liked'] == true;
      } else if (response.statusCode == 401) {
        // If unauthorized, assume not liked
        return false;
      } else {
        print('Failed to check if item is liked: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking if item is liked: $e');
      return false;
    }
  }
} 