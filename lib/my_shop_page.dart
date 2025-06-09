import 'package:flutter/material.dart';
import 'liked_items_screen.dart';
import 'services/profile_service.dart';

class MyShopPage extends StatefulWidget {
  final String? token;
  const MyShopPage({Key? key, this.token}) : super(key: key);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite status')),
        );
      }
    } catch (e) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(itemId);
        } else {
          _favoriteIds.remove(itemId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorite status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
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
                      Text('No items yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                                      ? Image.network(
                                          item['image_url'],
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
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['price'] != null ? '\$24${item['price'].toString()}' : '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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