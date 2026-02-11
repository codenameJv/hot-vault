import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// A testable version of ImageService that uses a temp directory
class TestableImageService {
  final Directory _testDirectory;

  TestableImageService(this._testDirectory);

  Directory get _imageDirectory {
    final imageDir = Directory(path.join(_testDirectory.path, 'car_images'));
    if (!imageDir.existsSync()) {
      imageDir.createSync(recursive: true);
    }
    return imageDir;
  }

  /// Save an image file and return the new path
  Future<String> saveImage(File sourceFile) async {
    final imageDir = _imageDirectory;
    final extension = sourceFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final destinationPath = path.join(imageDir.path, fileName);

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
    final imageDir = _imageDirectory;
    if (!await imageDir.exists()) {
      return [];
    }

    final files = await imageDir.list().toList();
    return files.whereType<File>().map((file) => file.path).toList();
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

void main() {
  late Directory tempDir;
  late TestableImageService imageService;
  late File testImageFile;

  setUp(() async {
    // Create temp directory for tests
    tempDir = await Directory.systemTemp.createTemp('image_service_test_');
    imageService = TestableImageService(tempDir);

    // Create a test image file
    testImageFile = File(path.join(tempDir.path, 'test_image.jpg'));
    await testImageFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // Minimal JPEG header
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageService', () {
    group('saveImage', () {
      test('should copy image to app directory', () async {
        final savedPath = await imageService.saveImage(testImageFile);

        expect(await File(savedPath).exists(), isTrue);
        expect(savedPath, contains('car_images'));
      });

      test('should preserve file extension', () async {
        final savedPath = await imageService.saveImage(testImageFile);

        expect(savedPath, endsWith('.jpg'));
      });

      test('should generate unique filename for each save', () async {
        final path1 = await imageService.saveImage(testImageFile);

        // Wait a bit to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 10));

        final path2 = await imageService.saveImage(testImageFile);

        expect(path1, isNot(equals(path2)));
      });

      test('should preserve file content', () async {
        final originalContent = await testImageFile.readAsBytes();
        final savedPath = await imageService.saveImage(testImageFile);
        final savedContent = await File(savedPath).readAsBytes();

        expect(savedContent, equals(originalContent));
      });
    });

    group('deleteImage', () {
      test('should delete existing image and return true', () async {
        final savedPath = await imageService.saveImage(testImageFile);

        final result = await imageService.deleteImage(savedPath);

        expect(result, isTrue);
        expect(await File(savedPath).exists(), isFalse);
      });

      test('should return false for non-existent image', () async {
        final result = await imageService.deleteImage('/non/existent/path.jpg');

        expect(result, isFalse);
      });
    });

    group('imageExists', () {
      test('should return true for existing image', () async {
        final savedPath = await imageService.saveImage(testImageFile);

        final result = await imageService.imageExists(savedPath);

        expect(result, isTrue);
      });

      test('should return false for non-existent image', () async {
        final result = await imageService.imageExists('/non/existent/path.jpg');

        expect(result, isFalse);
      });

      test('should return false after image is deleted', () async {
        final savedPath = await imageService.saveImage(testImageFile);
        await imageService.deleteImage(savedPath);

        final result = await imageService.imageExists(savedPath);

        expect(result, isFalse);
      });
    });

    group('getAllImagePaths', () {
      test('should return empty list when no images exist', () async {
        final result = await imageService.getAllImagePaths();

        expect(result, isEmpty);
      });

      test('should return all saved image paths', () async {
        final path1 = await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        final path2 = await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        final path3 = await imageService.saveImage(testImageFile);

        final result = await imageService.getAllImagePaths();

        expect(result.length, equals(3));
        expect(result, contains(path1));
        expect(result, contains(path2));
        expect(result, contains(path3));
      });
    });

    group('cleanupOrphanedImages', () {
      test('should delete images not in valid paths list', () async {
        final validPath = await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        final orphanPath = await imageService.saveImage(testImageFile);

        final deletedCount = await imageService.cleanupOrphanedImages([validPath]);

        expect(deletedCount, equals(1));
        expect(await imageService.imageExists(validPath), isTrue);
        expect(await imageService.imageExists(orphanPath), isFalse);
      });

      test('should not delete images in valid paths list', () async {
        final path1 = await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        final path2 = await imageService.saveImage(testImageFile);

        final deletedCount = await imageService.cleanupOrphanedImages([path1, path2]);

        expect(deletedCount, equals(0));
        expect(await imageService.imageExists(path1), isTrue);
        expect(await imageService.imageExists(path2), isTrue);
      });

      test('should return 0 when no orphaned images exist', () async {
        final deletedCount = await imageService.cleanupOrphanedImages([]);

        expect(deletedCount, equals(0));
      });

      test('should delete all images when valid paths is empty', () async {
        await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        await imageService.saveImage(testImageFile);
        await Future.delayed(const Duration(milliseconds: 10));
        await imageService.saveImage(testImageFile);

        final deletedCount = await imageService.cleanupOrphanedImages([]);

        expect(deletedCount, equals(3));
        final remaining = await imageService.getAllImagePaths();
        expect(remaining, isEmpty);
      });
    });
  });
}
