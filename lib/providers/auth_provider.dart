import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/shared_pref_utils.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  /// Try auto-login on app start
  Future<void> tryAutoLogin() async {
    final email = await SharedPrefUtils.getEmail();
    if (email != null) {
      final existingUser = await AuthService.getUserByEmail(email);
      _user = existingUser;
      notifyListeners();
    }
  }

  /// Login function
  Future<String?> login(String email, String password) async {
    final result = await AuthService.loginUser(email, password);
    if (result != null) {
      _user = result;
      await SharedPrefUtils.saveLogin(result.email);
      notifyListeners();
      return null;
    } else {
      return "Invalid email or password";
    }
  }

  /// Register function
  Future<String?> register(UserModel user) async {
    final error = await AuthService.registerUser(user);
    if (error == null) {
      _user = user;
      await SharedPrefUtils.saveLogin(user.email);
      notifyListeners();
    }
    return error;
  }

  /// Logout
  Future<void> logout() async {
    _user = null;
    await SharedPrefUtils.logout();
    notifyListeners();
  }

  /// Update user
  Future<void> updateProfile(UserModel updatedUser) async {
    await AuthService.updateUser(updatedUser);
    _user = updatedUser;
    await SharedPrefUtils.saveLogin(updatedUser.email);
    notifyListeners();
  }
}
