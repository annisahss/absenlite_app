import '../db/db_helper.dart';
import '../models/user_model.dart';

class AuthService {
  /// Register a new user
  static Future<String?> registerUser(UserModel user) async {
    final existingUser = await DBHelper.getUserByEmail(user.email);
    if (existingUser != null) {
      return "Email is already registered";
    }

    await DBHelper.insertUser(user);
    return null; // Success
  }

  /// Login user by verifying email and password
  static Future<UserModel?> loginUser(String email, String password) async {
    return await DBHelper.getUser(email, password);
  }

  /// Fetch user data using email
  static Future<UserModel?> getUserByEmail(String email) async {
    return await DBHelper.getUserByEmail(email);
  }

  /// Update user data (name, email)
  static Future<void> updateUser(UserModel user) async {
    await DBHelper.updateUser(user);
  }
}
