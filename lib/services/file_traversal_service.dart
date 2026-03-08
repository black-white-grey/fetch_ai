import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class FileTraversalService {
  /// Scans internal storage for PDF and PPTX files.
  /// Skips hidden and Android system specific data directories to optimize performance.
  static Future<List<String>> findAcademicVaultFiles({
    String? customDirectory,
  }) async {
    List<String> foundPaths = [];

    // Request full storage access (needed for Android 11+)
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      // Fallback for older Android versions
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      // ignore: avoid_print
      print("Storage permissions not granted.");
      return foundPaths;
    }

    // Use the custom directory if provided, else root
    final root = Directory(customDirectory ?? '/storage/emulated/0/');
    if (!await root.exists()) {
      // ignore: avoid_print
      print("Target directory not found.");
      return foundPaths;
    }

    try {
      await for (var entity
          in root
              .list(recursive: true, followLinks: false)
              .handleError((e) {})) {
        if (entity is File) {
          final path = entity.path.toLowerCase();

          // Performance Optimization & Security:
          // Skip massive cache folders, Android app data, and hidden files/directories.
          if (path.contains('/android/') ||
              path.contains('/.') ||
              path.contains('cache')) {
            continue;
          }

          if (path.endsWith('.pdf') || path.endsWith('.pptx')) {
            foundPaths.add(entity.path);
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Traversal error: $e');
    }

    return foundPaths;
  }
}
