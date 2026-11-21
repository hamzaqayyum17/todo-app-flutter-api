import 'dart:async';
import 'package:path/path.dart';

class DBHelper {
  DBHelper._init();
  static final DBHelper instance = DBHelper._init();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initializeDB();
    return _db!;
  }

  Future<Database> _initializeDB() async {
    final dbPath = join(await getDatabasesPath(), 'todo.db');
    return await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE TodoTask(
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        priority INTEGER NOT NULL,
        completionStatus INTEGER NOT NULL
      )
    ''');
  }
}
