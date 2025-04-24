class UserModel {
  int? id;
  String name;
  String email;
  String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Convert object to map (for insert/update)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  // Convert map to object (from query)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }
}
