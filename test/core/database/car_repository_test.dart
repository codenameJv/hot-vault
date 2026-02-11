import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hot_vault/core/models/hot_wheels_car.dart';
import 'package:hot_vault/core/database/car_repository.dart';

// ignore: unnecessary_import

import '../../helpers/test_helpers.dart';

/// A testable version of CarRepository that works with in-memory database
class TestableCarRepository {
  final Database _db;
  static const String _tableCars = 'cars';

  TestableCarRepository(this._db);

  Future<HotWheelsCar> insertCar(HotWheelsCar car) async {
    await _db.insert(_tableCars, car.toMap());
    return car;
  }

  Future<HotWheelsCar?> getCarById(String id) async {
    final maps = await _db.query(
      _tableCars,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HotWheelsCar.fromMap(maps.first);
  }

  Future<List<HotWheelsCar>> getAllCars({
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await _db.query(
      _tableCars,
      orderBy: '$orderByColumn $orderDirection',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  Future<List<HotWheelsCar>> getCarsPaginated({
    required int limit,
    required int offset,
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await _db.query(
      _tableCars,
      orderBy: '$orderByColumn $orderDirection',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  Future<List<HotWheelsCar>> searchCars(String query) async {
    final maps = await _db.query(
      _tableCars,
      where: 'name LIKE ? OR series LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  Future<int> updateCar(HotWheelsCar car) async {
    final updatedCar = car.copyWith(updatedAt: DateTime.now());
    return await _db.update(
      _tableCars,
      updatedCar.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<int> deleteCar(String id) async {
    return await _db.delete(
      _tableCars,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllCars() async {
    return await _db.delete(_tableCars);
  }

  Future<int> getTotalCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableCars',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<HotWheelsCar>> getFavoriteCars({
    SortField sortBy = SortField.createdAt,
    SortOrder order = SortOrder.descending,
  }) async {
    final orderByColumn = _getSortColumn(sortBy);
    final orderDirection = order == SortOrder.ascending ? 'ASC' : 'DESC';

    final maps = await _db.query(
      _tableCars,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: '$orderByColumn $orderDirection',
    );

    return maps.map((map) => HotWheelsCar.fromMap(map)).toList();
  }

  Future<int> toggleFavorite(String carId, bool isFavorite) async {
    return await _db.update(
      _tableCars,
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [carId],
    );
  }

  Future<int> getFavoritesCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableCars WHERE isFavorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getAllSeries() async {
    final maps = await _db.rawQuery(
      'SELECT DISTINCT series FROM $_tableCars WHERE series IS NOT NULL ORDER BY series ASC',
    );
    return maps.map((m) => m['series'] as String).toList();
  }

  Future<List<int>> getAllYears() async {
    final maps = await _db.rawQuery(
      'SELECT DISTINCT year FROM $_tableCars WHERE year IS NOT NULL ORDER BY year DESC',
    );
    return maps.map((m) => m['year'] as int).toList();
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

void main() {
  late TestDatabaseHelper dbHelper;
  late TestableCarRepository repository;

  setUpAll(() {
    initializeTestDatabase();
  });

  setUp(() async {
    dbHelper = TestDatabaseHelper();
    final db = await dbHelper.database;
    repository = TestableCarRepository(db);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CarRepository', () {
    group('insertCar', () {
      test('should insert a car and return it with correct data', () async {
        final car = HotWheelsCar(
          name: 'Test Car',
          series: 'Mainline',
          year: 2024,
          condition: 'Mint',
        );

        final result = await repository.insertCar(car);

        expect(result.id, equals(car.id));
        expect(result.name, equals('Test Car'));
        expect(result.series, equals('Mainline'));
        expect(result.year, equals(2024));
        expect(result.condition, equals('Mint'));
      });

      test('should generate unique IDs for each car', () async {
        final car1 = HotWheelsCar(name: 'Car 1');
        final car2 = HotWheelsCar(name: 'Car 2');

        await repository.insertCar(car1);
        await repository.insertCar(car2);

        expect(car1.id, isNot(equals(car2.id)));
      });
    });

    group('getCarById', () {
      test('should return the correct car by ID', () async {
        final car = HotWheelsCar(name: 'Find Me', series: 'Premium');
        await repository.insertCar(car);

        final result = await repository.getCarById(car.id);

        expect(result, isNotNull);
        expect(result!.name, equals('Find Me'));
        expect(result.series, equals('Premium'));
      });

      test('should return null for non-existent ID', () async {
        final result = await repository.getCarById('non-existent-id');

        expect(result, isNull);
      });
    });

    group('getAllCars', () {
      test('should return empty list when no cars exist', () async {
        final result = await repository.getAllCars();

        expect(result, isEmpty);
      });

      test('should return all cars sorted by createdAt descending by default', () async {
        final car1 = HotWheelsCar(name: 'First Car');
        await repository.insertCar(car1);

        await Future.delayed(const Duration(milliseconds: 10));

        final car2 = HotWheelsCar(name: 'Second Car');
        await repository.insertCar(car2);

        final result = await repository.getAllCars();

        expect(result.length, equals(2));
        expect(result[0].name, equals('Second Car'));
        expect(result[1].name, equals('First Car'));
      });

      test('should sort cars by name ascending when specified', () async {
        await repository.insertCar(HotWheelsCar(name: 'Zebra'));
        await repository.insertCar(HotWheelsCar(name: 'Alpha'));
        await repository.insertCar(HotWheelsCar(name: 'Beta'));

        final result = await repository.getAllCars(
          sortBy: SortField.name,
          order: SortOrder.ascending,
        );

        expect(result[0].name, equals('Alpha'));
        expect(result[1].name, equals('Beta'));
        expect(result[2].name, equals('Zebra'));
      });
    });

    group('getCarsPaginated', () {
      test('should return limited number of cars', () async {
        for (int i = 0; i < 10; i++) {
          await repository.insertCar(HotWheelsCar(name: 'Car $i'));
        }

        final result = await repository.getCarsPaginated(limit: 5, offset: 0);

        expect(result.length, equals(5));
      });

      test('should skip cars based on offset', () async {
        for (int i = 0; i < 10; i++) {
          await repository.insertCar(HotWheelsCar(name: 'Car $i'));
          await Future.delayed(const Duration(milliseconds: 5));
        }

        final page1 = await repository.getCarsPaginated(limit: 3, offset: 0);
        final page2 = await repository.getCarsPaginated(limit: 3, offset: 3);

        expect(page1.length, equals(3));
        expect(page2.length, equals(3));

        // Ensure no overlap
        final page1Ids = page1.map((c) => c.id).toSet();
        final page2Ids = page2.map((c) => c.id).toSet();
        expect(page1Ids.intersection(page2Ids), isEmpty);
      });

      test('should return empty list when offset exceeds total count', () async {
        await repository.insertCar(HotWheelsCar(name: 'Only Car'));

        final result = await repository.getCarsPaginated(limit: 10, offset: 100);

        expect(result, isEmpty);
      });
    });

    group('searchCars', () {
      test('should find cars matching name', () async {
        await repository.insertCar(HotWheelsCar(name: 'Red Baron'));
        await repository.insertCar(HotWheelsCar(name: 'Blue Thunder'));
        await repository.insertCar(HotWheelsCar(name: 'Red Rider'));

        final result = await repository.searchCars('Red');

        expect(result.length, equals(2));
        expect(result.every((c) => c.name.contains('Red')), isTrue);
      });

      test('should find cars matching series', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', series: 'Super Treasure Hunt'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2', series: 'Mainline'));
        await repository.insertCar(HotWheelsCar(name: 'Car 3', series: 'Treasure Hunt'));

        final result = await repository.searchCars('Treasure');

        expect(result.length, equals(2));
      });

      test('should find cars matching notes', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', notes: 'Found at Walmart'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2', notes: 'Gift from friend'));

        final result = await repository.searchCars('Walmart');

        expect(result.length, equals(1));
        expect(result[0].name, equals('Car 1'));
      });

      test('should return empty list for no matches', () async {
        await repository.insertCar(HotWheelsCar(name: 'Test Car'));

        final result = await repository.searchCars('NonExistent');

        expect(result, isEmpty);
      });
    });

    group('updateCar', () {
      test('should update car data', () async {
        final car = HotWheelsCar(name: 'Original Name', condition: 'Good');
        await repository.insertCar(car);

        final updatedCar = car.copyWith(name: 'Updated Name', condition: 'Mint');
        await repository.updateCar(updatedCar);

        final result = await repository.getCarById(car.id);

        expect(result!.name, equals('Updated Name'));
        expect(result.condition, equals('Mint'));
      });

      test('should update the updatedAt timestamp', () async {
        final car = HotWheelsCar(name: 'Test Car');
        await repository.insertCar(car);

        await Future.delayed(const Duration(milliseconds: 50));

        final updatedCar = car.copyWith(name: 'New Name');
        await repository.updateCar(updatedCar);

        final result = await repository.getCarById(car.id);

        expect(result!.updatedAt.isAfter(car.updatedAt), isTrue);
      });
    });

    group('deleteCar', () {
      test('should remove car from database', () async {
        final car = HotWheelsCar(name: 'To Be Deleted');
        await repository.insertCar(car);

        await repository.deleteCar(car.id);

        final result = await repository.getCarById(car.id);
        expect(result, isNull);
      });

      test('should return 0 for non-existent car', () async {
        final result = await repository.deleteCar('non-existent-id');

        expect(result, equals(0));
      });

      test('should only delete specified car', () async {
        final car1 = HotWheelsCar(name: 'Keep Me');
        final car2 = HotWheelsCar(name: 'Delete Me');
        await repository.insertCar(car1);
        await repository.insertCar(car2);

        await repository.deleteCar(car2.id);

        final remaining = await repository.getAllCars();
        expect(remaining.length, equals(1));
        expect(remaining[0].name, equals('Keep Me'));
      });
    });

    group('deleteAllCars', () {
      test('should remove all cars from database', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2'));
        await repository.insertCar(HotWheelsCar(name: 'Car 3'));

        await repository.deleteAllCars();

        final result = await repository.getAllCars();
        expect(result, isEmpty);
      });
    });

    group('getTotalCount', () {
      test('should return 0 for empty database', () async {
        final result = await repository.getTotalCount();

        expect(result, equals(0));
      });

      test('should return correct count', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2'));
        await repository.insertCar(HotWheelsCar(name: 'Car 3'));

        final result = await repository.getTotalCount();

        expect(result, equals(3));
      });
    });

    group('toggleFavorite', () {
      test('should set favorite to true', () async {
        final car = HotWheelsCar(name: 'Test Car', isFavorite: false);
        await repository.insertCar(car);

        await repository.toggleFavorite(car.id, true);

        final result = await repository.getCarById(car.id);
        expect(result!.isFavorite, isTrue);
      });

      test('should set favorite to false', () async {
        final car = HotWheelsCar(name: 'Test Car', isFavorite: true);
        await repository.insertCar(car);

        await repository.toggleFavorite(car.id, false);

        final result = await repository.getCarById(car.id);
        expect(result!.isFavorite, isFalse);
      });
    });

    group('getFavoriteCars', () {
      test('should return only favorite cars', () async {
        await repository.insertCar(HotWheelsCar(name: 'Favorite 1', isFavorite: true));
        await repository.insertCar(HotWheelsCar(name: 'Not Favorite', isFavorite: false));
        await repository.insertCar(HotWheelsCar(name: 'Favorite 2', isFavorite: true));

        final result = await repository.getFavoriteCars();

        expect(result.length, equals(2));
        expect(result.every((c) => c.isFavorite), isTrue);
      });

      test('should return empty list when no favorites', () async {
        await repository.insertCar(HotWheelsCar(name: 'Not Favorite'));

        final result = await repository.getFavoriteCars();

        expect(result, isEmpty);
      });
    });

    group('getFavoritesCount', () {
      test('should return correct count of favorites', () async {
        await repository.insertCar(HotWheelsCar(name: 'Fav 1', isFavorite: true));
        await repository.insertCar(HotWheelsCar(name: 'Not Fav', isFavorite: false));
        await repository.insertCar(HotWheelsCar(name: 'Fav 2', isFavorite: true));

        final result = await repository.getFavoritesCount();

        expect(result, equals(2));
      });
    });

    group('getAllSeries', () {
      test('should return unique series sorted alphabetically', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', series: 'Mainline'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2', series: 'Premium'));
        await repository.insertCar(HotWheelsCar(name: 'Car 3', series: 'Mainline'));
        await repository.insertCar(HotWheelsCar(name: 'Car 4', series: 'Boulevard'));

        final result = await repository.getAllSeries();

        expect(result, equals(['Boulevard', 'Mainline', 'Premium']));
      });

      test('should not include null series', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', series: 'Mainline'));
        await repository.insertCar(HotWheelsCar(name: 'Car 2'));

        final result = await repository.getAllSeries();

        expect(result, equals(['Mainline']));
      });
    });

    group('getAllYears', () {
      test('should return unique years sorted descending', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', year: 2020));
        await repository.insertCar(HotWheelsCar(name: 'Car 2', year: 2024));
        await repository.insertCar(HotWheelsCar(name: 'Car 3', year: 2020));
        await repository.insertCar(HotWheelsCar(name: 'Car 4', year: 2022));

        final result = await repository.getAllYears();

        expect(result, equals([2024, 2022, 2020]));
      });

      test('should not include null years', () async {
        await repository.insertCar(HotWheelsCar(name: 'Car 1', year: 2024));
        await repository.insertCar(HotWheelsCar(name: 'Car 2'));

        final result = await repository.getAllYears();

        expect(result, equals([2024]));
      });
    });
  });
}
