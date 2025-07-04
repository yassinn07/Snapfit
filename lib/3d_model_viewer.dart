import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'config.dart';

class Model3DViewer extends StatelessWidget {
  final String modelPath;
  final String itemName;
  final String fontFamily;

  const Model3DViewer({
    Key? key,
    required this.modelPath,
    required this.itemName,
    required this.fontFamily,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validate and format the model path
    String formattedPath = _formatModelPath(modelPath);

    // Check if the path is valid
    if (!_isValidModelPath(formattedPath)) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                "Invalid 3D Model Path",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The 3D model path is not accessible: $modelPath",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD55F5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFD55F5F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.view_in_ar, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "3D Model - $itemName",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          // 3D Model Viewer
          Container(
            height: 400,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ModelViewer(
              src: formattedPath,
              alt: itemName,
              ar: true,
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
              loading: Loading.eager,
              onWebViewCreated: (controller) {
                print('ModelViewer WebView created for path: $formattedPath');
              },
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Add AR functionality here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('AR feature coming soon!'),
                        backgroundColor: const Color(0xFFD55F5F),
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar, size: 18),
                  label: const Text("View in AR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD55F5F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD55F5F), width: 1.5),
                    foregroundColor: const Color(0xFFD55F5F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
                  ),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatModelPath(String path) {
    // If it's already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // If it's an asset path, return as is
    if (path.startsWith('assets/')) {
      return path;
    }

    // If it's a Windows absolute path, reject it
    if (path.contains(':\\') || path.startsWith('C:\\') || path.startsWith('D:\\')) {
      return path; // Return as is, will be caught by validation
    }

    // If it's a relative path, assume it's from the static folder
    if (!path.startsWith('/')) {
      return '${Config.baseUrl}/static/$path';
    }

    return '${Config.baseUrl}$path';
  }

  bool _isValidModelPath(String path) {
    // Reject Windows absolute paths
    if (path.contains(':\\') || path.startsWith('C:\\') || path.startsWith('D:\\')) {
      return false;
    }

    // Accept HTTP URLs, asset paths, and relative paths
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('assets/') ||
        path.startsWith('${Config.baseUrl}/static/');
  }
}

// Helper function to show 3D model viewer
void show3DModelViewer(BuildContext context, String modelPath, String itemName, String fontFamily) {
  showDialog(
    context: context,
    builder: (context) => Model3DViewer(
      modelPath: modelPath,
      itemName: itemName,
      fontFamily: fontFamily,
    ),
  );
}