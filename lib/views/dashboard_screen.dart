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

  @override
  void initState() {
    super.initState();
    _setDateTime();
    _getCurrentLocation();
  }

  void _setDateTime() {
    final now = DateTime.now();
    formattedTime = DateFormat('h:mm a').format(now);
    formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(now);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
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

  Future<void> _handleAttendance(String type) async {
    if (currentPosition == null) return;
    final now = DateTime.now();

    final record = AttendanceModel(
      userEmail: widget.user.email,
      type: type,
      date: DateFormat('yyyy-MM-dd').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
      address: currentAddress,
    );

    await DBHelper.insertAttendance(record);

    if (type == "Check-In") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checked in successfully")));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
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
              GestureDetector(
                onTap: _goToProfile,
                child: const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 36),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Loading...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Product Manager",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Card
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
                        height: 180,
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

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
                        backgroundColor: Colors.orange,
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
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
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
