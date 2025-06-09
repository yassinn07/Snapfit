import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class Brand {
  final String id;
  final String name;
  final String description;
  
  Brand({
    required this.id,
    required this.name,
    required this.description,
  });
  
  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['brand_id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class BrandService {
  final String? token;
  
  BrandService({required this.token});

  // Get the token with a default empty string if null
  String get _authToken => token ?? '';

  // Fetch all local brands from the backend
  Future<List<String>> getLocalBrands() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/brands'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> brandsData = json.decode(response.body);
        
        // Extract brand names from the response
        List<String> brandNames = [];
        for (var brandData in brandsData) {
          final String name = brandData['name'] ?? '';
          if (name.isNotEmpty) {
            brandNames.add(name);
          }
        }
        
        return brandNames;
      } else if (response.statusCode == 401) {
        // If unauthorized, return empty list
        print('Unauthorized request to get brands');
        return [];
      } else {
        throw Exception('Failed to load local brands: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching local brands: $e');
      return [];
    }
  }
  
  // Get all brands with complete information
  Future<List<Brand>> getAllBrands() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/brands'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> brandsData = json.decode(response.body);
        return brandsData.map((data) => Brand.fromJson(data)).toList();
      } else if (response.statusCode == 401) {
        print('Unauthorized request to get brands');
        return [];
      } else {
        throw Exception('Failed to load brands: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  // Get details about a specific brand
  Future<Brand?> getBrandDetails(String brandId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/brands/$brandId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Brand.fromJson(data);
      } else if (response.statusCode == 404) {
        print('Brand not found: $brandId');
        return null;
      } else {
        throw Exception('Failed to load brand details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching brand details: $e');
      return null;
    }
  }
} 