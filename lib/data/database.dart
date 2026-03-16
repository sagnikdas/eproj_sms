import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite database helper for Elder Shield.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();
  Database? _db;

  static const _dbName = 'elder_shield.db';
  static const _dbVersion = 1;

  // Table: analyzed messages
  static const tableMessages = 'analyzed_messages';
  static const tableReasons = 'message_reasons';

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        score REAL NOT NULL,
        band TEXT NOT NULL,
        feedback_label TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableReasons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id INTEGER NOT NULL,
        reason TEXT NOT NULL,
        FOREIGN KEY(message_id) REFERENCES $tableMessages(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for common query patterns.
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON $tableMessages(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_band ON $tableMessages(band)',
    );
    await db.execute(
      'CREATE INDEX idx_reasons_message_id ON $tableReasons(message_id)',
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
