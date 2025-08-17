// lib/main.dart
import 'package:flutter/material.dart';
import 'package:secpanel/login.dart';
import 'package:secpanel/login_change_password.dart';
import 'package:secpanel/main_screen.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secpanel/session_timeout_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  final companyId = prefs.getString('companyId');

  runApp(MyApp(isLoggedIn: companyId != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // 2. BUAT GLOBAL KEY UNTUK NAVIGATOR
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // 3. BUNGKUS MaterialApp DENGAN SessionTimeoutManager
    return SessionTimeoutManager(
      navigatorKey: navigatorKey, // Kirim navigator key
      // Anda bisa mengatur durasi di sini, misal: Duration(seconds: 30) untuk testing
      // timeoutDuration: const Duration(minutes: 15),
      child: MaterialApp(
        navigatorKey: navigatorKey, // Pasang navigator key ke MaterialApp
        title: 'SEC Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.schneiderGreen,
          scaffoldBackgroundColor: AppColors.white,
          fontFamily: 'Lexend',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.schneiderGreen,
          ),
          useMaterial3: true,
        ),
        // Logika initialRoute Anda sudah benar
        // initialRoute: isLoggedIn ? '/home' : '/login',
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/login-change-password': (context) =>
              const LoginChangePasswordPage(),
          '/home': (context) => const MainScreen(),
        },
      ),
    );
  }
}
