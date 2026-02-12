import 'package:sqflite/sqflite.dart';

import '../models/hot_wheels_car.dart';
import 'database_helper.dart';

enum SortField { name, year, createdAt, acquiredDate }
enum SortOrder { ascending, descending }

class CarRepository {
  final DatabaseHelper _databaseHelper;

  CarRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  // CREATE
  Future<HotWheelsCar> insertCar(HotWheelsCar car) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableCars,
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return car;
  }

  // READ - Get single car by ID
  Future<HotWheelsCar?> getCarById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HotWheelsCar.fromMap(maps.first);
  }

  // READ - Get all cars
  Future<List<HotWheelsCar>> getAllCars({
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final db = await _databaseHelper.database;
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await db.query(
      DatabaseHelper.tableCars,
      orderBy: '$orderByColumn $orderDirection',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Get cars with pagination
  Future<List<HotWheelsCar>> getCarsPaginated({
    required int limit,
    required int offset,
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final db = await _databaseHelper.database;
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await db.query(
      DatabaseHelper.tableCars,
      orderBy: '$orderByColumn $orderDirection',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Search cars by name
  Future<List<HotWheelsCar>> searchCars(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'name LIKE ? OR series LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Find cars with exact name match (for duplicate detection)
  Future<List<HotWheelsCar>> findCarsByName(String name) async {
    final db = await _databaseHelper.database;
    final normalizedName = name.trim().toUpperCase();
    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'name = ?',
      whereArgs: [normalizedName],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Get duplicate counts for all car names
  Future<Map<String, int>> getDuplicateCounts() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT name, COUNT(*) as count
      FROM ${DatabaseHelper.tableCars}
      GROUP BY name
      HAVING COUNT(*) > 1
    ''');

    return {
      for (final map in maps) map['name'] as String: map['count'] as int,
    };
  }

  // READ - Get cars by series
  Future<List<HotWheelsCar>> getCarsBySeries(String series) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'series = ?',
      whereArgs: [series],
      orderBy: 'name ASC',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Get cars by year
  Future<List<HotWheelsCar>> getCarsByYear(int year) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'name ASC',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Get recent cars (for home screen)
  Future<List<HotWheelsCar>> getRecentCars({int limit = 5}) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCars,
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // READ - Get total count
  Future<int> getTotalCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableCars}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // READ - Get all unique series
  Future<List<String>> getAllSeries() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT series FROM ${DatabaseHelper.tableCars} WHERE series IS NOT NULL ORDER BY series ASC',
    );
    return maps.map((m) => m['series'] as String).toList();
  }

  // READ - Get all unique years
  Future<List<int>> getAllYears() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT year FROM ${DatabaseHelper.tableCars} WHERE year IS NOT NULL ORDER BY year DESC',
    );
    return maps.map((m) => m['year'] as int).toList();
  }

  // UPDATE
  Future<int> updateCar(HotWheelsCar car) async {
    final db = await _databaseHelper.database;
    final updatedCar = car.copyWith(updatedAt: DateTime.now());
    return await db.update(
      DatabaseHelper.tableCars,
      updatedCar.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  // DELETE
  Future<int> deleteCar(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableCars,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Delete all cars
  Future<int> deleteAllCars() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseHelper.tableCars);
  }

  // FAVORITES - Get all favorite cars
  Future<List<HotWheelsCar>> getFavoriteCars({
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final db = await _databaseHelper.database;
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: '$orderByColumn $orderDirection',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // FAVORITES - Get favorite cars with pagination
  Future<List<HotWheelsCar>> getFavoriteCarsPaginated({
    required int limit,
    required int offset,
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final db = await _databaseHelper.database;
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await db.query(
      DatabaseHelper.tableCars,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: '$orderByColumn $orderDirection',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  // FAVORITES - Toggle favorite status
  Future<int> toggleFavorite(String carId, bool isFavorite) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableCars,
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [carId],
    );
  }

  // FAVORITES - Get favorites count
  Future<int> getFavoritesCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableCars} WHERE isFavorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ANALYTICS - Get total spent on purchases
  Future<double> getTotalSpent() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(purchasePrice) as total FROM ${DatabaseHelper.tableCars} WHERE purchasePrice IS NOT NULL',
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  // READ - Get all image paths (for cleanup)
  Future<List<String>> getAllImagePaths() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT imagePath FROM ${DatabaseHelper.tableCars} WHERE imagePath IS NOT NULL',
    );
    return maps.map((m) => m['imagePath'] as String).toList();
  }

  String _getSortColumn(SortField field) {
    switch (field) {
      case SortField.name:
        return 'name';
      case SortField.year:
        return 'year';
      case SortField.createdAt:
        return 'createdAt';
      case SortField.acquiredDate:
        return 'acquiredDate';
    }
  }
}
