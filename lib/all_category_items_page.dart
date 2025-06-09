import 'package:flutter/material.dart';
import 'services/closet_service.dart';
import 'closet_item_widgets.dart';

class AllCategoryItemsPage extends StatelessWidget {
  final String token;
  final String category;
  final String? subcategory;
  final List<ClosetItem> closetItems;

  const AllCategoryItemsPage({
    Key? key,
    required this.token,
    required this.category,
    this.subcategory,
    required this.closetItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String defaultFontFamily = 'Archivo';
    // Filter items by category and subcategory
    List<ClosetItem> filteredItems = closetItems
        .where((item) => item.category == category)
        .toList();
    if (subcategory != null &&
        subcategory != "All Upper Body" &&
        subcategory != "All Lower Body" &&
        subcategory != "All Shoes") {
      filteredItems = filteredItems
          .where((item) => item.subcategory.toLowerCase() == subcategory!.toLowerCase())
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subcategory != null ? "$subcategory" : category,
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.02 * 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: filteredItems.isEmpty
          ? const Center(child: Text('No items found.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return buildClosetItemCard(
                    context: context,
                    item: item,
                    fontFamily: defaultFontFamily,
                    onTap: () {},
                    onEditTap: null,
                    onDeleteTap: null,
                  );
                },
              ),
            ),
    );
  }
} 