// lib/main.dart
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // 2. BUAT GLOBAL KEY UNTUK NAVIGATOR
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Minta izin (penting di iOS)
    await messaging.requestPermission();

    // Ambil token device
    String? token = await messaging.getToken();
    print("🔑 FCM Token: $token");

    // Listener saat notif diterima ketika app foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Notif masuk (foreground): ${message.notification?.title}");

      // Kalau mau tampilkan snackbar di app saat notif masuk
      final ctx = MyApp.navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(message.notification?.title ?? "Notif baru")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. BUNGKUS MaterialApp DENGAN SessionTimeoutManager
    return SessionTimeoutManager(
      navigatorKey: MyApp.navigatorKey, // Kirim navigator key
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey, // Pasang navigator key ke MaterialApp
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
        // initialRoute bisa pakai login check dari SharedPreferences
        initialRoute: widget.isLoggedIn ? '/home' : '/login',
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
