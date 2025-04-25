import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:absenlite_app/db/db_helper.dart';
import 'package:absenlite_app/models/attendance_model.dart';
import 'package:absenlite_app/models/user_model.dart';
import 'package:absenlite_app/utils/shared_pref_utils.dart';
import 'package:absenlite_app/views/dashboard_screen.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceModel> _attendanceHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    final email = await SharedPrefUtils.getEmail();
    if (email != null) {
      final result = await DBHelper.getAttendanceByEmail(email);
      setState(() {
        _attendanceHistory = result;
        isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(int id) async {
    await DBHelper.deleteAttendance(id);
    _loadAttendanceHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance record deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("Attendance History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(user: widget.user),
              ),
            );
          },
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _attendanceHistory.isEmpty
              ? const Center(child: Text("No attendance records found."))
              : ListView.builder(
                itemCount: _attendanceHistory.length,
                itemBuilder: (context, index) {
                  final record = _attendanceHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        DateFormat(
                          'EEEE, MMMM dd, yyyy',
                        ).format(DateTime.parse(record.date)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Type: ${record.type}'),
                          Text('Time: ${record.time}'),
                          Text('Location: ${record.address ?? "-"}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEntry(record.id!),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
