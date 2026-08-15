import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';


class AppDatabase {
  static const String landmarks = 'landmarks';
  static const String visits = 'visits';
  static const String deleted = 'deleted_landmarks';

  static Database? _db;

  static Future<Database> open() async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'landmarks.db'),
      version: 1,
      onCreate: (db, _) async {

        await db.execute('''
          CREATE TABLE $landmarks (
            id           INTEGER PRIMARY KEY,
            title        TEXT    NOT NULL,
            lat          REAL    NOT NULL,
            lon          REAL    NOT NULL,
            image        TEXT    NOT NULL DEFAULT '',
            visit_count  INTEGER NOT NULL DEFAULT 0,
            avg_distance REAL    NOT NULL DEFAULT 0,
            score        REAL    NOT NULL DEFAULT 0
          )
        ''');


        await db.execute('''
          CREATE TABLE $visits (
            local_id       INTEGER PRIMARY KEY AUTOINCREMENT,
            landmark_id    INTEGER NOT NULL,
            landmark_title TEXT    NOT NULL,
            user_lat       REAL    NOT NULL,
            user_lon       REAL    NOT NULL,
            created_at     INTEGER NOT NULL,
            status         TEXT    NOT NULL,
            job_id         INTEGER,
            distance       REAL,
            error          TEXT,
            attempts       INTEGER NOT NULL DEFAULT 0
          )
        ''');


        await db.execute('''
          CREATE TABLE $deleted (
            id    INTEGER PRIMARY KEY,
            title TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }
}
