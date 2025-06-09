import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../filtered_shop_page.dart'; // For ShopItem model

class ShopService {
  final String? token;
  
  ShopService({required this.token});

  // Get the token with a default empty string if null
  String get _authToken => token ?? '';

  // Fetch all shop items from the backend
  Future<List<ShopItem>> getShopItems() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/shop/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsData = json.decode(response.body);
        List<ShopItem> items = [];

        for (var itemData in itemsData) {
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
              // Important: all items start with isFavorite = false
              // The favorites will be set in a separate call later
              isFavorite: false,
              color: itemData['color'] ?? '',
              size: itemData['size'] ?? '',
              occasion: itemData['occasion'] ?? '',
              gender: itemData['gender'] ?? '',
            )
          );
        }
        return items;
      } else {
        throw Exception('Failed to load shop items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching shop items: $e');
      return [];
    }
  }

  // Check if an item matches the user's style via AI
  Future<String?> checkAiMatch(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/ai/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'item_id': itemId}),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result['message'];
      } else {
        throw Exception('Failed to check AI match: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking AI match: $e');
      return 'Error connecting to AI service';
    }
  }

  // Get items by brand
  Future<List<ShopItem>> getItemsByBrand(String brandId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/shop/brands/$brandId/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsData = json.decode(response.body);
        List<ShopItem> items = [];

        for (var itemData in itemsData) {
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
              isFavorite: false,
              color: itemData['color'] ?? '',
              size: itemData['size'] ?? '',
              occasion: itemData['occasion'] ?? '',
              gender: itemData['gender'] ?? '',
            )
          );
        }
        return items;
      } else {
        throw Exception('Failed to load brand items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching brand items: $e');
      return [];
    }
  }

  // Get items by category (by apparel_type in the database)
  Future<List<ShopItem>> getItemsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/shop/categories/$category/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsData = json.decode(response.body);
        List<ShopItem> items = [];

        for (var itemData in itemsData) {
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
              isFavorite: false,
              color: itemData['color'] ?? '',
              size: itemData['size'] ?? '',
              occasion: itemData['occasion'] ?? '',
              gender: itemData['gender'] ?? '',
            )
          );
        }
        return items;
      } else {
        throw Exception('Failed to load category items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching category items: $e');
      return [];
    }
  }

  // Get store items
  Future<List<ShopItem>> getStoreItems() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/store/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('clothes') && responseData['clothes'] != null) {
          final List<dynamic> itemsData = json.decode(responseData['clothes']);
          List<ShopItem> items = [];

          for (var itemData in itemsData) {
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
                isFavorite: false,
                color: itemData['color'] ?? '',
                size: itemData['size'] ?? '',
                occasion: itemData['occasion'] ?? '',
                gender: itemData['gender'] ?? '',
              )
            );
          }
          return items;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load store items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching store items: $e');
      return [];
    }
  }
} 