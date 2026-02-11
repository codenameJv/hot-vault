import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static const String _databaseName = 'hot_vault.db';
  static const int _databaseVersion = 3;
  static const String tableCars = 'cars';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/$_databaseName';

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
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

    // Create index for common queries
    await db.execute('''
      CREATE INDEX idx_cars_name ON $tableCars (name)
    ''');
    await db.execute('''
      CREATE INDEX idx_cars_series ON $tableCars (series)
    ''');
    await db.execute('''
      CREATE INDEX idx_cars_year ON $tableCars (year)
    ''');
    await db.execute('''
      CREATE INDEX idx_cars_createdAt ON $tableCars (createdAt)
    ''');
    await db.execute('''
      CREATE INDEX idx_cars_isFavorite ON $tableCars (isFavorite)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addFavoriteColumnIfMissing(db);
    }
    if (oldVersion < 3) {
      await _addPriceColumnsIfMissing(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    // Safety check: ensure isFavorite column exists (handles failed migrations)
    await _addFavoriteColumnIfMissing(db);
  }

  Future<void> _addFavoriteColumnIfMissing(Database db) async {
    // Check if isFavorite column exists
    final result = await db.rawQuery('PRAGMA table_info($tableCars)');
    final hasIsFavorite = result.any((col) => col['name'] == 'isFavorite');

    if (!hasIsFavorite) {
      // Add isFavorite column
      await db.execute('''
        ALTER TABLE $tableCars ADD COLUMN isFavorite INTEGER DEFAULT 0
      ''');
      // Set all existing rows to 0 (not favorite)
      await db.execute('''
        UPDATE $tableCars SET isFavorite = 0 WHERE isFavorite IS NULL
      ''');
      // Create index if it doesn't exist
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_cars_isFavorite ON $tableCars (isFavorite)
      ''');
    }
  }

  Future<void> _addPriceColumnsIfMissing(Database db) async {
    final result = await db.rawQuery('PRAGMA table_info($tableCars)');
    final hasPurchasePrice = result.any((col) => col['name'] == 'purchasePrice');
    final hasSellingPrice = result.any((col) => col['name'] == 'sellingPrice');

    if (!hasPurchasePrice) {
      await db.execute('''
        ALTER TABLE $tableCars ADD COLUMN purchasePrice REAL
      ''');
    }
    if (!hasSellingPrice) {
      await db.execute('''
        ALTER TABLE $tableCars ADD COLUMN sellingPrice REAL
      ''');
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
