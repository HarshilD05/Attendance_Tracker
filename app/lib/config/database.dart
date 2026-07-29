import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Load the SQL schema file
    final schemaString = await rootBundle.loadString('lib/config/schema.sql');
    
    // Split by semicolon to get individual commands
    final statements = schemaString.split(';');

    // Execute each command
    for (var statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE Semester ADD COLUMN min_attendance_req REAL NOT NULL DEFAULT 75.0',
      );
    }
    if (oldVersion < 3) {
      // Add a unique index to enforce the UNIQUE(sem_id, name) constraint on existing DBs
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_subjects_sem_name ON Subjects(sem_id, name)',
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
