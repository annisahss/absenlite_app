import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  String? lastCheckInTime;

  @override
  void initState() {
    super.initState();
    _setDateTime();
    _getCurrentLocation();
    _checkTodayAttendance();
  }

  void _setDateTime() {
    final now = DateTime.now();
    formattedTime = DateFormat('h:mm a').format(now);
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

    final checkInLog = todayLogs.firstWhere(
      (log) => log.type == "Check-In",
      orElse: () => AttendanceModel.empty(),
    );

    setState(() {
      hasClockedInToday = checkInLog.type == "Check-In";
      lastCheckInTime = hasClockedInToday ? checkInLog.time : null;
    });
  }

  Future<void> _handleAttendance(String type) async {
    if (currentPosition == null) return;

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final logs = await DBHelper.getAttendanceByEmail(widget.user.email);
    final todayLogs = logs.where((log) => log.date == today).toList();

    final alreadyCheckedIn = todayLogs.any((log) => log.type == "Check-In");
    final alreadyCheckedOut = todayLogs.any((log) => log.type == "Check-Out");

    if (type == "Check-In" && alreadyCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already checked in today.")),
      );
      return;
    }

    if (type == "Check-Out" && !alreadyCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must check in before checking out.")),
      );
      return;
    }

    if (type == "Check-Out" && alreadyCheckedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already checked out today.")),
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

    if (type == "Check-In") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checked in successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checked out successfully")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HistoryScreen(user: widget.user)),
      );
    }
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
    );
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
              // ✅ Avatar, name, and email
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
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.user.email,
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

              // ✅ Location & time card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(formattedTime, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child:
                            currentPosition == null
                                ? const Center(
                                  child: CircularProgressIndicator(),
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

              // ✅ Show last check-in
              if (hasClockedInToday && lastCheckInTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "✅ Last Check-In: $lastCheckInTime",
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ),

              // ✅ Attendance buttons
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
                      onPressed: () => _handleAttendance("Check-In"),
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
                      onPressed: () => _handleAttendance("Check-Out"),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text("Clock Out"),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ History button
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
