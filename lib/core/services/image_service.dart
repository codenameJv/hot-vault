import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() => _instance;

  ImageService._internal();

  static const String _imageFolder = 'car_images';

  /// Get the directory for storing car images
  Future<Directory> get _imageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/$_imageFolder');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  /// Save an image file and return the new path
  /// [sourceFile] - The original image file (e.g., from camera or gallery)
  /// Returns the path to the saved image in app documents
  Future<String> saveImage(File sourceFile) async {
    final imageDir = await _imageDirectory;
    final extension = sourceFile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$extension';
    final destinationPath = '${imageDir.path}/$fileName';

    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  /// Delete an image by its path
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if an image exists
  Future<bool> imageExists(String imagePath) async {
    final file = File(imagePath);
    return await file.exists();
  }

  /// Get all stored images
  Future<List<String>> getAllImagePaths() async {
    final imageDir = await _imageDirectory;
    if (!await imageDir.exists()) {
      return [];
    }

    final files = await imageDir.list().toList();
    return files
        .whereType<File>()
        .map((file) => file.path)
        .toList();
  }

  /// Clean up orphaned images (images not referenced in database)
  Future<int> cleanupOrphanedImages(List<String> validPaths) async {
    final allImages = await getAllImagePaths();
    int deletedCount = 0;

    for (final imagePath in allImages) {
      if (!validPaths.contains(imagePath)) {
        final deleted = await deleteImage(imagePath);
        if (deleted) deletedCount++;
      }
    }

    return deletedCount;
  }
}
