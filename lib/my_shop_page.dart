import 'package:flutter/material.dart';
import 'liked_items_screen.dart';
import 'services/profile_service.dart';
import 'config.dart';
import 'constants.dart' show showThemedSnackBar;

class MyShopPage extends StatefulWidget {
  final String? token;
  final int userId;
  const MyShopPage({Key? key, this.token, required this.userId}) : super(key: key);

  @override
  State<MyShopPage> createState() => _MyShopPageState();
}

class _MyShopPageState extends State<MyShopPage> {
  late ProfileService _profileService;
  List<Map<String, dynamic>> _items = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(token: widget.token ?? '');
    _loadItems();
    _loadFavorites();
  }

  Future<void> _loadItems() async {
    // TODO: Replace with your backend call to fetch all shop items
    // Example placeholder:
    setState(() {
      _items = [
        // Example items
        {'id': '1', 'name': 'Jacket', 'price': 49.99, 'image_url': null},
        {'id': '2', 'name': 'Sneakers', 'price': 89.99, 'image_url': null},
      ];
      _isLoading = false;
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _profileService.getFavorites();
      setState(() {
        _favoriteIds = favorites.map<String>((item) => item['id'].toString()).toSet();
      });
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final itemId = item['id'].toString();
    final isFav = _favoriteIds.contains(itemId);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(itemId);
      } else {
        _favoriteIds.add(itemId);
      }
    });
    bool success = false;
    try {
      success = await _profileService.toggleFavorite(itemId);
      if (!success) {
        setState(() {
          if (isFav) {
            _favoriteIds.add(itemId);
          } else {
            _favoriteIds.remove(itemId);
          }
        });
        showThemedSnackBar(context, 'Failed to update favorite status', type: 'critical');
      }
    } catch (e) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(itemId);
        } else {
          _favoriteIds.remove(itemId);
        }
      });
      showThemedSnackBar(context, 'Error updating favorite status', type: 'critical');
    }
  }

  String _buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
    return '${Config.apiUrl}/static/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'Archivo';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('My Shop', style: TextStyle(fontFamily: fontFamily, color: Colors.black, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LikedItemsScreen(token: widget.token),
                ),
              ).then((_) => _loadFavorites());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No items yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: fontFamily)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isFavorite = _favoriteIds.contains(item['id'].toString());
                    return Card(
                      elevation: 4,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                                      ? Image.network(
                                          _buildImageUrl(item['image_url']),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => _toggleFavorite(item),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: fontFamily, color: Colors.black),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['price'] != null ? '\$${item['price'].toString()}' : '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: fontFamily),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 