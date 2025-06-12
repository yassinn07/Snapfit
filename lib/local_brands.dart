// lib/local_brands.dart

import 'package:flutter/material.dart';
import 'filtered_shop_page.dart';
import 'services/brand_service.dart'; // Import for backend brand data

class LocalBrandsPage extends StatefulWidget {
  final String? token;
  final int userId;
  
  const LocalBrandsPage({this.token, required this.userId, super.key});

  @override
  State<LocalBrandsPage> createState() => _LocalBrandsPageState();
}

class _LocalBrandsPageState extends State<LocalBrandsPage> {
  List<String> brandNames = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late BrandService _brandService;

  @override
  void initState() {
    super.initState();
    _brandService = BrandService(token: widget.token ?? '');
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final brands = await _brandService.getLocalBrands();
      
      if (mounted) {
        setState(() {
          brandNames = brands;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading brands: $e';
          _isLoading = false;
        });
      }
      print('Error fetching brands: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: () => Navigator.of(context).pop()
        ),
        title: const Text(
          "Local Brands", 
          style: TextStyle(
            fontFamily: defaultFontFamily, 
            fontSize: 25, 
            fontWeight: FontWeight.w500, 
            color: Colors.black, 
            letterSpacing: -0.02 * 25
          )
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
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.red[600], fontFamily: defaultFontFamily),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchBrands,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBrands,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 20.0),
                    children: [
                      _buildAiStylistInfoCard(context, "Local Brands", defaultFontFamily),
                      const SizedBox(height: 30),

                      // Brand List Section
                      if (brandNames.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              "No local brands available at the moment.",
                              style: TextStyle(
                                fontFamily: defaultFontFamily,
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        ...brandNames.map((name) => _buildBrandRow(
                          context: context,
                          brandName: name,
                          fontFamily: defaultFontFamily,
                          onTap: () {
                            // Navigate to FilteredShopPage, filtering by this brand name
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FilteredShopPage(
                                filterTitle: name, // Pass brand name as filter title
                                filterType: FilterType.brand, // Specify filter type
                                token: widget.token, // Pass the token
                                userId: widget.userId, // Pass the userId
                              )),
                            );
                          }
                        )).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAiStylistInfoCard(BuildContext context, String filterName, String fontFamily) {
    Widget embeddedIcon = Container(
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 16
      ),
    );

    return InkWell(
      onTap: () {
        print("AI Stylist Info Card tapped");
      },
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F1EE),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy_outlined, size: 30, color: Colors.black),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Shop $filterName with your AI Stylist",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.02 * 20,
                      color: Colors.black
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.02 * 14,
                        color: Colors.black.withOpacity(0.9),
                        height: 1.2
                      ),
                      children: [
                        const TextSpan(text: "Tap the "),
                        WidgetSpan(
                          child: embeddedIcon,
                          alignment: PlaceholderAlignment.middle
                        ),
                        const TextSpan(text: " to see if the item matches your closet!"),
                      ]
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandRow({
    required BuildContext context,
    required String brandName,
    required String fontFamily,
    required VoidCallback onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      title: Text(
        brandName,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02 * 18,
          color: Colors.black
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: Colors.black54
      ),
      onTap: onTap,
    );
  }
}