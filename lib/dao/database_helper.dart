import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gohealth.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        age INTEGER,
        height REAL,
        weight REAL,
        profile_image TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        access_token TEXT,
        refresh_token TEXT,
        expires_at TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Add indexes for better query performance
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_sync_status ON users(is_synced)');
    await db
        .execute('CREATE INDEX idx_sessions_user_id ON user_sessions(user_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_active ON user_sessions(is_active)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in the future
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_sessions');
      await txn.delete('users');
    });
  }

  // Get database path
  Future<String> getDatabasePath() async {
    String path = join(await getDatabasesPath(), 'gohealth.db');
    return path;
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final path = await getDatabasePath();

    // Get database version
    final version = await db.getVersion();

    // Get table info
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // Get database size (if file exists)
    final file = File(path);
    final size = await file.exists() ? await file.length() : 0;

    return {
      'path': path,
      'exists': await file.exists(),
      'version': version,
      'size_bytes': size,
      'size_mb': (size / (1024 * 1024)).toStringAsFixed(2),
      'tables': tables.map((table) => table['name']).toList(),
      'created_at': await file.exists()
          ? (await file.lastModified()).toIso8601String()
          : null,
    };
  }
}
