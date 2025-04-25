import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> initDb() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'absenlite.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create users table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');

        // Create attendance table
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT,
            type TEXT,
            date TEXT,
            time TEXT,
            latitude REAL,
            longitude REAL,
            address TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  // ✅ USER METHODS

  static Future<void> insertUser(UserModel user) async {
    final db = await initDb();
    await db.insert('users', user.toMap());
  }

  static Future<UserModel?> getUser(String email, String password) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  static Future<void> updateUser(UserModel user) async {
    final db = await initDb();
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ✅ ATTENDANCE METHODS

  static Future<void> insertAttendance(AttendanceModel attendance) async {
    final db = await initDb();
    await db.insert('attendance', attendance.toMap());
  }

  static Future<List<AttendanceModel>> getAttendanceByEmail(
    String email,
  ) async {
    final db = await initDb();
    final result = await db.query(
      'attendance',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'date DESC, time DESC',
    );

    return result.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  static Future<void> deleteAttendance(int id) async {
    final db = await initDb();
    await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }
}
