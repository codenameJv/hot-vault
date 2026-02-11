import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/car_repository.dart';
import '../models/hot_wheels_car.dart';
import 'image_service.dart';

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class ImportResult {
  final bool success;
  final String message;
  final int carsImported;
  final int imagesImported;

  ImportResult({
    required this.success,
    required this.message,
    this.carsImported = 0,
    this.imagesImported = 0,
  });
}

class BackupService {
  final CarRepository _carRepository;
  final ImageService _imageService;

  static const String _backupFileName = 'hotvault_backup';
  static const String _dataFileName = 'collection.json';
  static const String _imagesFolder = 'images';
  static const int _backupVersion = 1;

  BackupService({
    required CarRepository carRepository,
    required ImageService imageService,
  })  : _carRepository = carRepository,
        _imageService = imageService;

  /// Export the entire collection to a zip file and share it
  Future<BackupResult> exportCollection() async {
    try {
      // Get all cars from database
      final cars = await _carRepository.getAllCars();

      if (cars.isEmpty) {
        return BackupResult(
          success: false,
          message: 'No cars in collection to export',
        );
      }

      // Create archive
      final archive = Archive();

      // Prepare cars data with relative image paths
      final carsData = <Map<String, dynamic>>[];
      final imageFiles = <String, File>{};

      for (final car in cars) {
        final carMap = car.toMap();

        // Handle image - store with relative path in backup
        if (car.imagePath != null && car.imagePath!.isNotEmpty) {
          final imageFile = File(car.imagePath!);
          if (await imageFile.exists()) {
            final imageName = car.imagePath!.split('/').last;
            carMap['imagePath'] = '$_imagesFolder/$imageName';
            imageFiles[imageName] = imageFile;
          } else {
            carMap['imagePath'] = null;
          }
        }

        carsData.add(carMap);
      }

      // Create JSON data
      final backupData = {
        'version': _backupVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'totalCars': cars.length,
        'cars': carsData,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final jsonBytes = utf8.encode(jsonString);

      // Add JSON file to archive
      archive.addFile(ArchiveFile(
        _dataFileName,
        jsonBytes.length,
        jsonBytes,
      ));

      // Add images to archive
      for (final entry in imageFiles.entries) {
        final imageBytes = await entry.value.readAsBytes();
        archive.addFile(ArchiveFile(
          '$_imagesFolder/${entry.key}',
          imageBytes.length,
          imageBytes,
        ));
      }

      // Encode archive as zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        return BackupResult(
          success: false,
          message: 'Failed to create backup archive',
        );
      }

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = '${tempDir.path}/${_backupFileName}_$timestamp.zip';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);

      // Share the file
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: 'Hot Vault Collection Backup',
      );

      return BackupResult(
        success: true,
        message: 'Collection exported successfully (${cars.length} cars)',
        filePath: zipPath,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Export failed: ${e.toString()}',
      );
    }
  }

  /// Import a collection from a zip file
  Future<ImportResult> importCollection(String zipFilePath,
      {bool replaceExisting = false}) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) {
        return ImportResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Read and decode zip
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and read JSON data file
      final jsonFile = archive.findFile(_dataFileName);
      if (jsonFile == null) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file: missing collection data',
        );
      }

      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData['version'] as int?;
      if (version == null || version > _backupVersion) {
        return ImportResult(
          success: false,
          message: 'Unsupported backup version',
        );
      }

      final carsData = backupData['cars'] as List<dynamic>;
      if (carsData.isEmpty) {
        return ImportResult(
          success: false,
          message: 'Backup file contains no cars',
        );
      }

      // If replacing, delete existing data
      if (replaceExisting) {
        await _imageService.cleanupOrphanedImages([]);
        await _carRepository.deleteAllCars();
      }

      // Get image directory for saving imported images
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/car_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      int carsImported = 0;
      int imagesImported = 0;

      // Import each car
      for (final carData in carsData) {
        final carMap = Map<String, dynamic>.from(carData as Map);

        // Check if car already exists (by ID) before processing
        final carId = carMap['id'] as String;
        final existingCar = await _carRepository.getCarById(carId);

        // Skip if car exists and we're not replacing
        if (existingCar != null && !replaceExisting) {
          continue;
        }

        String? newImagePath;

        // Handle image import (only if we're going to use the car)
        final originalImagePath = carMap['imagePath'] as String?;
        if (originalImagePath != null &&
            originalImagePath.startsWith(_imagesFolder)) {
          final imageFile = archive.findFile(originalImagePath);
          if (imageFile != null) {
            // Save image to app directory
            final imageName = originalImagePath.split('/').last;
            newImagePath = '${imageDir.path}/$imageName';

            // Check if file already exists, generate new name if needed
            var destFile = File(newImagePath);
            if (await destFile.exists()) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final extension = imageName.split('.').last;
              final baseName =
                  imageName.substring(0, imageName.lastIndexOf('.'));
              newImagePath = '${imageDir.path}/${baseName}_$timestamp.$extension';
              destFile = File(newImagePath);
            }

            await destFile.writeAsBytes(imageFile.content as List<int>);
            imagesImported++;
          }
        }

        // Update image path in car data
        carMap['imagePath'] = newImagePath;

        // Create car from map and insert
        final car = HotWheelsCar.fromMap(carMap);

        if (existingCar == null) {
          await _carRepository.insertCar(car);
        } else {
          // Delete old image if replacing and paths differ
          if (existingCar.imagePath != null &&
              existingCar.imagePath != newImagePath) {
            await _imageService.deleteImage(existingCar.imagePath!);
          }
          await _carRepository.updateCar(car);
        }
        carsImported++;
      }

      return ImportResult(
        success: true,
        message: 'Import completed successfully',
        carsImported: carsImported,
        imagesImported: imagesImported,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }
}
