import '../db/db_helper.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  /// Insert a new attendance record
  static Future<void> insertAttendance(AttendanceModel record) async {
    await DBHelper.insertAttendance(record);
  }

  /// Get all attendance records for a specific user
  static Future<List<AttendanceModel>> getAttendanceByEmail(
    String email,
  ) async {
    return await DBHelper.getAttendanceByEmail(email);
  }

  /// Delete a specific attendance record
  static Future<void> deleteAttendance(int id) async {
    await DBHelper.deleteAttendance(id);
  }
}
