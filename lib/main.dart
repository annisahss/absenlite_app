import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';
import 'theme/app_colors.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'utils/shared_pref_utils.dart';
import 'db/db_helper.dart';
import 'models/user_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        primaryColor: AppColors.primaryPurple,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryPurple,
          secondary: AppColors.mediumPurple,
          surface: Colors.white,
          background: AppColors.backgroundLilac,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLilac,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: AppColors.darkPurple,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryPurple,
          secondary: AppColors.mediumPurple,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
        ),
      ),
      home: const InitialRouteDecider(),
    );
  }
}

// Menentukan ke mana user diarahkan saat membuka app
class InitialRouteDecider extends StatefulWidget {
  const InitialRouteDecider({super.key});

  @override
  State<InitialRouteDecider> createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<InitialRouteDecider> {
  bool isLoading = true;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final email = await SharedPrefUtils.getEmail();
    if (email != null) {
      user = await DBHelper.getUserByEmail(email);
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
        ),
      );
    return user != null ? DashboardScreen(user: user!) : const LoginScreen();
  }
}