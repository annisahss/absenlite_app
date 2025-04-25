class AttendanceModel {
  final int? id;
  final String userEmail;
  final String type;
  final String date;
  final String time;
  final double latitude;
  final double longitude;
  final String? address;

  AttendanceModel({
    this.id,
    required this.userEmail,
    required this.type,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'type': type,
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      userEmail: map['user_email'],
      type: map['type'],
      date: map['date'],
      time: map['time'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
    );
  }

  factory AttendanceModel.empty() => AttendanceModel(
    id: null,
    userEmail: '',
    type: '',
    date: '',
    time: '',
    latitude: 0.0,
    longitude: 0.0,
    address: '',
  );
}
