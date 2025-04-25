import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../models/user_model.dart';
import '../utils/shared_pref_utils.dart';
import '../theme/theme_provider.dart';
import 'dashboard_screen.dart'; // ✅ import dashboard screen

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
  }

  Future<void> _saveProfile() async {
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and email cannot be empty.")),
      );
      return;
    }

    final updatedUser = UserModel(
      id: widget.user.id,
      name: newName,
      email: newEmail,
      password: widget.user.password,
    );

    setState(() => isSaving = true);
    await DBHelper.updateUser(updatedUser);
    await SharedPrefUtils.saveLogin(newEmail); // Update session email
    setState(() => isSaving = false);

    // ✅ Navigate back to updated dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(user: updatedUser)),
    );
  }

  Future<void> _logout() async {
    await SharedPrefUtils.logout();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              child: const Text("Save Changes"),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dark Mode"),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[300]),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
