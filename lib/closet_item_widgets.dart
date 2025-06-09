import 'package:flutter/material.dart';
import 'services/closet_service.dart';

// Helper method to build the closet items list
Widget buildClosetItemsRow({
  required BuildContext context,
  required List<ClosetItem> items,
  required String fontFamily,
  required Function(ClosetItem) onTap,
  required Function(ClosetItem) onEdit,
  required Function(ClosetItem) onDelete,
  required VoidCallback onAddItem,
}) {
  return SizedBox(
    height: 201,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length, // Remove +1 for Add Item card
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: buildClosetItemCard(
            context: context,
            item: item,
            fontFamily: fontFamily,
            onTap: () => onTap(item),
            onEditTap: () => onEdit(item),
            onDeleteTap: () => onDelete(item)
          )
        );
      }
    )
  );
}

class ClosetItemDetailsDialog extends StatelessWidget {
  final ClosetItem item;
  final String fontFamily;
  const ClosetItemDetailsDialog({required this.item, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!.startsWith('http')
                      ? item.imageUrl!
                      : 'http://10.0.2.2:8000/static/${item.imageUrl!}',
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.checkroom, size: 80, color: Colors.grey),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
                  const SizedBox(height: 10),
                  _buildDetailRow("Subcategory", item.subcategory),
                  _buildDetailRow("Color", item.color),
                  _buildDetailRow("Size", item.size),
                  _buildDetailRow("Occasion", item.occasion),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600, fontFamily: fontFamily)),
          Expanded(child: Text(value, style: TextStyle(fontFamily: fontFamily))),
        ],
      ),
    );
  }
}

// Helper method to build a closet item card
Widget buildClosetItemCard({
  required BuildContext context,
  required ClosetItem item,
  required String fontFamily,
  VoidCallback? onTap,
  VoidCallback? onEditTap,
  VoidCallback? onDeleteTap,
}) {
  return InkWell(
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => ClosetItemDetailsDialog(item: item, fontFamily: fontFamily),
      );
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 143,
      height: 201,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Stack(
        children: [
          // Item image or placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!.startsWith('http')
                      ? item.imageUrl!
                      : 'http://10.0.2.2:8000/static/${item.imageUrl!}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checkroom, size: 60, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 14,
                            color: Colors.grey.shade600
                          ),
                        ),
                        Text(
                          item.color,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            color: Colors.grey
                          ),
                        ),
                      ],
                    )
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.checkroom, size: 60, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          color: Colors.grey.shade600
                        ),
                      ),
                      Text(
                        item.color,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12,
                          color: Colors.grey
                        ),
                      ),
                    ],
                  )
            )
          ),
          // Delete button
          Positioned(
            bottom: 8,
            right: 8,
            child: buildItemCardOverlayButton(
              onTap: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Delete Item', style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to delete this item?', style: TextStyle(fontFamily: 'Archivo')),
                    actionsAlignment: MainAxisAlignment.end,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFD55F5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold)
                        ),
                        child: const Text('Yes'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD55F5F), width: 1.5),
                          foregroundColor: const Color(0xFFD55F5F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold)
                        ),
                        child: const Text('No'),
                      ),
                    ],
                  ),
                );
                if (shouldDelete == true && onDeleteTap != null) {
                  onDeleteTap();
                }
              },
              icon: Icons.delete_outline
            )
          ),
        ]
      )
    )
  );
}

// Helper method to build the Add Item card
Widget buildAddItemCard({
  required BuildContext context,
  required String fontFamily,
  required VoidCallback onTap
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 128,
      height: 201,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EE),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: Color(0xFFD55F5F),
              shape: BoxShape.circle
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24
              )
            )
          ),
          const SizedBox(height: 15),
          Text(
            "New Item",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.02 * 14,
              color: Colors.black
            )
          )
        ]
      )
    )
  );
}

// Helper method to build a button overlay for item cards
Widget buildItemCardOverlayButton({
  required IconData icon,
  VoidCallback? onTap
}) {
  return Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 1.0,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 33,
        height: 33,
        decoration: const BoxDecoration(
          shape: BoxShape.circle
        ),
        child: Center(
          child: Icon(
            icon,
            size: 17,
            color: Colors.black.withOpacity(0.7)
          )
        )
      )
    )
  );
} 