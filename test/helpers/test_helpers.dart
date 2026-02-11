import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize sqflite FFI for desktop/test environments
void initializeTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Test database helper that uses in-memory database
class TestDatabaseHelper {
  Database? _database;
  static const String tableCars = 'cars';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCars (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        series TEXT,
        year INTEGER,
        imagePath TEXT,
        notes TEXT,
        condition TEXT,
        acquiredDate INTEGER,
        purchasePrice REAL,
        sellingPrice REAL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_cars_name ON $tableCars (name)');
    await db.execute('CREATE INDEX idx_cars_series ON $tableCars (series)');
    await db.execute('CREATE INDEX idx_cars_year ON $tableCars (year)');
    await db.execute('CREATE INDEX idx_cars_createdAt ON $tableCars (createdAt)');
    await db.execute('CREATE INDEX idx_cars_isFavorite ON $tableCars (isFavorite)');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
