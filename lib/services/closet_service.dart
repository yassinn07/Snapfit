import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ClosetItem {
  final String id;
  final String name;
  final String category; // matches apparel_type in database
  final String subcategory; // matches subtype in database
  final String? imageUrl; // matches path in database
  final String color;
  final String size;
  final String occasion;
  final String gender;
  final String brand;
  final String? path3d; // Add this line for 3D model path

  ClosetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    this.imageUrl,
    required this.color,
    this.size = '',
    this.occasion = '',
    this.gender = '',
    this.brand = '',
    this.path3d, // Add this line
  });

  factory ClosetItem.fromJson(Map<String, dynamic> json) {
    return ClosetItem(
      id: json['id'].toString(),
      name: json['subtype'] ?? json['name'] ?? '',
      category: json['apparel_type'] ?? json['category'] ?? '',
      subcategory: json['subtype'] ?? json['subcategory'] ?? '',
      imageUrl: json['path'] ?? json['image_url'],
      color: json['color'] ?? 'Unknown',
      size: json['size'] ?? '',
      occasion: json['occasion'] ?? '',
      gender: json['gender'] ?? '',
      brand: json['brand'] ?? '',
      path3d: json['path_3d'], // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'apparel_type': category,
      'subtype': subcategory,
      'path': imageUrl,
      'color': color,
      'size': size,
      'occasion': occasion,
      'gender': gender,
      'brand': brand,
      'path_3d': path3d, // Add this line
    };
  }
}

class ClosetService {
  final String token;

  ClosetService({required this.token});

  Future<List<ClosetItem>> getClosetItems() async {
    final url = Uri.parse('${Config.apiUrl}/clothes/user');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => ClosetItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load closet items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching closet items: $e');
      throw Exception('Failed to load closet items: $e');
    }
  }

  Future<ClosetItem> addClosetItem(ClosetItem item) async {
    final url = Uri.parse('${Config.apiUrl}/clothes');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return ClosetItem.fromJson(data);
      } else {
        throw Exception('Failed to add closet item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding closet item: $e');
      throw Exception('Failed to add closet item: $e');
    }
  }

  Future<(bool, String?)> deleteClosetItem(String itemId) async {
    final url = Uri.parse('${Config.apiUrl}/clothes/$itemId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return (true, null);
      } else {
        String errorMsg = 'Failed to delete item.';
        try {
          final data = json.decode(response.body);
          if (data['detail'] != null) errorMsg = data['detail'];
        } catch (_) {}
        return (false, errorMsg);
      }
    } catch (e) {
      print('Error deleting closet item: $e');
      return (false, 'Error deleting item: $e');
    }
  }

  Future<ClosetItem> updateClosetItem(String itemId, ClosetItem item) async {
    final url = Uri.parse('${Config.apiUrl}/clothes/$itemId');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return ClosetItem.fromJson(data);
      } else {
        throw Exception('Failed to update closet item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating closet item: $e');
      throw Exception('Failed to update closet item: $e');
    }
  }

  Future<Map<String, dynamic>?> addItemWithImage(String imagePath) async {
    try {
      final url = Uri.parse('${Config.apiUrl}/clothes/upload');
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Item uploaded successfully');
        final responseData = json.decode(responseString);
        return responseData; // Return the response data containing id, path, url
      } else {
        print('Failed to upload item: ${response.statusCode}');
        print('Response: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading item with image: $e');
      return null;
    }
  }

  Future<ClosetItem?> addItemFull({
    required String name,
    required String category,
    required String subcategory,
    required String color,
    required String size,
    required String occasion,
    required String brand,
    required String gender,
    required String imagePath,
    required int userId,
  }) async {
    try {
      final url = Uri.parse('${Config.apiUrl}/clothes/');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      request.fields['user_id'] = userId.toString();
      request.fields['subtype'] = name; // or 'name' if backend expects that
      request.fields['apparel_type'] = category;
      request.fields['subtype'] = subcategory;
      request.fields['color'] = color;
      request.fields['size'] = size;
      request.fields['occasion'] = occasion;
      request.fields['brand'] = brand;
      request.fields['gender'] = gender;
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Item uploaded successfully');
        final responseData = json.decode(responseString);
        // Return the actual item with database ID
        return ClosetItem.fromJson(responseData);
      } else {
        print('Failed to upload item: ${response.statusCode}');
        print('Response: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading item with image: $e');
      return null;
    }
  }
} 