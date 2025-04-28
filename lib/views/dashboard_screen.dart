import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../db/db_helper.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../views/history_screen.dart';
import '../views/profile_screen.dart';

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

  // 🆕 variabel untuk menyimpan nama dan email yang bisa diubah
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    _setDateTime();
    _getCurrentLocation();
    _checkTodayAttendance();

    currentName = widget.user.name;
    currentEmail = widget.user.email;
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
      (log) => log.type == "Clock In",
      orElse: () => AttendanceModel.empty(),
    );

    setState(() {
      hasClockedInToday = clockInLog.type == "Clock In";
      lastClockInTime = hasClockedInToday ? clockInLog.time : null;
    });
  }

  Future<void> _handleAttendance(String type) async {
    if (currentPosition == null) return;

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final logs = await DBHelper.getAttendanceByEmail(widget.user.email);
    final todayLogs = logs.where((log) => log.date == today).toList();

    final alreadyClockedIn = todayLogs.any((log) => log.type == "Clock In");
    final alreadyClockedOut = todayLogs.any((log) => log.type == "Clock Out");

    if (type == "Clock In" && alreadyClockedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already clocked in today.")),
      );
      return;
    }

    if (type == "Clock Out" && !alreadyClockedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must clock in before clocking out.")),
      );
      return;
    }

    if (type == "Clock Out" && alreadyClockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already clocked out today.")),
      );
      return;
    }

    final record = AttendanceModel(
      userEmail: widget.user.email,
      type: type,
      date: today,
      time: DateFormat('HH:mm:ss').format(now),
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
      address: currentAddress,
    );

    await DBHelper.insertAttendance(record);
    await _checkTodayAttendance(); // Refresh status

    if (type == "Clock In") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clocked in successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clocked out successfully")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HistoryScreen(user: widget.user)),
      );
    }
  }

  Future<void> _goToProfile() async {
    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(user: widget.user),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        currentName = updatedUser.name;
        currentEmail = updatedUser.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar and Name
              Row(
                children: [
                  GestureDetector(
                    onTap: _goToProfile,
                    child: const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Working Hours, Time, Date, and Map
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Working Hours: 09.00 am - 05.00 pm",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(formattedTime, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: currentPosition == null
                            ? const Center(child: CircularProgressIndicator())
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
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Last Clock In
              if (hasClockedInToday && lastClockInTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      "✅ Last Clock In: $lastClockInTime",
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
                ),

              // Clock In and Clock Out Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => _handleAttendance("Clock In"),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text("Clock In"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => _handleAttendance("Clock Out"),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text("Clock Out"),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Attendance History Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(user: widget.user),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Text(
                    "Attendance History",
                    style: TextStyle(color: Colors.black),
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
