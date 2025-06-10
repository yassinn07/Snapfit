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
                    print('Favorite item: ' + item.toString());
                    return InkWell(
                      onTap: () {
                        final shopItem = ShopItem(
                          id: (item['id'] ?? '').toString(),
                          name: item['name'] ?? item['subtype'] ?? 'Unknown Item',
                          description: item['description'] ?? '',
                          category: item['category'] ?? item['apparel_type'] ?? '',
                          userName: item['user_name'] ?? '',
                          price: item['price'] != null ? item['price'].toString() : '',
                          imageUrl: item['image_url'] ?? item['path'],
                          isFavorite: true,
                          purchaseLink: item['purchase_link'],
                          color: item['color'] ?? '',
                          size: item['size'] ?? '',
                          occasion: item['occasion'] ?? '',
                          gender: item['gender'] ?? '',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemScreen(item: shopItem, token: widget.token),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    child: (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                                        ? Image.network(
                                            getFullImageUrl(item['image_url']),
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : (item['path'] != null && item['path'].toString().isNotEmpty
                                            ? Image.network(
                                                getFullImageUrl(item['path']),
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                height: 160,
                                                width: double.infinity,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                              )),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Material(
                                      color: Colors.white,
                                      shape: const CircleBorder(),
                                      elevation: 2,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          _removeFavorite(fav['item_id'].toString());
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? item['subtype'] ?? 'Unknown Item',
                                    style: const TextStyle(
                                      fontFamily: 'Archivo',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD55F5F),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 24, thickness: 1.2),
                                  _buildDetailRow('Brand',
                                    item['user_name'] ?? fav['user_name'] ?? item['brand'] ?? fav['brand'] ?? item['item_brand'] ?? item['item']?['brand'] ?? ''
                                  ),
                                  _buildDetailRow('Category', item['category'] ?? item['apparel_type'] ?? ''),
                                  _buildDetailRow('Price', item['price'] != null ? '${item['price']}' : ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Archivo')),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Archivo'))),
        ],
      ),
    );
  }
} 