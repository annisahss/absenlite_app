import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> initDb() async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), 'attendance_app.db');

    _database = await openDatabase(path, version: 1, onCreate: _onCreate);

    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE absensi (
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
  }

  // USER METHODS
  static Future<int> insertUser(UserModel user) async {
    final db = await initDb();
    return await db.insert('users', user.toMap());
  }

  static Future<UserModel?> getUser(String email, String password) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  static Future<int> updateUser(UserModel user) async {
    final db = await initDb();
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ATTENDANCE METHODS
  static Future<int> insertAttendance(AttendanceModel att) async {
    final db = await initDb();
    return await db.insert('absensi', att.toMap());
  }

  static Future<List<AttendanceModel>> getAttendanceByEmail(
    String email,
  ) async {
    final db = await initDb();
    final result = await db.query(
      'absensi',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'date DESC, time DESC',
    );
    return result.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  static Future<int> deleteAttendance(int id) async {
    final db = await initDb();
    return await db.delete('absensi', where: 'id = ?', whereArgs: [id]);
  }
}
