import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = false;

  List<AttendanceModel> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;

  /// Load attendance for the current user
  Future<void> loadAttendance(String email) async {
    _isLoading = true;
    notifyListeners();

    _attendanceList = await AttendanceService.getAttendanceByEmail(email);

    _isLoading = false;
    notifyListeners();
  }

  /// Add new attendance record
  Future<void> addAttendance(AttendanceModel record) async {
    await AttendanceService.insertAttendance(record);
    await loadAttendance(record.userEmail); // Refresh list
  }

  /// Delete a record
  Future<void> deleteAttendance(int id, String email) async {
    await AttendanceService.deleteAttendance(id);
    await loadAttendance(email); // Refresh list
  }
}
