import 'package:flutter/material.dart';
import 'filtered_shop_page.dart';
import 'item_screen.dart';
import 'services/profile_service.dart';

class LikedItemsScreen extends StatefulWidget {
  final String? token;

  const LikedItemsScreen({required this.token, super.key});

  @override
  State<LikedItemsScreen> createState() => _LikedItemsScreenState();
}

class _LikedItemsScreenState extends State<LikedItemsScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(token: widget.token ?? '');
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final favorites = await _profileService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _removeFavorite(String itemId) async {
    try {
      final success = await _profileService.removeFavorite(itemId);
      if (success) {
        if (mounted) {
          setState(() {
            _favorites.removeWhere((item) => item['item_id'].toString() == itemId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from favorites')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove from favorites')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'http://10.0.2.2:8000$path'; // Adjust for your backend if needed
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "My Favorites",
          style: TextStyle(
            fontFamily: defaultFontFamily, 
            fontSize: 25, 
            fontWeight: FontWeight.w500, 
            color: Colors.black, 
            letterSpacing: -0.02 * 25
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage, 
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchFavorites,
                    child: const Text("Retry"),
                  )
                ],
              )
            )
          : _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No favorite items yet', 
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: defaultFontFamily
                      )
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Items you like will appear here',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey, 
                        fontFamily: defaultFontFamily
                      ),
                    ),
                  ],
                )
              )
            : RefreshIndicator(
                onRefresh: _fetchFavorites,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    final item = fav['item'] ?? {};
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  getFullImageUrl(item['path']),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 170,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    height: 170,
                                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _removeFavorite(fav['item_id'].toString());
                                    },
                                    iconSize: 20,
                                    padding: EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['apparel_type'] != null && item['subtype'] != null
                                    ? '${item['apparel_type']} | ${item['subtype']}'
                                    : 'Unknown Item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['price'] != null
                                    ? '\$${item['price'].toString()}'
                                    : '',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
} 