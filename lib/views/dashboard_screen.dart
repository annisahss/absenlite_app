import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../db/db_helper.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String formattedTime = '';
  String formattedDate = '';
  String currentAddress = 'Loading location...';
  Position? currentPosition;
  late CameraPosition _mapPosition;

  bool hasClockedInToday = false;
  String? lastClockInTime;

  @override
  void initState() {
    super.initState();
    _setDateTime();
    _getCurrentLocation();
    _checkTodayAttendance();

    // Update time every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _setDateTime();
        setState(() {});
        Future.delayed(const Duration(seconds: 1), () => _setDateTime());
      }
    });
  }

  void _setDateTime() {
    final now = DateTime.now();
    formattedTime = DateFormat('hh:mm:ss a').format(now);
    formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(now);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      final place = placemarks.first;
      final address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';

      setState(() {
        currentAddress = address;
        _mapPosition = CameraPosition(
          target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          zoom: 15,
        );
      });
    } catch (e) {
      setState(() => currentAddress = "Failed to get location: $e");
    }
  }

  Future<void> _checkTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logs = await DBHelper.getAttendanceByEmail(widget.user.email);
    final todayLogs = logs.where((log) => log.date == today).toList();

    final clockInLog = todayLogs.firstWhere(
      (log) => log.type == "Clock-In",
      orElse: () => AttendanceModel.empty(),
    );

    setState(() {
      hasClockedInToday = clockInLog.type == "Clock-In";
      lastClockInTime = hasClockedInToday ? clockInLog.time : null;
    });
  }

  Future<void> _handleAttendance(String type) async {
    if (currentPosition == null) return;

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final logs = await DBHelper.getAttendanceByEmail(widget.user.email);
    final todayLogs = logs.where((log) => log.date == today).toList();

    final alreadyClockedIn = todayLogs.any((log) => log.type == "Clock-In");
    final alreadyClockedOut = todayLogs.any((log) => log.type == "Clock-Out");

    if (type == "Clock-In" && alreadyClockedIn) {
      _showSnackBar("You already clocked in today.");
      return;
    }

    if (type == "Clock-Out" && !alreadyClockedIn) {
      _showSnackBar("You must clock in before clocking out.");
      return;
    }

    if (type == "Clock-Out" && alreadyClockedOut) {
      _showSnackBar("You already clocked out today.");
      return;
    }

    final record = AttendanceModel(
      userEmail: widget.user.email,
      type: type,
      date: today,
      time: DateFormat('hh:mm:ss a').format(now),
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
      address: currentAddress,
    );

    await DBHelper.insertAttendance(record);
    await _checkTodayAttendance();

    if (type == "Clock-In") {
      _showSnackBar("Clocked in successfully");
    } else {
      _showSnackBar("Clocked out successfully");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HistoryScreen(user: widget.user)),
      );
    }
  }

  void _showSnackBar(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isDarkMode ? AppColors.darkCardColor : AppColors.primaryIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.backgroundLavender;
    final cardBackground = isDarkMode ? AppColors.darkCardColor : Colors.white;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textDark;
    final textSecondaryColor =
        isDarkMode ? Colors.white70 : AppColors.textMedium;
    final textTertiaryColor = isDarkMode ? Colors.white60 : AppColors.textLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar with Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AbsenLite",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      Text(
                        "Hello, ${widget.user.name.split(' ')[0]}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  GestureDetector(
                    onTap: _goToProfile,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDarkMode
                                    ? AppColors.primaryIndigo.withOpacity(0.3)
                                    : AppColors.primaryIndigo.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            isDarkMode ? AppColors.darkSurface : Colors.white,
                        child: Text(
                          widget.user.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Time & Date Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDarkMode
                            ? [AppColors.darkIndigo, AppColors.primaryIndigo]
                            : [AppColors.primaryIndigo, AppColors.darkIndigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDarkMode
                              ? AppColors.darkIndigo.withOpacity(0.5)
                              : AppColors.primaryIndigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Working Hours",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "09:00 AM - 05:00 PM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:
                              hasClockedInToday
                                  ? const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Clocked In",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                  : const Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Not Clocked In",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Current Time",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Today's Date",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasClockedInToday && lastClockInTime != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Last Clock-In: $lastClockInTime",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Your Location
              Text(
                "Your Location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Location Card with Map
              Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDarkMode
                              ? AppColors.darkBorderColor
                              : AppColors.mediumIndigo,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child:
                          currentPosition == null
                              ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode
                                        ? AppColors.accentViolet
                                        : AppColors.primaryIndigo,
                                  ),
                                ),
                              )
                              : GoogleMap(
                                initialCameraPosition: _mapPosition,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('me'),
                                    position: _mapPosition.target,
                                  ),
                                },
                                zoomControlsEnabled: false,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                // Apply dark/light styling to map
                                mapType: MapType.normal,
                                trafficEnabled: false,
                              ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: cardBackground),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.lightLavender,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color:
                                  isDarkMode
                                      ? AppColors.accentViolet
                                      : AppColors.primaryIndigo,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Current Address",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textTertiaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Attendance Actions
              Text(
                "Attendance Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAttendance("Clock-In"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasClockedInToday
                                ? (isDarkMode
                                    ? AppColors.successGreen.withOpacity(0.3)
                                    : AppColors.successLightGreen)
                                : AppColors.successGreen,
                        foregroundColor:
                            hasClockedInToday
                                ? (isDarkMode
                                    ? AppColors.successGreen
                                    : AppColors.successGreen)
                                : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: hasClockedInToday ? 0 : 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasClockedInToday
                                ? Icons.check_circle
                                : Icons.login,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasClockedInToday ? "Clocked In" : "Clock In",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          hasClockedInToday
                              ? () => _handleAttendance("Clock-Out")
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        disabledBackgroundColor:
                            isDarkMode
                                ? AppColors.errorRed.withOpacity(0.3)
                                : AppColors.errorLightRed,
                        disabledForegroundColor:
                            isDarkMode
                                ? AppColors.errorRed.withOpacity(0.5)
                                : AppColors.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Clock Out",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // History Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(user: widget.user),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.mediumIndigo,
                    foregroundColor:
                        isDarkMode ? AppColors.mediumIndigo : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color:
                            isDarkMode ? AppColors.accentViolet : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Attendance History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode
                                  ? AppColors.accentViolet
                                  : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
