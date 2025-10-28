// 1. TAMBAHKAN IMPORT INI DI BAGIAN ATAS
import 'dart:io'; 

import 'package:flutter/material.dart';
import 'package:secpanel/login.dart';
import 'package:secpanel/login_change_password.dart';
import 'package:secpanel/main_screen.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secpanel/session_timeout_manager.dart';

// Tambahan Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Handler pesan background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Pesan FCM (background): ${message.notification?.title}");
}

// 2. LETAKKAN KELAS INI DI SINI, DI LUAR FUNGSI main()
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. TERAPKAN PENGATURAN GLOBAL DI SINI, SEBELUM runApp()
  HttpOverrides.global = MyHttpOverrides();

  await initializeDateFormatting('id_ID', null);

  // Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Ambil prefs login
  final prefs = await SharedPreferences.getInstance();
  final companyId = prefs.getString('companyId');

  runApp(MyApp(isLoggedIn: companyId != null));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SessionTimeoutManager(
      navigatorKey: MyApp.navigatorKey,
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        title: '3SUTORPro',
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
        initialRoute:  '/login',
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