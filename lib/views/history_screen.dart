import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:absenlite_app/db/db_helper.dart';
import 'package:absenlite_app/models/attendance_model.dart';
import 'package:absenlite_app/models/user_model.dart';
import 'package:absenlite_app/utils/shared_pref_utils.dart';
import 'package:absenlite_app/views/dashboard_screen.dart';
import 'package:absenlite_app/theme/app_colors.dart';
import 'package:absenlite_app/theme/theme_provider.dart';

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Attendance record deleted'),
        backgroundColor: AppColors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundLilac,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Attendance History",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
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
      body: SafeArea(
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mediumIndigo,
                  ),
                )
                : _attendanceHistory.isEmpty
                ? _buildEmptyState(isDark)
                : _buildHistoryList(isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color:
                isDark
                    ? AppColors.mediumIndigo.withOpacity(0.5)
                    : AppColors.textMedium.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance records found",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your attendance history will appear here",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: _attendanceHistory.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final record = _attendanceHistory[index];
          final attendanceDate = DateTime.parse(record.date);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isDark
                      ? []
                      : [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header with type chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.3)
                            : AppColors.lightPurple.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, MMMM dd, yyyy',
                        ).format(attendanceDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.grey[300] : AppColors.textMedium,
                        ),
                      ),
                      _getAttendanceTypeChip(record.type, isDark),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color:
                                isDark
                                    ? AppColors.mediumIndigo
                                    : AppColors.iconPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            record.time,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color:
                                isDark
                                    ? AppColors.mediumIndigo
                                    : AppColors.iconPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.address ?? "No location data",
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : AppColors.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Delete button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _deleteEntry(record.id!),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color:
                                  isDark
                                      ? AppColors.accentRed
                                      : AppColors.errorRed,
                            ),
                            label: Text(
                              "Delete",
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppColors.accentRed
                                        : AppColors.errorRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getAttendanceTypeChip(String type, bool isDark) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'check in':
        bgColor =
            isDark
                ? AppColors.successGreen.withOpacity(0.15)
                : AppColors.successLightGreen;
        textColor = AppColors.successGreen;
        icon = Icons.login_rounded;
        break;
      case 'check out':
        bgColor =
            isDark
                ? AppColors.errorRed.withOpacity(0.15)
                : AppColors.errorLightRed;
        textColor = isDark ? AppColors.accentRed : AppColors.errorRed;
        icon = Icons.logout_rounded;
        break;
      default:
        bgColor =
            isDark
                ? AppColors.primaryIndigo.withOpacity(0.15)
                : AppColors.lightPurple;
        textColor = AppColors.mediumIndigo;
        icon = Icons.event_note;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
